#### This script contains the step that runs the IEM algorithm. 
# This script is deduced from step 4 from the algorithm that is attached to the pipeline. algorithm taken from DOI: 10.3390/ijms21030979

# in: algorithm, file_expected_biomarkers_IEM, zscore_patients ||| 
# out: prob_score (+file)

if (algorithm == 1) {
  # Load data
  cat(paste0("\nloading expected file:\n ->  ", file_expected_biomarkers_IEM, "\n"))
  expected_biomarkers <- read.csv(file_expected_biomarkers_IEM, sep=';', stringsAsFactors=FALSE) #output: "C/Users/bveldma2/Library/CloudStorage/OneDrive-UMCUtrecht/1 dIEM/data/Expected_biomarkers_IEM.csv"
  #expected_biomarkers <- read.csv('~/OneDrive - UMC Utrecht/1 dIEM/data/Expected_biomarkers_IEM.csv', sep=';', stringsAsFactors=FALSE)
  
  # modify column names
  names(expected_biomarkers) <- gsub("HMDB.code", "HMDB_code",  names(expected_biomarkers))  
  names(expected_biomarkers) <- gsub("Metabolite", "HMDB_name", names(expected_biomarkers))
  
  # prepare dataframe scaffold rank_patients 
  # Error in xtfrm.data.frame(x) : cannot xtfrm data frames # something with the prev. R version that is not compatible anymore!
  rank_patients <- zscore_patients
  # Fill df rank_patients with the ranks for each patient
  # Error in xtfrm.data.frame(x) : cannot xtfrm data frames # something with the prev. R version that is not compatible anymore!
  # for (patient_index in 3:ncol(zscore_patients)) {
  #   # number of positive zscores in patient
  #   pos <- sum(zscore_patients[ , patient_index] > 0) 
  #   # sort the column on zscore; NB: this sorts the entire object, not just one column
  #   rank_patients <- rank_patients[order(-rank_patients[patient_index]), ]
  #   # Rank all positive zscores highest to lowest
  #   rank_patients[1:pos, patient_index] <- as.numeric(ordered(-rank_patients[1:pos, patient_index]))
  #   # Rank all negative zscores lowest to highest
  #   rank_patients[(pos+1):nrow(rank_patients), patient_index] <- as.numeric(ordered(rank_patients[(pos+1):nrow(rank_patients), patient_index]))
  #}
  #rewritten part: 
  # order z-scores 
  for (patient_index in 3:ncol(zscore_patients)) {
    pos <- sum(zscore_patients[, patient_index] > 0)     # number of positive zscores in patient
    rank_patients[1:pos, patient_index] <- as.numeric(order(-zscore_patients[1:pos, patient_index]))     # Rank positive zscores highest to lowest
    rank_patients[(pos + 1):nrow(rank_patients), patient_index] <- as.numeric(order(zscore_patients[(pos + 1):nrow(rank_patients), patient_index]))     # Rank negative zscores lowest to highest
  }
  
  '~/OneDrive - UMC Utrecht/1 dIEM/data/Expected_biomarkers_IEM.csv' 
  # Calculate metabolite score, using the dataframes with only values, and later add the cols without values (1&2).
  expected_zscores <- merge(x=expected_biomarkers, y=zscore_patients, by.x = c("HMDB_code"), by.y = c("HMDB_code"))
  expected_zscores_original <- expected_zscores # necessary copy?
  
  # determine which columns contain Z-scores and which contain disease info
  select_zscore_cols <- grep("_Zscore", colnames(expected_zscores))
  select_info_cols <- 1:(min(select_zscore_cols) -1)
  # set some zscores to zero
  select_incr_indisp <- which(expected_zscores$Change=="Increase" & expected_zscores$Dispensability=="Indispensable")
  expected_zscores[select_incr_indisp, select_zscore_cols] <- lapply(expected_zscores[select_incr_indisp, select_zscore_cols], function(x) ifelse (x <= 1.6 , 0, x))
  select_decr_indisp <- which(expected_zscores$Change=="Decrease" & expected_zscores$Dispensability=="Indispensable")
  expected_zscores[select_decr_indisp, select_zscore_cols] <- lapply(expected_zscores[select_decr_indisp, select_zscore_cols], function(x) ifelse (x >= -1.2 , 0, x))
  
  # calculate rank score: 
  expected_ranks <- merge(x=expected_biomarkers, y=rank_patients, by.x = c("HMDB_code"), by.y = c("HMDB_code"))
  rank_scores <- expected_zscores[order(expected_zscores$HMDB_code), select_zscore_cols]/(expected_ranks[order(expected_ranks$HMDB_code), select_zscore_cols]*0.9)
  # combine disease info with rank scores
  expected_metabscore <- cbind(expected_ranks[order(expected_zscores$HMDB_code), select_info_cols], rank_scores)
  
  # multiply weight score and rank score
  weight_score <- expected_zscores
  weight_score[ , select_zscore_cols] <- expected_metabscore$Total_Weight * expected_metabscore[ , select_zscore_cols]
  
  # sort table on Disease and Absolute_Weight
  weight_score <- weight_score[order(weight_score$Disease, weight_score$Absolute_Weight, decreasing = TRUE), ]
  
  # select columns to check duplicates
  dup <- weight_score[ , c('Disease', 'M.z')] 
  uni <- weight_score[!duplicated(dup) | !duplicated(dup, fromLast=FALSE),]
  
  # calculate probability score
  prob_score <-  aggregate(uni[ , select_zscore_cols], uni["Disease"], sum)
  
  # list of all diseases that have at least one metabolite Zscore at 0
  for (patient_index in 2:ncol(prob_score)) {
    patient_zscore_colname <- colnames(prob_score)[patient_index]
    matching_colname_expected <- which(colnames(expected_zscores) == patient_zscore_colname)
    # determine which Zscores are 0 for this patient
    zscores_zero <- which(expected_zscores[ , matching_colname_expected] == 0)
    # get Disease for these 
    disease_zero <- unique(expected_zscores[zscores_zero, "Disease"])
    # set the probability score of these diseases to 0 
    prob_score[which(prob_score$Disease %in% disease_zero), patient_index]<- 0
  }
  
  # determine disease rank per patient
  disease_rank <- prob_score 
  # rank diseases in decreasing order
  disease_rank[2:ncol(disease_rank)] <- lapply(2:ncol(disease_rank), function(x) as.numeric(ordered(-disease_rank[1:nrow(disease_rank), x])))
  # modify column names, Zscores have now been converted to probability scores
  colnames(prob_score) <- gsub("_Zscore","_prob_score", colnames(prob_score)) # redundant?
  colnames(disease_rank) <- gsub("_Zscore","", colnames(disease_rank))
  
  # Create conditional formatting for output excel sheet. Colors according to values.
  wb <- createWorkbook()
  addWorksheet(wb, "Probability Scores")
  writeData(wb, "Probability Scores", prob_score)
  conditionalFormatting(wb, "Probability Scores", cols = 2:ncol(prob_score), rows = 1:nrow(prob_score), type = "colourScale", style = c("white","#FFFDA2","red"), rule = c(1, 10, 100))
  saveWorkbook(wb, file = paste0(output_dir,"/algoritme_output_attempt2_", run_name, ".xlsx"), overwrite = TRUE)
  # check whether prob_score df exists and has expected dimensions.
  if (exists("expected_biomarkers") & (length(disease_rank) == length(prob_score))) {
    cat("\n### Step 4 # Running the IEM algorithm is done.\n\n")
  } else {
    cat("\n**** Error: Could not run IEM algorithm. Check if path to expected_biomarkers csv-file is correct. \n")
  }
  
  rm(wb)
}


# Save the following parameters in an .Rdata file, so they can be loaded in for the violin plots.
save(zscore_patients, violin, nr_contr, nr_pat, Data, path_textfiles, zscore_cutoff, xaxis_cutoff, top_diseases, top_metab, output_dir, file = paste0(output_dir,"Input_violin.Rdata"))
# Error in save(zscore_patients, violin, nr_contr, nr_pat, Data, path_textfiles,  : 
#                 objects ‘Data’, ‘path_textfiles’, ‘top_diseases’, ‘top_metab’ not found

beep('coin')
cat('The algorithm has succesfully been run')
