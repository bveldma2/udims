#### STEP 5: Make violin plots #####      
# in: algorithm / zscore_patients, violin, nr_contr, nr_pat, Data, path_textfiles, zscore_cutoff, xaxis_cutoff, top_diseases, top_metab, output_dir ||| 
# out: pdf file

# Load the saved variables from the dIEM algorithm. 
load(paste0(output_dir,"Input_violin.Rdata")) 

if (violin == 1) { # make violin plots
  
  # preparation
  # isobarics_txt <- c()
  zscore_patients_copy <- zscore_patients 
  # keep the original for testing purposes, remove later. 
  colnames(zscore_patients) <- gsub("_RobustZscore", "_Zscore", colnames(zscore_patients)) # for robust scaler
  colnames(zscore_patients) <- gsub("_Zscore", "", colnames(zscore_patients))
  colnames(zscore_controls) <- gsub("_RobustZscore", "_Zscore", colnames(zscore_controls)) # for robust scaler
  colnames(zscore_controls) <- gsub("_Zscore", "", colnames(zscore_controls))
  
  # Make patient list for violin plots
  patient_list <- names(zscore_patients)[-c(1,2)]
  
  # from table expected_biomarkers, choose selected columns 
  select_columns <- c("Disease", "HMDB_code", "HMDB_name")
  select_col_nrs <- which(colnames(expected_biomarkers) %in% select_columns)
  expected_biomarkers_select <- expected_biomarkers[ , select_col_nrs]
  # remove duplicates
  expected_biomarkers_select <- expected_biomarkers_select[!duplicated(expected_biomarkers_select[ , c(1,2)]), ]
  
  # load file with explanatory information to be included in PDF.
  explanation <- readLines(file_explanation)
  
  # for debugging:
  #write.table(explanation, file=paste0(outdir, "explanation_read_in.txt"), sep="\t")
  
  # first step: normal violin plots
  # Find all text files in the given folder, which contain metabolite lists of which
  # each file will be a page in the pdf with violin plots.
  # Make a PDF file for each of the categories in metabolite_dirs
  metabolite_dirs <- list.files(path=path_metabolite_groups, full.names=FALSE, recursive=FALSE) 
  for (metabolite_dir in metabolite_dirs) {
    # create a directory for the output PDFs
    pdf_dir <- paste(output_dir, metabolite_dir, sep="/")
    dir.create(pdf_dir, showWarnings=FALSE)
    cat("making plots in category:", metabolite_dir, "\n")
    
    # get a list of all metabolite files
    metabolite_files <- list.files(path=paste(path_metabolite_groups, metabolite_dir, sep="/"), pattern="*.txt", full.names=FALSE, recursive=FALSE)
    
    # put all metabolites into one list
    metab_list_all <- list()
    metab_list_names <- c()
    cat("making plots from the input files:")
    # open the text files and add each to a list of dataframes (metab_list_all)
    for (file_index in seq_along(metabolite_files)) {
      infile <- metabolite_files[file_index]
      metab_list <- read.table(paste(path_metabolite_groups, metabolite_dir, infile, sep="/"), sep = "\t", header = TRUE, quote="")
      # put into list of all lists
      metab_list_all[[file_index]] <- metab_list
      metab_list_names <- c(metab_list_names, strsplit(infile, ".txt")[[1]][1])
      cat(paste0("\n", infile))
    } 
    # include list of classes in metabolite list
    names(metab_list_all) <- metab_list_names
    
    # prepare list of metabolites; max nr_plots_perpage on one page
    metab_interest_sorted <- prepare_data(metab_list_all, zscore_patients)
    metab_interest_controls <- prepare_data(metab_list_all, zscore_controls)
    metab_perpage <- prepare_data_perpage(metab_interest_sorted, metab_interest_controls, nr_plots_perpage, nr_pat, nr_contr)
    
    # make violin plots per patient
    for (pt_nr in 1:length(patient_list)) {
      pt_name <- patient_list[pt_nr]
      # for category Diagnostics, make list of metabolites that exceed alarm values for this patient
      # for category Other, make list of top highest and lowest Z-scores for this patient
      if (grepl("Diagnost", pdf_dir)) {
        top_metab_pt <- prepare_alarmvalues(pt_name, metab_interest_sorted)
        # save(top_metab_pt, file=paste0(outdir, "/start_15_prepare_alarmvalues.RData"))
      } else {
        top_metab_pt <- prepare_toplist(pt_name, zscore_patients)
        # save(top_metab_pt, file=paste0(outdir, "/start_15_prepare_toplist.RData"))
      }
      
      # generate normal violin plots
      violin_plots(pdf_dir, pt_name, metab_perpage, top_metab_pt)
      
    } # end for pt_nr
    
  } # end for metabolite_dir
  
  # Second step: dIEM plots in separate directory
  dIEM_plot_dir <- paste(output_dir, "dIEM_plots", sep="/")
  dir.create(dIEM_plot_dir)
  
  # Select the metabolites that are associated with the top highest scoring IEM, for each patient
  # disease_rank is from step 4: the dIEM algorithm. The lower the value, the more likely.
  for (pt_nr in 1:length(patient_list)) {
    pt_name <- patient_list[pt_nr]
    # get top diseases for this patient
    pt_colnr <- which(colnames(disease_rank) == pt_name)
    pt_top_indices <- which(disease_rank[ , pt_colnr] <= top_nr_IEM)
    pt_IEMs <- disease_rank[pt_top_indices, "Disease"]
    pt_top_IEMs <- pt_prob_score_top_IEMs <- c()
    for (single_IEM in pt_IEMs) {
      # get the probability score
      prob_score_IEM <- prob_score[which(prob_score$Disease == single_IEM), pt_colnr]
      # use only diseases for which probability score is above threshold
      if (prob_score_IEM >= threshold_IEM) {
        pt_top_IEMs <- c(pt_top_IEMs, single_IEM)
        pt_prob_score_top_IEMs <- c(pt_prob_score_top_IEMs, prob_score_IEM)
      }
    }
    
    # prepare data for plotting dIEM violin plots
    # If prob_score_top_IEM is an empty list, don't make a plot
    if (length(pt_top_IEMs) > 0) {
      # Sorting from high to low, both prob_score_top_IEMs and pt_top_IEMs.
      pt_prob_score_order <- order(-pt_prob_score_top_IEMs)
      pt_prob_score_top_IEMs <- round(pt_prob_score_top_IEMs, 1)
      pt_prob_score_top_IEM_sorted <- pt_prob_score_top_IEMs[pt_prob_score_order]
      pt_top_IEM_sorted <- pt_top_IEMs[pt_prob_score_order]
      # getting metabolites for each top_IEM disease exactly like in metab_list_all
      metab_IEM_all <- list()
      metab_IEM_names <- c()
      for (single_IEM_index in 1:length(pt_top_IEM_sorted)) {
        single_IEM <- pt_top_IEM_sorted[single_IEM_index]
        single_prob_score <- pt_prob_score_top_IEM_sorted[single_IEM_index]
        select_rows <- which(expected_biomarkers_select$Disease == single_IEM)
        metab_list <- expected_biomarkers_select[select_rows, ]
        metab_IEM_names <- c(metab_IEM_names, paste0(single_IEM, ", probability score ", single_prob_score))
        metab_list <- metab_list[ , -1]
        metab_IEM_all[[single_IEM_index]] <- metab_list
      }
      # put all metabolites into one list
      names(metab_IEM_all) <- metab_IEM_names
      
      # get Zscore information from zscore_patients_copy, similar to normal violin plots
      metab_IEM_sorted <- prepare_data(metab_IEM_all, zscore_patients_copy)
      metab_IEM_controls <- prepare_data(metab_IEM_all, zscore_controls)
      # make sure every page has 20 metabolites
      dIEM_metab_perpage <- prepare_data_perpage(metab_IEM_sorted, metab_IEM_controls, nr_plots_perpage, nr_pat)
      #warnings()
      # generate dIEM violin plots
      violin_plots(dIEM_plot_dir, pt_name, dIEM_metab_perpage, top_metab_pt)
    } else {
      cat(paste0("\n\n**** This patient had no prob_scores higher than ", threshold_IEM,".
                   Therefore, this pdf was not made:\t ", pt_name ,"_IEM \n"))
    }
    
  } # end for pt_nr
  
} # end if violin = 1
