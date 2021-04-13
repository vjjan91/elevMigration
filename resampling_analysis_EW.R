setwd("D:/IISC/Sahas_elevation")

## Clean up Raw ebird data
## Input path of ebird raw data and the country it is from
readcleanrawdata = function(rawpath, Country)
{
  require(lubridate)
  require(tidyverse)
  require(cowplot)
  
  preimp = c("COMMON.NAME","OBSERVATION.COUNT",
             "LOCALITY.ID","LOCALITY.TYPE", "STATE", "COUNTRY",
             "LATITUDE","LONGITUDE","OBSERVATION.DATE","TIME.OBSERVATIONS.STARTED","OBSERVER.ID",
             "PROTOCOL.TYPE","DURATION.MINUTES","EFFORT.DISTANCE.KM", "REVIEWED",
             "NUMBER.OBSERVERS","ALL.SPECIES.REPORTED","GROUP.IDENTIFIER","SAMPLING.EVENT.IDENTIFIER","APPROVED","CATEGORY")
  
  nms = read.delim(rawpath, nrows = 1, sep = "\t", header = T, quote = "", stringsAsFactors = F, na.strings = c(""," ",NA))
  nms = names(nms)
  nms[!(nms %in% preimp)] = "NULL"
  nms[nms %in% preimp] = NA
  
  data = read.delim(rawpath, colClasses = nms, sep = "\t", header = T, quote = "", stringsAsFactors = F, na.strings = c(""," ",NA))
  
  ## choosing important variables
  
  imp = c("COMMON.NAME","OBSERVATION.COUNT",
          "LOCALITY.ID","LOCALITY.TYPE", "STATE", "COUNTRY",
          "LATITUDE","LONGITUDE","OBSERVATION.DATE","TIME.OBSERVATIONS.STARTED","OBSERVER.ID",
          "PROTOCOL.TYPE","DURATION.MINUTES","EFFORT.DISTANCE.KM", "SAMPLING.EVENT.IDENTIFIER",
          "NUMBER.OBSERVERS","ALL.SPECIES.REPORTED","group.id", "CATEGORY","no.sp")
  
  days = c(31,28,31,30,31,30,31,31,30,31,30,31)
  cdays = c(0,31,59,90,120,151,181,212,243,273,304,334)
  
  ## setup eBird data ##
  
  ## filter approved observations, species, slice by single group ID, remove repetitions
  ## remove repeats
  ## set date, add month, year and day columns using package LUBRIDATE
  ## filter distance travelled, duration birded and number of observers
  ## add number of species column (no.sp)
  
  if (Country != "India")
  {
    data = data %>%
      filter(REVIEWED == 0 | APPROVED == 1) %>%
      mutate(group.id = ifelse(is.na(GROUP.IDENTIFIER), SAMPLING.EVENT.IDENTIFIER, GROUP.IDENTIFIER)) %>%
      filter(ALL.SPECIES.REPORTED == 1) %>%  filter(EFFORT.DISTANCE.KM<=2.5|is.na(EFFORT.DISTANCE.KM))%>%
      filter(DURATION.MINUTES <= 120)%>% filter(NUMBER.OBSERVERS <= 10)%>%
      group_by(group.id,COMMON.NAME) %>% slice(1) %>% ungroup %>%
      group_by(group.id) %>% mutate(no.sp = n_distinct(COMMON.NAME))%>%
      dplyr::select(imp) %>%
      mutate(OBSERVATION.DATE = as.Date(OBSERVATION.DATE), 
             month = month(OBSERVATION.DATE), year = year(OBSERVATION.DATE),
             day = day(OBSERVATION.DATE) + cdays[month], week = week(OBSERVATION.DATE),
             fort = ceiling(day/14)) %>%
      ungroup
    
    return(data)
  }
  
  if (Country == "India")
  {
    data = data %>%
      filter(REVIEWED == 0 | APPROVED == 1) %>%
      mutate(group.id = ifelse(is.na(GROUP.IDENTIFIER), SAMPLING.EVENT.IDENTIFIER, GROUP.IDENTIFIER)) %>%
      filter(ALL.SPECIES.REPORTED == 1) %>%  filter(EFFORT.DISTANCE.KM<=2.5|is.na(EFFORT.DISTANCE.KM))%>%
      filter(DURATION.MINUTES <= 120)%>% filter(NUMBER.OBSERVERS <= 10)%>%
      filter(STATE == "Uttarakhand" | STATE == "Himachal Pradesh"| STATE == "Jammu and Kashmir"| STATE == "Sikkim" | STATE == "Arunachal Pradesh" |STATE == "West Bengal")%>%
      group_by(group.id,COMMON.NAME) %>% slice(1) %>% ungroup %>%
      group_by(group.id) %>% mutate(no.sp = n_distinct(COMMON.NAME))%>%
      dplyr::select(imp) %>%
      mutate(OBSERVATION.DATE = as.Date(OBSERVATION.DATE), 
             month = month(OBSERVATION.DATE), year = year(OBSERVATION.DATE),
             day = day(OBSERVATION.DATE) + cdays[month], week = week(OBSERVATION.DATE),
             fort = ceiling(day/14)) %>%
      ungroup
    
    return(data)
  }
}

Bhutan<-readcleanrawdata("ebd_BT_relSep-2020.txt", Country = "Bhutan")
Nepal<-readcleanrawdata("ebd_NP_relSep-2020.txt", Country = "Nepal")
POK<-readcleanrawdata("ebd_IN-JK-KM_relSep-2020.txt", Country = "POK")
India<-readcleanrawdata("ebd_IN_relSep-2020.txt", Country = "India")
Pakistan<-readcleanrawdata("ebd_PK_relSep-2020.txt", Country = "Pakistan")

## Removing non himalayan regions
India<-India %>% filter(LATITUDE>26,LONGITUDE<100)
Pakistan<-Pakistan %>% filter (LATITUDE>33)

dat<-rbind(Nepal,POK,India,Pakistan,Bhutan)

## Unique locations used

datll<-dat%>% distinct(LATITUDE,LONGITUDE, .keep_all = T)%>%select(LOCALITY.ID,LATITUDE,LONGITUDE)
write.csv(datll, "unique_loc.csv", row.names = F)

##extracting elev
library(tidyverse)
library(sf)
library(raster)

dat <- st_as_sf(dat, coords = c("LONGITUDE","LATITUDE"), crs=4326, remove = "F")

# Loading the elevation data
elev <- raster("D:/IISC/Sahas_elevation/elevation/alt")

# Extract elevation
elevation <- raster::extract(elev,dat)

# cbind elevation back to dataframe
dat.1 <- cbind(dat,elevation)

# save Rdata file
save(dat.1,file = "eBird_elev.RData")


######### 
load("eBird_elev.RData")
dat.1<-as.data.frame(dat.1)
dat.1<-dat.1[,-27]

dat.1<-dat.1 %>% filter(CATEGORY == "species" | CATEGORY == "issf")

dat1W<-dat.1 %>% filter (LONGITUDE < 83)
dat1E<-dat.1 %>% filter (LONGITUDE > 83)

############################################## FOR EAST ########################################

## Number of checklists in either season in each elevational band
Checklists <- dat1E[!duplicated(dat1E$group.id), ]
Checklists$elev_level <- cut(Checklists$elevation, breaks = c(-Inf, 500, 1000, 1500, 2000, 2500, 3000, Inf), labels = 1:7)
Checklists.S <- subset(Checklists, month %in% 3:7)
Checklists.W <- subset(Checklists, month %in% c(1, 2, 11, 12))

summer<- Checklists.S %>% group_by(elev_level) %>% summarise(summer = n_distinct(group.id))
winter<- Checklists.W %>% group_by(elev_level) %>% summarise(winter = n_distinct(group.id))

CL_ES<- left_join(summer,winter, by = "elev_level")
levels(CL_ES$elev_level)<-c("0-500","500-1000","1000-1500","1500-2000","2000-2500","2500-3000",">3000")
write.csv(CL_ES, "ChecklistNo_SeasonElevation_East.csv", row.names = F )

ID.S <- lapply(1:7, function(x) Checklists.S$group.id[Checklists.S$elev_level == x])
ID.W <- lapply(1:7, function(x) Checklists.W$group.id[Checklists.W$elev_level == x])

## Get unique species list
uniSpe <- dat1E %>% filter(CATEGORY == "species" | CATEGORY == "issf")
uniSpe <- unique(uniSpe[, "COMMON.NAME"]) %>% data.frame()

## Get median effort (number of checklists) across season and elevation
efforts.S <- summary(Checklists.S$elev_level)
efforts.W <- summary(Checklists.W$elev_level)
qEffort <- quantile(c(efforts.S, efforts.W), 0.50)

## sample an equal number of checklists (median effort) from each elevation band x 
set.seed(56789)
sampleID.S <- lapply(1:1000, function(y) {unlist(lapply(1:7, function(x) sample(ID.S[[x]], qEffort, replace=T)))})
set.seed(56789)
sampleID.W <- lapply(1:1000, function(y) {unlist(lapply(1:7, function(x) sample(ID.W[[x]], qEffort, replace=T)))})

# calculate the median elevation for each bird species in the two seasons
# This step takes a long computation time

rs<- lapply(1:1000, function(y) {
  m <- t(sapply(uniSpe[, 1], function(x){
    occs.S <- subset(dat1E, COMMON.NAME ==x & group.id %in% sampleID.S[[y]], select="elevation")
    occs.W <- subset(dat1E, COMMON.NAME==x & group.id %in% sampleID.W[[y]], select="elevation")
    B.n <- nrow(occs.S)
    W.n <- nrow(occs.W)
    B.elev <- if (B.n > 0) quantile(occs.S$elevation, 0.5) else NA
    W.elev <- if (W.n > 0) quantile(occs.W$elevation, 0.5) else NA
    return(c(B.elev = B.elev, B.n = B.n, W.elev = W.elev, W.n = W.n))
  }))
})

save(rs,file = "eBird_resampled_east.RData")

############# Get median difference in elevation range in Summer and Winter
load("eBird_resampled_east.RData")

B.elev <- sapply(1:1000, function(x) rs[[x]][, 1])
B.n <-    sapply(1:1000, function(x) rs[[x]][, 2])
W.elev <- sapply(1:1000, function(x) rs[[x]][, 3])
W.n <-    sapply(1:1000, function(x) rs[[x]][, 4])

diff <- B.elev - W.elev
dimnames(diff)<-list(uniSpe[,1],1:1000)

# For each species exclude trials where it has been detected less than 30 in winter or summer
diff[W.n < 30 | B.n < 30] <- NA  
diff.sel <- diff[apply(diff, 1, FUN = function(x) sum(is.na(x))) < 1000, ]

# Calculate medians of the percentiles over 1000 sets of resampled sampling events. Along with confidence intervals    
med.CI <- apply(diff.sel, 1, FUN = function(x) quantile((x), c(0.025, .5, .975), na.rm = TRUE))
med.CI <- t(med.CI)
med.CI  <- as.data.frame(med.CI)
med.CI$Group <- with(med.CI, ifelse(`2.5%` > 0 & `97.5%` > 0, 2, ifelse(`2.5%` < 0 & `97.5%` < 0, 1, 0)))
med.CI$LCI_diff <- as.numeric(med.CI$`2.5%`)
med.CI$Median_diff <- as.numeric(med.CI$`50%`)
med.CI$UCI_diff <- as.numeric(med.CI$`97.5%`)
med.CI$Species <- rownames(med.CI)
med.CI<-med.CI[,-c(1,2,3)]

## adding median breeding elevations to the same table

dimnames(B.elev)<-list(uniSpe[,1],1:1000)
B.elev[W.n < 30 | B.n < 30] <- NA

B.sel <- B.elev[apply(B.elev, 1, FUN = function(x) sum(is.na(x))) < 1000, ]

med.S.CI <- apply(B.sel, 1, FUN = function(x) quantile((x), c(0.025, .5, .975), na.rm = TRUE))
med.S.CI <- t(med.S.CI)
med.S.CI  <- as.data.frame(med.S.CI)
med.S.CI$LCI_S <- as.numeric(med.S.CI$`2.5%`)
med.S.CI$Median_S <- as.numeric(med.S.CI$`50%`)
med.S.CI$UCI_S <- as.numeric(med.S.CI$`97.5%`)
med.S.CI$Species <- rownames(med.S.CI)
med.S.CI<-med.S.CI[,-c(1,2,3)]

## adding median winter elevations to the same table

dimnames(W.elev)<-list(uniSpe[,1],1:1000)
W.elev[W.n < 30 | B.n < 30] <- NA

W.sel <- W.elev[apply(W.elev, 1, FUN = function(x) sum(is.na(x))) < 1000, ]

med.W.CI <- apply(W.sel, 1, FUN = function(x) quantile((x), c(0.025, .5, .975), na.rm = TRUE))
med.W.CI <- t(med.W.CI)
med.W.CI  <- as.data.frame(med.W.CI)
med.W.CI$LCI_W <- as.numeric(med.W.CI$`2.5%`)
med.W.CI$Median_W <- as.numeric(med.W.CI$`50%`)
med.W.CI$UCI_W <- as.numeric(med.W.CI$`97.5%`)
med.W.CI$Species <- rownames(med.W.CI)
med.W.CI<-med.W.CI[,-c(1,2,3)]

ts<-left_join(med.CI,med.S.CI, by = "Species") %>% left_join(., med.W.CI, by = "Species", )

ts <- ts[c("Species", "Group", "Median_S", "LCI_S", "UCI_S","Median_W","LCI_W","UCI_W","Median_diff","LCI_diff", "UCI_diff")]

write.csv(ts, "final_birdlist_east2.csv", row.names = F)


############################################ for West

## Number of checklists in either season in each elevational band
Checklists <- dat1W[!duplicated(dat1W$group.id), ]
Checklists$elev_level <- cut(Checklists$elevation, breaks = c(-Inf, 500, 1000, 1500, 2000, 2500, 3000, Inf), labels = 1:7)
Checklists.S <- subset(Checklists, month %in% 3:7)
Checklists.W <- subset(Checklists, month %in% c(1, 2, 11, 12))

summer<- Checklists.S %>% group_by(elev_level) %>% summarise(summer = n_distinct(group.id))
winter<- Checklists.W %>% group_by(elev_level) %>% summarise(winter = n_distinct(group.id))

CL_ES<- left_join(summer,winter, by = "elev_level")
levels(CL_ES$elev_level)<-c("0-500","500-1000","1000-1500","1500-2000","2000-2500","2500-3000",">3000")
write.csv(CL_ES, "ChecklistNo_SeasonElevation_West.csv", row.names = F )

ID.S <- lapply(1:7, function(x) Checklists.S$group.id[Checklists.S$elev_level == x])
ID.W <- lapply(1:7, function(x) Checklists.W$group.id[Checklists.W$elev_level == x])

## Get unique species list
uniSpe <- dat1W %>% filter(CATEGORY == "species" | CATEGORY == "issf")
uniSpe <- unique(uniSpe[, "COMMON.NAME"]) %>% data.frame()

## Get median effort (number of checklists) across season and elevation
efforts.S <- summary(Checklists.S$elev_level)
efforts.W <- summary(Checklists.W$elev_level)
qEffort <- quantile(c(efforts.S, efforts.W), 0.50)

## sample an equal number of checklists (median effort) from each elevation band x 
set.seed(56789)
sampleID.S <- lapply(1:1000, function(y) {unlist(lapply(1:7, function(x) sample(ID.S[[x]], qEffort, replace=T)))})
set.seed(56789)
sampleID.W <- lapply(1:1000, function(y) {unlist(lapply(1:7, function(x) sample(ID.W[[x]], qEffort, replace=T)))})

# calculate the median elevation for each bird species in the two seasons
# This step takes a long computation time

rs<- lapply(1:1000, function(y) {
  m <- t(sapply(uniSpe[, 1], function(x){
    occs.S <- subset(dat1W, COMMON.NAME ==x & group.id %in% sampleID.S[[y]], select="elevation")
    occs.W <- subset(dat1W, COMMON.NAME==x & group.id %in% sampleID.W[[y]], select="elevation")
    B.n <- nrow(occs.S)
    W.n <- nrow(occs.W)
    B.elev <- if (B.n > 0) quantile(occs.S$elevation, 0.5) else NA
    W.elev <- if (W.n > 0) quantile(occs.W$elevation, 0.5) else NA
    return(c(B.elev = B.elev, B.n = B.n, W.elev = W.elev, W.n = W.n))
  }))
})

save(rs,file = "eBird_resampled_west.RData")

############# Get median difference in elevation range in Summer and Winter
load("eBird_resampled_west.RData")

B.elev <- sapply(1:1000, function(x) rs[[x]][, 1])
B.n <-    sapply(1:1000, function(x) rs[[x]][, 2])
W.elev <- sapply(1:1000, function(x) rs[[x]][, 3])
W.n <-    sapply(1:1000, function(x) rs[[x]][, 4])

diff <- B.elev - W.elev
dimnames(diff)<-list(uniSpe[,1],1:1000)

# For each species exclude trials where it has been detected less than 30 in winter or summer
diff[W.n < 30 | B.n < 30] <- NA  
diff.sel <- diff[apply(diff, 1, FUN = function(x) sum(is.na(x))) < 1000, ]

# Calculate medians of the percentiles over 1000 sets of resampled sampling events. Along with confidence intervals    
med.CI <- apply(diff.sel, 1, FUN = function(x) quantile((x), c(0.025, .5, .975), na.rm = TRUE))
med.CI <- t(med.CI)
med.CI  <- as.data.frame(med.CI)
med.CI$Group <- with(med.CI, ifelse(`2.5%` > 0 & `97.5%` > 0, 2, ifelse(`2.5%` < 0 & `97.5%` < 0, 1, 0)))
med.CI$LCI_diff <- as.numeric(med.CI$`2.5%`)
med.CI$Median_diff <- as.numeric(med.CI$`50%`)
med.CI$UCI_diff <- as.numeric(med.CI$`97.5%`)
med.CI$Species <- rownames(med.CI)
med.CI<-med.CI[,-c(1,2,3)]

## adding median breeding elevations to the same table

dimnames(B.elev)<-list(uniSpe[,1],1:1000)
B.elev[W.n < 30 | B.n < 30] <- NA

B.sel <- B.elev[apply(B.elev, 1, FUN = function(x) sum(is.na(x))) < 1000, ]

med.S.CI <- apply(B.sel, 1, FUN = function(x) quantile((x), c(0.025, .5, .975), na.rm = TRUE))
med.S.CI <- t(med.S.CI)
med.S.CI  <- as.data.frame(med.S.CI)
med.S.CI$LCI_S <- as.numeric(med.S.CI$`2.5%`)
med.S.CI$Median_S <- as.numeric(med.S.CI$`50%`)
med.S.CI$UCI_S <- as.numeric(med.S.CI$`97.5%`)
med.S.CI$Species <- rownames(med.S.CI)
med.S.CI<-med.S.CI[,-c(1,2,3)]

## adding median winter elevations to the same table

dimnames(W.elev)<-list(uniSpe[,1],1:1000)
W.elev[W.n < 30 | B.n < 30] <- NA

W.sel <- W.elev[apply(W.elev, 1, FUN = function(x) sum(is.na(x))) < 1000, ]

med.W.CI <- apply(W.sel, 1, FUN = function(x) quantile((x), c(0.025, .5, .975), na.rm = TRUE))
med.W.CI <- t(med.W.CI)
med.W.CI  <- as.data.frame(med.W.CI)
med.W.CI$LCI_W <- as.numeric(med.W.CI$`2.5%`)
med.W.CI$Median_W <- as.numeric(med.W.CI$`50%`)
med.W.CI$UCI_W <- as.numeric(med.W.CI$`97.5%`)
med.W.CI$Species <- rownames(med.W.CI)
med.W.CI<-med.W.CI[,-c(1,2,3)]

ts<-left_join(med.CI,med.S.CI, by = "Species") %>% left_join(., med.W.CI, by = "Species", )

ts <- ts[c("Species", "Group", "Median_S", "LCI_S", "UCI_S","Median_W","LCI_W","UCI_W","Median_diff","LCI_diff", "UCI_diff")]

write.csv(ts, "final_birdlist_west.csv", row.names = F)



