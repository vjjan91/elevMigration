## Source code for _High elevation Himalayan birds shift elevations to track thermal regimes across seasons_

<!-- badges: start -->

  [![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
  [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6545050.svg)](https://doi.org/10.5281/zenodo.6545050)

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

- _06_geometric-constraints.Rmd_: First (PGLS1), we tested for an association between elevational shift and the breadth of elevational distribution (elevational range) of the species, in which we calculated elevational range by subtracting the summer lower elevation limit from the summer upper elevational limit. Then (PGLS2) we tested for an association between absolute elevational shift ( to account for both upslope and downslope shifts) and the estimated summer elevation at the upper, median and lower elevational limits.   

- _07_PGLS-models.Rmd_: In this script, we used a phylogenetic generalized least squares regression to test if thermal regime, dispersal ability, and diet significantly drive Himalayan bird elevational shift.   

## Data 

The `data/` folder contains the following datasets required to reproduce the above scripts.  

### eBird data

Please download the eBird sampling and EBD dataset from https://ebird.org/home prior to running the above code. 

### Species specific data

- `species_list.csv`: Contains a list of species that was analyzed in this study.    

- `species-trait-dat.csv`: Contains selected columns of species trait data which was downloaded from Sheard et al. (2020).   

- `localities-for-map.csv`: A list of unique eBird checklist localities that were later subjected to spatial thinning.  

### Climate and elevation data

All climate and elevation data are housed in the `chelsa/` and `elevation` folder within `data/` respectively. Please note that none of this data is uploaded to GitHub as a result of the size of the datasets.  

### Spatial data

All spatial data is house in the `shapefiles` folder within `data/` folder. Here, we have included a shapefile corresponding to the entire spatial extent of the Himalayas.  

## Results

This folder contains outputs that were obtained by running the above scripts. 

## Figures

The `figs\` folder contains figures accompanying the main text. The main text figures are suffixed with numbers (example:`fig01`).   

## Attribution

To cite this repository:     

Vijay Ramesh, Tarun Menon, Sahas Barve (2022). _Source code and Supplementary material for "High elevation Himalayan birds shift elevations to track thermal regimes across seasons"_ (v1.1). Zenodo. https://doi.org/10.5281/zenodo.6545050. 

## Contact information

Please contact the following in case of interest.  

[Vijay Ramesh (repo maintainer)](https://evolecol.weebly.com/)  
PhD student, Columbia University  
