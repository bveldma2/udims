library(openxlsx)

### Load unique marker list 
#path <- '~/Library/CloudStorage/OneDrive-UMCUtrecht/1 Project Urine DIMS/Biomarker- en patientenlijsten/'
#file_name <- 'Unieke_markers_urine_upload_R.xlsx'

path <- '/Volumes/metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2023/Project_2023_012_Urine DIMS/Methode/'
file_name <- 'Unique_markers_urine_copy.xlsx'
Unique_markers_urine <- read.xlsx(paste0(path,file_name))

# load outlist.ident 
#RES_RUN3 <- read.xlsx('/Volumes/metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2023/Project_2023_012_Urine DIMS/URI_RUN3_2024-01-15/Bioinformatics/UR_RUN3_20240115_B.xlsx')
RES_RUN4 <- read.xlsx('/Volumes/metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2023/Project_2023_012_Urine DIMS/URI_RUN4_20240206/Bioinformatics/UR_RUN4_20240206_BV.xlsx')

### Look in the outlist, which biomarkers have a similar name 

# Loop over the list: works but finds only 4? 
for (i in Unique_markers_urine$Biomarker) {
  Unique_markers_urine$HMDB_code_5[Unique_markers_urine$Biomarker == i] <- outlist.ident[outlist.ident$assi_HMDB == i, "HMDB_code"]
}  

for (i in Unique_markers_urine$Biomarker) {
  i <- toupper(i)
  idx <- which(toupper(Unique_markers_urine$Biomarker) == i)
  hmdb_codes <- RES_RUN3[toupper(RES_RUN3$HMDB_name) == i, "HMDB_code"]
  # hmdb_codes <- RES_RUN3[toupper(RES_RUN3$HMDB_name) == i, "HMDB_code"]
  hmdb_names <- RES_RUN3[toupper(RES_RUN3$HMDB_name) == i, "HMDB_name"]
  # hmdb_names <- RES_RUN3[toupper(RES_RUN3$HMDB_name) == i, "HMDB_name"]
  if (!is.na(hmdb_codes) && length(hmdb_codes) > 0) {
    Unique_markers_urine$HMDB_code_5[idx] <- hmdb_codes
    Unique_markers_urine$HMDB_name[idx] <- hmdb_names
  }
}


###  Manual approach: 

# search the metabolites which have NA as hmdb code 
#Unique_markers_urine$HMDB_code_5[Unique_markers_urine$HMDB_code_5 == "NA"] <- NA
na_rows <- which(is.na(Unique_markers_urine$HMDB_code_5))
for (i in na_rows) {
  print(Unique_markers_urine$Biomarker[i])
}
cat(paste0('length: ',length(na_rows)),'from a total of: ', nrow(Unique_markers_urine)) #194 left 

# choose one from the list and try their english alternative:
metabolite_UMU <- 'L-Alanine' # UMU = Unique Markers Urine 
search_metabolite <- 'L-Alanine' # E.g. tyrosine, valine, tryptophan
RES_RUN3[grep(search_metabolite,RES_RUN3$HMDB_name,ignore.case=T),c('HMDB_code','HMDB_name')]

# change the table: 
Unique_markers_urine$HMDB_name[Unique_markers_urine$Biomarker == metabolite_UMU] <- 'Beta-N-Acetylglucosamine'
Unique_markers_urine$HMDB_code_5[Unique_markers_urine$Biomarker == metabolite_UMU] <- 'HMDB00803'

# add a new row:
new_row <- data.frame(Biomarker = 'L-Pipecolic acid', HMDB_name = 'L-Pipecolic acid', HMDB_code_5 = 'HMDB00716', HMDB_code_7 = NA,  synonym = NA, Adducts = NA)
Unique_markers_urine <- rbind(Unique_markers_urine, new_row)

# double check:
Unique_markers_urine[Unique_markers_urine$Biomarker == 'Threonine',]


#delete old row: 
Unique_markers_urine <- Unique_markers_urine[Unique_markers_urine$Biomarker != 'L-Pipecolic acid', ]

# Save changes 
library(openxlsx)
write.xlsx(Unique_markers_urine, file = paste0(path,'Unique_markers_urine_copy.xlsx'))


# ----------------------------
