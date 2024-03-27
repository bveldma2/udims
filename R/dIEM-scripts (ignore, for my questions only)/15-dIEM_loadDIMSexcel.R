# Set variables for the algorithm 
path_DIMSfile <- paste0(outdir, run_name, ".xlsx") # ${outdir} in run.sh #outdir is the same as the DIMS_input_folder in local version.

#### STEP 1: Preparation #### 
# in: run_name, path_DIMSfile, header_row ||| out: output_dir, DIMS

# Check whether the file exists
if (file.exists(paste0(DIMS_output_folder,run_name,'.xlsx'))){
  HPC_done <- 1 #Yes
  cat('Excel file exists\nStart loading excel file, can take some time..')
} else {
  HPC_done <- 0 #No
  cat('Excel file not found\n')
}

# Load the excel file.
dims_xls <- readWorkbook(xlsxFile = path_DIMSfile, sheet = 1, startRow = header_row)
if (exists("dims_xls")) {
  cat(paste0("\nThe excel file is succesfully loaded:\n -> ",path_DIMSfile))
} else {
  cat(paste0("\n\n**** Error: Could not find an excel file. Please check if path to excel file is correct in config.R:\n -> ",path_DIMSfile,"\n"))
}

# what is this withratios excel? Is that the difference in the step 3 if ratios ==1 vs ratios == 0? 
#path_DIMSfile <- paste0(outdir, run_name, "withRatios.xlsx") # ${outdir} in run.sh #outdir is the same as the DIMS_input_folder in local version.
#dims_xls <- readWorkbook(xlsxFile = path_DIMSfile, sheet = 1, startRow = header_row)


#### STEP 2: Edit DIMS data #####      
# in: dims_xls ||| out: Data, nr_contr, nr_pat
# Input: the xlsx file that comes out of the pipeline with format:
# [plots] [C] [P] [summary columns] [C_Zscore] [P_Zscore]
# Output: "_CSV.csv" file that is suited for the algorithm in shiny.

# Determine the number of Contols and Patients in column names:
nr_contr <- length(grep("C",names(dims_xls)))/2   # Number of control samples: 9 
nr_pat   <- length(grep("P",names(dims_xls)))/2   # Number of patient samples: 10 
# total number of samples
nrsamples <- nr_contr + nr_pat
# check whether the number of intensity columns equals the number of Zscore columns
if (nr_contr + nr_pat != length(grep("_Zscore", names(dims_xls)))) {
  cat("\n**** Error: there aren't as many intensities listed as Zscores")
}
cat(paste0("\n\n------------\n", nr_contr, " controls \n", nr_pat, " patients\n------------\n\n"))

# Move the columns HMDB_code and HMDB_name to the beginning. 
HMDB_info_cols <- c(which(colnames(dims_xls) == "HMDB_code"), which(colnames(dims_xls) == "HMDB_name"))
other_cols     <- seq_along(1:ncol(dims_xls))[-HMDB_info_cols]
dims_xls_copy  <- dims_xls[ , c(HMDB_info_cols, other_cols)]
# Remove the columns from 'name' to 'pathway'
from_col      <- which(colnames(dims_xls_copy) == "name")
to_col        <- which(colnames(dims_xls_copy) == "pathway")
dims_xls_copy <- dims_xls_copy[ , -c(from_col:to_col)]
# in case the excel had an empty "plots" column, remove it
if ("plots" %in% colnames(dims_xls_copy)) { 
  dims_xls_copy <- dims_xls_copy[ , -grep("plots", colnames(dims_xls_copy))]
} 
# Rename columns 
names(dims_xls_copy) <- gsub("avg.ctrls", "Mean_controls", names(dims_xls_copy))
names(dims_xls_copy) <- gsub("sd.ctrls",  "SD_controls", names(dims_xls_copy))
names(dims_xls_copy) <- gsub("HMDB_code", "HMDB.code", names(dims_xls_copy))
names(dims_xls_copy) <- gsub("HMDB_name", "HMDB.name", names(dims_xls_copy))

# intensity columns and mean and standard deviation of controls
numeric_cols <- c(3:ncol(dims_xls_copy))
# make sure all values are numeric
dims_xls_copy[ , numeric_cols] <- sapply(dims_xls_copy[ , numeric_cols], as.numeric)

if (exists("dims_xls_copy") & (length(dims_xls_copy) < length(dims_xls))) {
  cat("\n### Step 2 # Edit dims data is done.\n")
} else {
  cat("\n**** Error: Could not execute step 2 \n")
}


#### STEP 3: Calculate ratios of intensities for metabolites ####      
# in: ratios, file_ratios_metabolites, dims_xls_copy, nr_contr, nr_pat ||| out: Zscore (+file)
            # why use dims_xls_copy instead of dims_xls to which the extra columns have been added? Why add cols to a file you will not further use? 
# This script loads the file with Ratios (file_ratios_metabolites) and calculates 
# the ratios of the intensities of the given metabolites. It also calculates
# Zs-cores based on the avg and sd of the ratios of the controls.

# Input: dataframe with intensities and Zscores of controls and patients:
# [HMDB.code] [HMDB.name] [C] [P] [Mean_controls] [SD_controls] [C_Zscore] [P_Zscore]

# Output: "_CSV.csv" file that is suited for the algorithm, with format:
# "_Ratios_CSV.csv" file, same file as above, but with ratio rows added.

# does the loaded excel file contain ratios already? 
if (any(grepl('[R/r]atio', path_DIMSfile))){ 
  ratios <- 0 # No, Do not add ratio's, they are already in there
  cat("ratio\'s have already been added during HPC run")
} else {
  ratios <- 1 # Yes, Still need to add the ratios to the file 
}
#ratios <- 1

if (ratios == 1) { 
  cat(paste0("\nloading ratios file:\n ->  ", file_ratios_metabolites, "\n"))
  ratio_input <- read.csv(file_ratios_metabolites, sep=';', stringsAsFactors=FALSE)
  
  # Prepare empty data frame to fill with ratios
  ratio_list <- setNames(data.frame(matrix(
    ncol=ncol(dims_xls_copy),
    nrow=nrow(ratio_input)
  )), colnames(dims_xls_copy))
  
  # put HMDB info into first two columns of ratio_list
  ratio_list[ ,1:2] <- ratio_input[ ,1:2]
  
  # look for intensity columns (exclude Zscore columns)
  control_cols   <- grep("C", colnames(ratio_list)[1:which(colnames(ratio_list) == "Mean_controls")])
  patient_cols   <- grep("P", colnames(ratio_list)[1:which(colnames(ratio_list) == "Mean_controls")])
  intensity_cols <- c(control_cols, patient_cols)
  # calculate each of the ratios of intensities 
  for (ratio_index in 1:nrow(ratio_input)) {
    ratio_numerator   <- ratio_input[ratio_index, "HMDB_numerator"] 
    ratio_numerator   <- strsplit(ratio_numerator, "plus")[[1]]
    ratio_denominator <- ratio_input[ratio_index, "HMDB_denominator"] 
    ratio_denominator <- strsplit(ratio_denominator, "plus")[[1]]
    # find these HMDB IDs in dataset. Could be a sum of multiple metabolites
    sel_denominator <- sel_numerator <- c()
    for (numerator_index in 1:length(ratio_numerator)) { 
      sel_numerator <- c(sel_numerator, which(dims_xls_copy[ , "HMDB.code"] == ratio_numerator[numerator_index])) 
    }
    for (denominator_index in 1:length(ratio_denominator)) { 
      # special case for sum of metabolites (dividing by one)  
      if (ratio_denominator[denominator_index] != "one") {
        sel_denominator <- c(sel_denominator, which(dims_xls_copy[ , "HMDB.code"] == ratio_denominator[denominator_index])) 
      }
    }
    # calculate ratio
    if (ratio_denominator[denominator_index] != "one") {
      ratio_list[ratio_index, intensity_cols] <- apply(dims_xls_copy[sel_numerator, intensity_cols], 2, sum) /
        apply(dims_xls_copy[sel_denominator, intensity_cols], 2, sum)
    } else {
      # special case for sum of metabolites (dividing by one)
      ratio_list[ratio_index, intensity_cols] <- apply(dims_xls_copy[sel_numerator, intensity_cols], 2, sum)
    }
    # calculate log of ratio
    ratio_list[ratio_index, intensity_cols]<- log2(ratio_list[ratio_index, intensity_cols])
  }
  
  #.       instead of the calculate_zscore function in the other scripts, this one doesn't use that function, but gets calculated below. 
  # Calculate means and SD's of the calculated ratios for Controls
  ratio_list[ , "Mean_controls"] <- apply(ratio_list[ , control_cols], 1, mean)
  ratio_list[ , "SD_controls"]   <- apply(ratio_list[ , control_cols], 1, sd)
  
  # Calc z-scores with the means and SD's of Controls
  zscore_cols <- grep("Zscore", colnames(ratio_list))
  for (sample_index in 1:length(zscore_cols)) {
    zscore_col <- zscore_cols[sample_index] 
    # matching intensity column
    int_col <- intensity_cols[sample_index]
    # test on column names
    if (same_samplename(colnames(ratio_list)[int_col], colnames(ratio_list)[zscore_col])) {
      # calculate Z-scores
      ratio_list[ , zscore_col] <- (ratio_list[ , int_col] - ratio_list[ , "Mean_controls"]) / ratio_list[ , "SD_controls"]
    }
  }
  
  # Add rows of the ratio hmdb codes to the data of zscores from the pipeline.
  dims_xls_ratios <- rbind(ratio_list, dims_xls_copy) #why the copy file? 
  
  # Edit the DIMS output Zscores of all patients in format:
  # HMDB_code patientname1  patientname2
  names(dims_xls_ratios) <- gsub("HMDB.code","HMDB_code", names(dims_xls_ratios))
  names(dims_xls_ratios) <- gsub("HMDB.name", "HMDB_name", names(dims_xls_ratios))
  
  # for debugging:
  write.table(dims_xls_ratios, file=paste0(outdir, "ratios.txt"), sep="\t")
  
  # Select only the cols with zscores of the patients 
  zscore_patients <- dims_xls_ratios[ , c(1, 2, zscore_cols[grep("P", colnames(dims_xls_ratios)[zscore_cols])])]
  # Select only the cols with zscores of the controls
  zscore_controls <- dims_xls_ratios[ , c(1, 2, zscore_cols[grep("C", colnames(dims_xls_ratios)[zscore_cols])])]
  
}

beep('coin')
cat('The DIMS excel file has succesfully been loaded and altered')

#outdir <- '/Volumes/metab-1/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2022/Project_2022_002_dIEM/PL_RUN1/Bioinformatics' 
# summary scripts: 
# step 1: load excel file
# step 2: alter column names and add HMDB information
# step 3: if ratios == 1 -> calculate the ratios and add to the table 

# summary datasets: 
# dims_xls <- original dims file (information columns will be added)
# dims_xls_copy <- copy of the original dims file
# dims_xls_ratios <- 18 rows of ratios added to dims_xls_copy 
#.    why not to dims_xls, that contains extra rows of information? 
# dims_xls_with_ratios <- excel file with ratios (already from the pipeline ratios calculated), depends on which file you load whether ratios == 0 (ratios already calculated), or ratios ==1 (already calculated)
#     in this case: 1 ratio added (the AC probably), since the rows from the 2022 version differ 1 row from the 2024 run! 
