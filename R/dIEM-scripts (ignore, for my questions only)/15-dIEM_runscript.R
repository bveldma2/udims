# For untargeted metabolomics, this tool calculates probability scores for 
# metabolic disorders. In addition, it provides visual support with violin plots 
# of the DIMS measurements for the lab specialists.

# Input needed: 
# 1. Excel file in which metabolites are listed with their intensities for
#    controls (with C in samplename) and patients (with P in samplename) and their
#    corresponding Z-scores. 
# 2. All files from github: https://github.com/UMCUGenetics/dIEM

## DOWNLOADS NECESSARY BEFORE RUNNING 
# 1) Create a 'dIEM' folder locally 
# 2) Create the following subfolders: 'dIEM/Scripts', 'dIEM/Input algorithm', 'dIEM/Input algorithm/AddOnFunctions', 'dIEM/Input algorithm/InputFiles'
# 3) Download the R scripts from link below to dIEM/Scripts
#.      pipeline/scripts/AddOnFunctions
# 4) Download the AddOnFunctions from link below to 'dIEM/Input algorithm/AddOnFunctions'
#.      pipeline/scripts/AddOnFunctions
# 5) Downlaod the Input Files from link(s) below to 'dIEM/Input algorithm/InputFiles'
#.      https://github.com/UMCUGenetics/dIEM/tree/main/data
#.      Rest found at ..? 

# Load packages 
library(dplyr) # tidytable is for other_isobaric.R (left_join)
library(reshape2) # used in prepare_data.R
library(openxlsx) # for opening Excel file
library(ggplot2) # for plotting
library(gridExtra) # for table top highest/lowest
library(beepr)

## Settings Input & Output 

# Settings - CHANGE THESE MANUALLY FOR EACH ANALYSIS
getwd()
project_folder <- "~/OneDrive - UMC Utrecht/1 dIEM/Testsets/Testset 1 - RUN 322/" # set to where data output should be stored 
setwd(project_folder)
input_algorithm <- "~/OneDrive - UMC Utrecht/1 dIEM/Input algorithm/" # change folder if necessary
DIMS_output_folder <- '/Volumes/metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2022/Project_2022_002_dIEM/PL_RUN1/Bioinformatics/'
#DIMS_input_folder <- '/Volumes/metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2022/Project_2022_002_dIEM/PL_RUN1/dIEM_PL_20220406_RUN1/' # here are the rawdata files stored.
run_name <- "dIEM_PL_20220406_RUN1" #needs to be the EXACT name of the run in the DIMS data. 
#run_name <- 'dIEM_PL_20220406_RUN1withRatios' # then ratios <- 0 

# Run settings - change if necessary 
z_score <- 1 #set z_score (0=N, 1=Y)
violin <- 1 #default is 1 (0=N, 1=Y)
algorithm <- 1 # do you want to run the algorithm? (0=N, 1=Y)
ratios <- 1 # do you want to add ratios to the run? (0=N, 1=Y) 
HPC <- 0 # are you running the code on HPC? (0=N, 1=Y)

# Variables under construction
#    individual_adducts <- 1 # default is 0 (No), you don't want to calculate for every run the invidual adducts, only research purposes 
#    unidentified_adducts <- 0 # default is 0 (No) (in case you want the outlist for the unidentified adducts, e.g. looking for metabolites that are not in the HMDB)
#    zscore_done <- 1 # default is 1 since hpc often calculates them, (0 = not calculated, 1 = already calculated) 
#.      isnt this the same as z_score <- 0 ? --> same goal? 

### Run the config file, depends on being run on HPC or locally. HPC<-1 should be on default!
# if local: HPC=F 
if (HPC==1){
  source('HPC/15-dIEM_config_HPC.R')
} else {
  source('~/Library/CloudStorage/OneDrive-UMCUtrecht/1 dIEM/Scripts/15-dIEM_config_local.R')
  cat('Run is local, config_local.R file has been run')
}

### Run the individual scripts. 

# first script - Load DIMS excel file & calculate ratios 
source(paste0(scripts_folder,'15-dIEM_loadDIMSexcel.R'))   

# second script - algorithm
source(paste0(scripts_folder,'15-dIEM_algorithm.R'))

# third script - violin plots 
if (violin == 1){
  source(paste0(scripts_folder,'15-violinplots.R'))
  beep('coin')
  cat('The violin plots have been made and saved')
} else {
  cat('Violin plots were not requested/made')
}

