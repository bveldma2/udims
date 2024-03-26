### This script is part of the dIEM algorithm. Run this script prior to 15-dIEM_algorithm.R. 
# Two versions of this script exist: One to run on the hpc, to run in combination with the pipeline. 
# The other to run locally, e.g. for development of the algorithm or to run the algorithm additionally. 

## Load functions from HPC 

# load AddOnfunctions
source("/hpc/dbg_mz/production/DIMS/pipeline/scripts/AddOnFunctions/same_samplename.R")
source("/hpc/dbg_mz/production/DIMS/pipeline/scripts/AddOnFunctions/prepare_data.R")
source("/hpc/dbg_mz/production/DIMS/pipeline/scripts/AddOnFunctions/prepare_data_perpage.R")
source("/hpc/dbg_mz/production/DIMS/pipeline/scripts/AddOnFunctions/prepare_toplist.R")
source("/hpc/dbg_mz/production/DIMS/pipeline/scripts/AddOnFunctions/violin_plots.R")
source("/hpc/dbg_mz/production/DIMS/pipeline/scripts/AddOnFunctions/prepare_alarmvalues.R")

## Settings 

# define parameters - check after addition to run.sh
cmd_args <- commandArgs(trailingOnly = TRUE)
for (arg in cmd_args) {
  cat("  ", arg, "\n", sep = "")
}

outdir   <- cmd_args[1]  # same as input_folder in local version. HPC differs that the output gets stored in the same folder.
run_name <- cmd_args[2]
z_score  <- as.numeric(cmd_args[3]) # use Z-scores (1) or not (0)?
# Kunnen onderstaande config parameters bij in commandArgs? Violin staat er denk ik al wel in? 
# violin <- 1 #default is 1 (0 betekent nee)
# individual_adducts <- F # default is F, you don't want to calculate for every run the invidual adducts, only research purposes 


# Create output folder 
output_dir <- paste0(outdir, "/Output data dIEM") #Stores the output data in a subfolder of the input data folder 
dir.create(output_dir, showWarnings = F) 

# copy list of isomers to project folder.
file.copy("/hpc/dbg_mz/tools/isomers.txt", output_dir) 

### Load input files

# folder in which all metabolite lists are (.txt).   # these file locations should be checked on the HPC! 
path_metabolite_groups <- "/hpc/dbg_mz/tools/db/dIEM/" 
file_ratios_metabolites <- "/hpc/dbg_mz/tools/db/dIEM/data/Ratios_between_metabolites.csv" #for step 3 - prealgorithm
file_expected_biomarkers_IEM <- "/hpc/dbg_mz/tools/db/dIEM/data/Expected_biomarkers_IEM.csv" #for step 4 - algorithm
file_explanation <- "/hpc/dbg_mz/tools/db/dIEM/Explanation_violin_plots.txt" #for step 5 - violin plots 

### Load scripts 

scripts_folder <- '/hpc/dbg_mz/tools/db/dIEM/Scripts' #         #no folder yet existing in HPC! 

### Config parameters 

# The list of parameters can be shortened for HPC. Leave for now.
top_nr_IEM       <- 5 # number of diseases that score highest in algorithm to plot
threshold_IEM    <- 5 # probability score cut-off for plotting the top diseases
ratios_cutoff    <- -5 # z-score cutoff of axis on the left for top diseases
nr_plots_perpage <- 20 # number of violin plots per page in PDF

# Where do the headers and columns start? (default, 1B)
header_row    <- 1    # integer: are the sample names headers on row 1 or row 2 in the DIMS excel? (default 1)
col_start     <- "B"  # column name where the data starts (default B)
zscore_cutoff <- 5
xaxis_cutoff  <- 20

