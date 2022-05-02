## Climate as a function of elevation


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
library(rgeos)

# Load shapefiles
himalayas <- st_read("data/shapefiles/shapefile_himalaya.shp")
mapview(himalayas)

# Need to merge a few polygons to essentially split himalayas into the west and the east
# This will have to be done at 83E for Nepal

# Merge polygons for western himalayas
west_toMerge <- himalayas[c(3,4,7,8,9,10),]
westHim <- st_crop(west_toMerge,xmin=68.03321,ymin=23.69771,xmax=83,ymax=37.07761)

# Merge polygons for eastern himalayas
east_toMerge <- himalayas[c(1,2,5,6,10),]
east_toMerge <- st_buffer(east_toMerge, dist=0)
eastHim <- st_crop(east_toMerge,xmin=83,ymin=25.96462,xmax=97.4115,ymax=30.44728)

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
alt.hills <- crop(alt, as(eastHim, "Spatial"))
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
  a <- crop(a, as(eastHim, "Spatial"))
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
  mutate(elev_round  = plyr::round_any(elev, 100)) %>% # changed to 100 m intervals 
  dplyr::select(-elev) %>% 
  group_by(elev_round) %>% 
  summarise_all(.funs = list(~mean(.), ~ci(.))) %>%
  mutate(tempRange_Jan = (maxTemp_Jan_mean - minTemp_Jan_mean),
         tempRange_June = (maxTemp_June_mean - minTemp_June_mean))

# Write results to a .csv
west_data <- write.csv(env,"output/westHim_100.csv", row.names = F)
east_data <- write.csv(env,"output/eastHim_100.csv", row.names = F)


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
  labs(x = "elevation (m) at 100m intervals", y = "CHELSA variable value")+
  theme(axis.title = element_text(size = 16, face = "bold"), 
        axis.ticks.length.x = unit(.5, "cm"),
        axis.text = element_text(size = 14),
        legend.title = element_blank(),
        legend.key.size = unit(1,"cm"),
        legend.text = element_text(size = 12))

# save ggplots accordingly
ggsave(fig_climate_elev, filename = "figs/fig_eastHim_elev100.png", 
       height = 10, width = 14, device = png(), dpi = 300, units="in"); dev.off()

