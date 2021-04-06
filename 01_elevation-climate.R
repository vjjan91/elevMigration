## Climate as a function of elevation

### Author: Code written by Pratik Gupte and Vijay Ramesh for a manuscript in review

## Prepare libraries

library(raster)
library(stringi)
library(glue)
library(gdalUtils)
library(purrr)
library(dplyr)
library(tidyr)
library(scales)
library(ggplot2)
library(ggthemes)
library(sf)
library(mapview)

# Load shapefiles
west <- st_read("data/shapefiles/westHimalayas.shp")
east <- st_read("data/shapefiles/eastHimalayas.shp")

# get ci func
ci <- function(x){qnorm(0.975)*sd(x, na.rm = T)/sqrt(length(x))}

# prep mode function to aggregate
funcMode <- function(x, na.rm = T) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

# a basic test
assertthat::assert_that(funcMode(c(2,2,2,2,3,3,3,4)) == as.character(2), 
                        msg = "problem in the mode function") # works

### Prepare terrain rasters
# load elevation and crop to hills size, then mask by hills
alt <- raster("data/elevation/alt")
alt.hills <- crop(alt, as(east, "Spatial"))
rm(alt); gc()

# get slope and aspect
slopeData <- terrain(x = alt.hills, opt = c("slope", "aspect"))
elevData <- raster::stack(alt.hills, slopeData)
rm(alt.hills); gc()

### Prepare CHELSA rasters
# list chelsa files
chelsaFiles <- list.files("data/chelsa/", 
                          full.names = TRUE, 
                          pattern = "*.tif")

# gather chelsa rasters
chelsaData <- purrr::map(chelsaFiles, function(chr){
  a <- raster(chr)
  crs(a) <- crs(elevData)
  a <- crop(a, as(east, "Spatial"))
  return(a)
})

# Divide temperature values by 10
chelsaData[[1]] <- chelsaData[[1]]/10
chelsaData[[2]] <- chelsaData[[2]]/10
chelsaData[[3]] <- chelsaData[[3]]/10
chelsaData[[4]] <- chelsaData[[4]]/10

# stack chelsa data
chelsaData <- raster::stack(chelsaData)

### Stack prepared rasters
# stack rasters for efficient reprojection later
env_data <- stack(elevData, chelsaData)

# get proper names
elev_names <- c("elev", "slope", "aspect")
chelsa_names <- c("maxTemp_Jan", "maxTemp_June","minTemp_Jan","minTemp_June")

names(env_data) <- as.character(glue('{c(elev_names, chelsa_names)}'))

# make duplicate stack
env <- env_data[[c("elev", chelsa_names)]]

# convert to list
env <- as.list(env)

# map get values over the stack
env <- purrr::map(env, getValues)
names(env) <- c("elev", chelsa_names)

# convert to dataframe and round to a particular elevational band you need
env <- bind_cols(env)
env <- drop_na(env) %>% 
  mutate(elev_round  = plyr::round_any(elev, 500)) %>% 
  dplyr::select(-elev) %>% 
  group_by(elev_round) %>% 
  summarise_all(.funs = list(~mean(.), ~ci(.))) %>%
  mutate(tempRange_Jan = (maxTemp_Jan_mean - minTemp_Jan_mean),
         tempRange_June = (maxTemp_June_mean - minTemp_June_mean))

# Write results to a .csv
westHim <- write.csv(env,"output/westHim_500.csv", row.names = F)
eastHim <- write.csv(env,"output/eastHim_500.csv", row.names = F)


# Edit plot code later # 
# plot in facets
fig_climate_elev <- ggplot(env)+
  geom_line(aes(x = elev_round, y = mean),
            size = 0.2, col = "grey")+
  geom_pointrange(aes(x = elev_round, y = mean, ymin=mean-ci, ymax=mean+ci),
                  size = 0.3)+
  scale_x_continuous(labels = scales::comma)+
  scale_y_continuous(labels = scales::comma)+
  facet_wrap(~clim_var, scales = "free_y")+
  theme_few()+
  labs(x = "elevation (m) at 500m intervals", y = "CHELSA variable value")+
  theme(axis.title = element_text(size = 16, face = "bold"), 
        axis.ticks.length.x = unit(.5, "cm"),
        axis.text = element_text(size = 14),
        legend.title = element_blank(),
        legend.key.size = unit(1,"cm"),
        legend.text = element_text(size = 12))

ggsave(fig_climate_elev, filename = "figs/fig_eastHim_elev500.png", 
       height = 10, width = 14, device = png(), dpi = 300, units="in"); dev.off()

