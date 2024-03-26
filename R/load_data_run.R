getwd() 
setwd("/Users/bveldma2/Library/CloudStorage/OneDrive-UMCUtrecht/1 Project Urine DIMS")
library(openxlsx)
# path <- "/Volumes/metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2023/Project_2023_012_Urine DIMS/URI_RUN3_2024-01-15/Bioinformatics/"
# path <- '/Volumes/metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2023/Project_2023_012_Urine DIMS/URI_RUN4_20240206/Bioinformatics/'
path <- '/Volumes/metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2023/Project_2023_012_Urine DIMS/URI_RUN5_20240312/Bioinformatics'

#load('~/Library/CloudStorage/OneDrive-UMCUtrecht/1 Project Urine DIMS/R scripts/calculate_zscore_adjusted.R')  GIVES AN ERROR!
# -------------------------------------------------------------------------------------------------------

### Load the data 

# Load the outlist for the positive data 
load(paste0(path,'/outlist_identified_positive.RData'))
#load("/Volumes/metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2023/Project_2023_012_Urine DIMS/UR_20221221_RUN1_stitching/outlist_identified_positive.RData")
outlist.ident.pos <- outlist.ident
outlist.not.ident.pos <- outlist.not.ident 

# Load the outlist for the negative data 
load(paste0(path,'/outlist_identified_negative.RData'))
#load("/Volumes/metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2023/Project_2023_012_Urine DIMS/UR_20221221_RUN1_stitching/outlist_identified_negative.RData")
outlist.ident.neg <- outlist.ident
outlist.not.ident.neg <- outlist.not.ident 

rm(outlist.ident)
rm(outlist.not.ident)

# Save the outlists for both the neg and pos modus
path_excel_neg <- paste0(path,'/outlist_identified_negative.xlsx')
write.xlsx(outlist.ident.neg, file = path_excel_neg, sheetName = "PeakGroups", rowNames = FALSE)
path_excel_pos <- paste0(path,'/outlist_identified_positive.xlsx')
write.xlsx(outlist.ident.pos, file = path_excel_pos, sheetName = "PeakGroups", rowNames = FALSE)


# Load the sum outputs 
RES_RUN4 <- read.xlsx('/Volumes/metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2023/Project_2023_012_Urine DIMS/URI_RUN4_20240206/Bioinformatics/UR_RUN4_20240206_BV.xlsx')
RES_RUN5 <- read.xlsx('/Volumes/metab/Metabolomics/Research Metabolic Diagnostics/Metabolomics Projects/Projects 2023/Project_2023_012_Urine DIMS/URI_RUN5_20240312/Bioinformatics/RES_UR_RUN5_20240313_noTIC2.xlsx')

# search
outlist.ident.neg[grep('HMDB00171', outlist.ident.neg$HMDB_code),]

# -------------------------------------------------------------------------------------------------------
### Calculate the Z-scores for both the pos mode
# load function calc_zscores_2 from calc_zscore_adjusted.R
# or load the original calc_zscores function in R (from Mia)

# positive mode z-scores 
outlist.ident.Zscore.pos <- calc_zscores_2(outlist.ident.pos)
outlist.not.ident.Zscore.pos <- calc_zscores_2(outlist.not.ident.pos)

# Negative mode z-scores 
outlist.ident.Zscore.neg <- calc_zscores_2(outlist.ident.neg)
outlist.not.ident.Zscore.neg <- calc_zscores_2(outlist.not.ident.neg)

# Save Z-scores 
#path_excel <- paste0(path,'/outlist_identified_negative.xlsx')
# write.xlsx(outlist.not.ident.Zscore.neg, file = path_excel, sheetName = "PeakGroups", rowNames = FALSE)
# save(outlist.ident.Zscore.pos, outlist.not.ident.Zscore.pos, file=paste0(path,"outlist_identified_positive_Zscore.RData"))
# path_excel <- paste0(path,'/outlist_identified_positive_Zscore.xlsx')
# write.xlsx(outlist.ident.Zscore.pos, file = path_excel, sheetName = "PeakGroups", row.names = FALSE)
#save(outlist.ident.Zscore.neg, outlist.not.ident.Zscore.neg, file=paste0(path,"outlist_identified_negative_Zscore.RData"))


# -------------------------------------------------------------------------------------------------------
### Merge the runs -> not recommended, too big excel files 
## for the identified outlists 

# Add the scanmode to the file for each of the sets
for (i in 1:nrow(outlist.ident.Zscore.neg)){
  outlist.ident.Zscore.neg['Scanmode'] <- 'Negative'
}
for (i in 1:nrow(outlist.ident.Zscore.pos)){
  outlist.ident.Zscore.pos['Scanmode'] <- 'Positive'
}

# combine lists 
combined_outlist_Zscore <- rbind(outlist.ident.Zscore.neg,outlist.ident.Zscore.pos)

# write the table to .txt file
write.table(combined_outlist_Zscore[ , c(4,6:ncol(combined_outlist_Zscore))], file = paste(path, "URI_RUN3_combined_outlist_Zscore_2.txt", sep = "/"), sep="\t", row.names = FALSE)
path_excel <- paste0(path,'/outlist_identified_combined_Zscore.xlsx')
write.xlsx(combined_outlist_Zscore, file = path_excel, sheetName = "PeakGroups", row.names = FALSE)


# -------------------------------------------------------------------------------------------------------
### for the unidentified: 

# Add both scanmode & unidentified to the columns 
for (i in 1:nrow(outlist.not.ident.Zscore.neg)){
  outlist.not.ident.Zscore.neg['Scanmode'] <- 'Negative'
  outlist.not.ident.Zscore.neg['Identified'] <- 'Not identified'
}
for (i in 1:nrow(outlist.not.ident.Zscore.pos)){
  outlist.not.ident.Zscore.pos['Scanmode'] <- 'Positive'
  outlist.not.ident.Zscore.pos['Identified'] <- 'Not identified'
}

# combine lists & write the table 
combined_outlist_unidentified_Zscore <- rbind(outlist.not.ident.Zscore.neg,outlist.not.ident.Zscore.pos)
write.table(combined_outlist_unidentified_Zscore[ , c(4,6:ncol(combined_outlist_Zscore))], file = paste(path, "URI_RUN3_combined_outlist_Zscore_unidentified.txt", sep = "/"), sep="\t", row.names = FALSE)

