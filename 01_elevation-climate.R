## Ecography: Plot of temperature and precipitation by Himalayan region (eastern, central and Western)

## Prepare libraries
# load libs
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

# Load shapefiles
west <- st_read("C:\\Users\\vr235\\Desktop\\SahasMaps\\westHimalayas.shp")
east <- st_read("C:\\Users\\vr235\\Desktop\\SahasMaps\\eastHimalayas.shp")

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
alt <- raster("data/spatial/elevation/alt")
alt.hills <- crop(alt, as(Him, "Spatial"))
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
  a <- crop(a, as(Him, "Spatial"))
  return(a)
})

chelsaData[[1]] <- chelsaData[[1]]/10

# stack chelsa data
chelsaData <- raster::stack(chelsaData)

### Stack prepared rasters
# stack rasters for efficient reprojection later
env_data <- stack(elevData, chelsaData)

# get proper names
elev_names <- c("elev", "slope", "aspect")
chelsa_names <- c("chelsa_temp", "chelsa_prec")

names(env_data) <- as.character(glue('{c(elev_names, chelsa_names)}'))

# make duplicate stack
env <- env_data[[c("elev", chelsa_names)]]

# convert to list
env <- as.list(env)

# map get values over the stack
env <- purrr::map(env, getValues)
names(env) <- c("elev", chelsa_names)

# conver to dataframe and round to 100m
env <- bind_cols(env)
env <- drop_na(env) %>% 
  mutate(elev_round  = plyr::round_any(elev, 200)) %>% 
  dplyr::select(-elev) %>% 
  pivot_longer(cols = contains("chelsa"),
               names_to = "clim_var") %>% 
  group_by(elev_round, clim_var) %>% 
  summarise_all(.funs = list(~mean(.), ~ci(.)))

env <- env %>% filter(elev_round<=5000)

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
  labs(x = "elevation (m)", y = "CHELSA variable value")+
  theme(axis.title = element_text(size = 16, face = "bold"), 
        axis.ticks.length.x = unit(.5, "cm"),
        axis.text = element_text(size = 14),
        legend.title = element_blank(),
        legend.key.size = unit(1,"cm"),
        legend.text = element_text(size = 12))

ggsave(fig_climate_elev, filename = "C:\\Users\\vr235\\Desktop\\SahasMaps\\fig_centralHim_elev.svg", 
       height = 10, width = 11, device = svg(), dpi = 300); dev.off()

