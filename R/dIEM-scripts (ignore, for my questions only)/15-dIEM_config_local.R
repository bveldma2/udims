### This script is part of the dIEM algorithm. This script will be automatically run through the 15-dIEM_runscript.R file. 
# Two versions of this script exist: One to run on the hpc, to run in combination with the pipeline. 
# The other to run locally, e.g. for development of the algorithm or to run the algorithm additionally. 

## Folder settings 

output_folder <- paste0(project_folder,'/Output data/')
dir.create(output_folder,showWarnings =F)
#DIMS_input_folder <- paste0(project_folder,'DIMS data/') # but DIMS data needs to be already there? DIMS empty?
# These names originate from the original script; should be changed throughout the script to input_ and output_folder for clarity?
outdir <- DIMS_output_folder #needed for variable path_DIMSfile #change outdir for indir throughout? 
output_dir <- output_folder 


## Load AddOnfunctions locally

# load functions
source(paste0(input_algorithm,'AddOnFunctions/same_samplename.R'))
source(paste0(input_algorithm,'AddOnFunctions/prepare_data.R')) 
source(paste0(input_algorithm,'AddOnFunctions/prepare_data_perpage.R'))
source(paste0(input_algorithm,'AddOnFunctions/prepare_toplist.R')) 
source(paste0(input_algorithm,'AddOnFunctions/violin_plots.R'))
source(paste0(input_algorithm,'AddOnFunctions/prepare_alarmvalues.R')) 

# copy list of isomers to project folder.
file.copy(paste0(input_algorithm,'/InputFiles/isomers.txt'),output_dir)

## Load input files 

# folder in which all metabolite lists are (.txt)
path_metabolite_groups <- paste0(input_algorithm,"InputFiles/metabolite_groups")   #"/hpc/dbg_mz/tools/db/dIEM/ or #"C:/Users/birgi/OneDrive - UMC Utrecht/dIEM/metabolite_groups"
file_ratios_metabolites <- paste0(input_algorithm,"InputFiles/Ratios_between_metabolites.csv") # file for algorithm step 3
file_expected_biomarkers_IEM <- paste0(input_algorithm,"InputFiles/Expected_biomarkers_IEM.csv") # file for algorithm step 4
file_explanation <- paste0(input_algorithm,"InputFiles/Explanation_violin_plots.txt") # explanation: file with text to be included in violin plots

## Load R scripts

scripts_folder <- '~/OneDrive - UMC Utrecht/1 dIEM/Scripts/'

## General config parameters 

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


