## Source code for _Himalayan birds shift elevations more to remain within narrow thermal regimes across seasons_

<!-- badges: start -->

  [![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
  [![DOI](https://zenodo.org/badge/353883213.svg)](https://zenodo.org/badge/latestdoi/353883213)

<!-- badges: end -->

This repository contains code and analysis for a manuscript that uses citizen science data to study elevational migration in Himalayan birds.

## [Readable version](https://vjjan91.github.io/elevMigration/)  
A readable version of this analysis is available in bookdown format by clicking on the heading above.  

## Source code for the analyses

We describe what each script (`.Rmd`) of this repository is intended to achieve below.

- _01_spatial-thinning.Rmd:_. In this script, we spatially thin a list of localities for the sake of mapping and creating a representative figure of checklist locations for the eastern and Western Himalayas.

- _02_elevation-temperature.Rmd:_. In this script, we extracted minimum and maximum temperature for the months of January and June across every 100 m elevational band for both the eastern and western Himalayas.    

- _03_eBird-data-processing.Rmd:_. Here, we processed the [eBird](https://ebird.org/home) by applying a number of filters.   

- _04_resampling-analysis.Rmd:_. Follwing Tsai et al. (2020), we classified each species as a downslope or upslope migrant if the 95% confidence interval of the difference in the median elevation or either elevational limit of a species distribution obtained from the 1000 resamples was completely above or below zero respectively (Tsai et al. 2020).  

- _05_elevational-migration.Rmd_: To quantify the extent of elevational shift, we measured the difference between the breeding and non-breeding elevation (upper, median, and lower limit) of a species.    

- _06_PGLS-models.Rmd_: In this script, we used a phylogenetic generalized least squares regression to test if thermal regime, dispersal ability, and diet significantly drive Himalayan bird elevational shift.   

## Data 

The `data/` folder contains the following datasets required to reproduce the above scripts.  

### eBird data

Please download the eBird sampling and EBD dataset from https://ebird.org/home prior to running the above code. 

### Species specific data   

- `2020-sheard et al-species-trait-dat - speciesdata.csv`: Contains selected columns of species trait data which was downloaded from Sheard et al. (2020).   

- `localities-for-map.csv`: A list of unique eBird checklist localities that were later subjected to spatial thinning.  

- `SpeciesList_nonhimalayan`: A list of species to be omitted from analysis as these species are not exclusively migrating within the Himalayas

- `for_PGLS_list3`: Species list with taxonomy used by birdtree.org

- `birdtree.nex`: nexus file downloaded from birdtree.org for PGLS analysis


### Climate and elevation data

Please note that none of this data is uploaded to GitHub as a result of the size of the datasets. This data can be accessed from [CHELSA](https://chelsa-climate.org/) and [WorldClim](https://www.worldclim.org/) respectively.    
 

## Results

This folder contains outputs that were obtained by running the above scripts. 
  

## Attribution

To cite this repository:     

Vijay Ramesh, Tarun Menon, Sahas Barve (2023). _Source code and Supplementary material for "High elevation Himalayan birds shift elevations to track thermal regimes across seasons"_ (v1.3). Zenodo. https://doi.org/10.5281/zenodo.7762131. 

## Contact information

Please contact the following in case of interest.  

[Vijay Ramesh (repo maintainer)](https://evolecol.weebly.com/)  
Postdoctoral Fellow, Cornell Lab of Ornithology  
