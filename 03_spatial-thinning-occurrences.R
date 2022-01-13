#### script to reduce the number of localities before mapping

# load libraries
library(sf)
library(dplyr)
library(spThin)

# load sheet of all localties
loc <- read.csv("data/localities-for-map.csv")
head(loc)

loc_unique <- loc %>% distinct()

loc_unique$species <- "species"

# carry out spatial thinning with a minimum distance of 15km between records
thinned <- thin(loc_unique,lat.col="LATITUDE",long.col = "LONGITUDE",
                spec.col = "species",thin.par = 15,reps=1,
                write.files=T, 
                out.dir="data/",
                out.base="localities-thinned")

# reload spatially thinned file
thin_file <- read.csv("data/localities-for-map-thinned.csv")

thin_file <- thin_file %>%
  mutate(region = case_when(LONGITUDE < 83 ~ "west",
                            LONGITUDE > 83 ~ "east"))

shp <- st_as_sf(thin_file, coords = c("LONGITUDE","LATITUDE"), crs=4326)
str(shp)

st_write(shp[shp$region=="east",],"shapefiles/localities-east.shp",
         driver="ESRI Shapefile")
