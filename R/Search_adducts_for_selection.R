### udims script
#in: outlists | unique-markers
#out: excel workbook | pdf with plots 

# load libraries 
library('ggplot2')
#library('gridExtra')
library('openxlsx')

# config: 
path <- 'data/raw/' #change this manually 
runname <- 'testrun' 

# load required objects & functions 
Unique_markers_urine <- read.xlsx(paste0(path,'Unique_markers_urine_copy.xlsx')) #load dataframe 
load('~/R/AddOnFunctions/load_outlists.R') #load add on function 
RES_RUN <- read.xlsx(paste0(path,'/udims/data/raw/RES_UR_RUN5_20240313_noTIC2.xlsx')) #load dataset-in

# Look for a certain selection of unique markers in your data 
ORGZ_sel <- c('Lactaat','3-OH boterzuur','3-OH-propionzuur','3-OH isovaleriaanzuur','Methylmalonzuur','Glutaarzuur','malaat','3-OH-adipinezuur','Homovanillinezuur','vanillylamandelzuur ','5-oxo-proline')

# Retrieve selection (=ORGZ_sel) from Unique_markers_urine 
ORGZ_SEL <- data.frame()
for (i in ORGZ_sel){
  df <- Unique_markers_urine[Unique_markers_urine$Biomarker == i,]
  ORGZ_SEL <- rbind(ORGZ_SEL, df)
}

### Find the matching HMDB_name per HMDB_code 
for (i in 1:nrow(ORGZ_SEL)) {
  # Look for the HMDBs in HMDB_code_5
  hmdb_codes <- strsplit(ORGZ_SEL$HMDB_code_5[i], "\r\n")
  hmdb_codes <- unlist(hmdb_codes)
  # Define pattern to match any of the HMDB codes, add 'or' search token |
  pattern <- paste0(hmdb_codes, collapse = "|")
  # last check for whitespaces 
  pattern <- gsub('\\s',"",pattern)
  hmdb_names <- RES_RUN$HMDB_name[grep(pattern, RES_RUN$HMDB_code)]
  hmdb_names <- paste(hmdb_names, collapse = '|')
  #hmdb_names <- hmdb_names[hmdb_names != ""]
  ORGZ_SEL$HMDB_name[i] <- hmdb_names
}

# check some individually:
name <- 'Homovanillic acid'
RES_RUN[grep(name,RES_RUN$HMDB_name),c('HMDB_code','HMDB_name')]
HMDB_code <- 'HMDB62492'
RES_RUN[grep(HMDB_code,RES_RUN$HMDB_code),c('HMDB_code','HMDB_name')]

HMDB_code <- 'HMDB00243'
HMDB_name <- 'Lactic acid'
pyruvic_acid <- outlist.ident.pos[grep(HMDB_code,outlist.ident.pos$HMDB_code),]
pyruvic_acid <- outlist.ident.pos[grep(HMDB_name,outlist.ident.pos$assi_HMDB),]
NH4_sel <- isotope_matches_data_pos_all[isotope_matches_data_pos_all$adduct.nr == '_4',]
isotopes_db

# make a subdf of the data for ORGZ_SEL & add the pattern and the name! 
rundata <- RES_RUN
RUN_ORGZ <- data.frame()
for (i in 1:nrow(ORGZ_SEL)){
  hmdb_codes <- strsplit(ORGZ_SEL$HMDB_code_5[i], "\r\n")
  hmdb_codes <- unlist(hmdb_codes)
  pattern <- paste0(hmdb_codes, collapse = "|")
  pattern <- gsub('\\s',"",pattern)
  matching_rows <- rundata[grep(pattern,rundata$HMDB_code),]
  matching_rows$pattern[i] <- pattern 
  hmdb_names <- rundata$HMDB_name[grep(pattern, rundata$HMDB_code)]
  hmdb_names <- paste(hmdb_names, collapse = '|')
  matching_rows$hmdb_names <- hmdb_names
  RUN_ORGZ <- rbind(RUN_ORGZ,matching_rows)
}

# Now do the same with the outlist 

# load the data from load_data_RUN
RUN_ORGZ_adducts <- data.frame() #dataset_out 
dataset_in <- outlist.ident.neg #outlist.not.ident.[pos|neg] not connected to hmdb code! Then look for m/z values from the ident. one. 
# OUTPUT: 90 positive adducts for 11 metabolites; 120 negative adducts for 11 metabolites. 

for (i in 1:nrow(ORGZ_SEL)){
  hmdb_codes <- strsplit(ORGZ_SEL$HMDB_code_5[i], "\r\n")
  hmdb_codes <- unlist(hmdb_codes)
  pattern <- paste0(hmdb_codes, collapse = "|")
  pattern <- gsub('\\s',"",pattern)
  matching_rows <- dataset_in[grep(pattern,dataset_in$HMDB_code),] #change 2x dataset_in
  RUN_ORGZ_adducts <- rbind(RUN_ORGZ_adducts,matching_rows) #change 2x dataset_out 
}

# write.xlsx(RUN4_ORGZ_adducts, file = paste0(path,'RUN4_ORGZ_adducts.xlsx'), sheetName = "PeakGroups", rowNames = FALSE)
# write.xlsx(RUN4_ORGZ, file = paste0(path,'RUN4_ORGZ.xlsx'), sheetName = "PeakGroups", rowNames = FALSE)

#Save both in an excel workbook:

# Create workbook for the sums (adjusted version below >> delete )
# library(openxlsx)      
# ORGZ_RUN4 <- createWorkbook()
# 
# addWorksheet(ORGZ_RUN4, sheetName = "RUN4_ORGZ")
# writeData(ORGZ_RUN4, sheet = "RUN4_ORGZ", x = RUN4_ORGZ,startRow = 1, startCol = 1, rowNames = TRUE)
# addWorksheet(ORGZ_RUN4, sheetName = "RUN4_ORGZ_adducts")
# writeData(ORGZ_RUN4, sheet = "RUN4_ORGZ_adducts", x = RUN4_ORGZ_adducts, startRow = 1, startCol = 1, rowNames = TRUE)
# 
# saveWorkbook(ORGZ_RUN4, file = paste0(path, 'ORGZ_selection_RUN4.xlsx'))

# -------- # ----------- # ------------------ 
### Do the same as above, now add for the adducts the search-hmdb and the corresponding name to make finding easier 

# create the dataframe for the adducts 
RUN_ORGZ_adducts <- data.frame() #dataset_out 
RUN_ORGZ_adducts['pattern'] <- ""
RUN_ORGZ_adducts['hmdb_names'] <- ""
dataset_in <- outlist.ident.pos #outlist.not.ident.[pos|neg] not connected to hmdb code! Then look for m/z values from the ident. one. 
# OUTPUT: 90 positive adducts for 11 metabolites; 120 negative adducts for 11 metabolites. 

# # working version (but without saving the adduct type)
# for (i in 1:nrow(ORGZ_SEL)){
#   hmdb_codes <- strsplit(ORGZ_SEL$HMDB_code_5[i], "\r\n")
#   hmdb_codes <- unlist(hmdb_codes)
#   pattern <- paste0(hmdb_codes, collapse = "|")
#   pattern <- gsub('\\s',"",pattern)
#   matching_rows <- dataset_in[grep(pattern,dataset_in$HMDB_code),] #change 2x dataset_in
#   matching_rows$pattern <- pattern
#   hmdb_names <- RES_RUN$HMDB_name[grep(pattern, RES_RUN$HMDB_code)]
#   hmdb_names <- paste(hmdb_names, collapse = '|')
#   matching_rows$hmdb_names <- hmdb_names
#   RUN4_ORGZ_adducts <- rbind(RUN4_ORGZ_adducts,matching_rows) #change 2x dataset_out 
# }

##  Extended version - including adduct_type and adduct.type (HMDB012345_X and [M-H] added to the dataframe)
RUN_ORGZ_adducts_neg <- data.frame() #dataset_out 
RUN_ORGZ_adducts_pos <- data.frame() #dataset_out 
# RUN4_ORGZ_adducts_b['pattern'] <- ""
# RUN4_ORGZ_adducts_b['hmdb_names'] <- ""
# RUN4_ORGZ_adducts_b['adduct_type'] <- ""

### ---- RUN this part entirely for neg ------
# change for pos/neg
RUN_ORGZ_adducts <- data.frame()
dataset_in <- outlist.ident.neg #outlist.not.ident.[pos|neg] not connected to hmdb code! Then look for m/z values from the ident. one. 
scanmode <- 'Negative'

# or pos
RUN_ORGZ_adducts <- data.frame()
dataset_in <- outlist.ident.pos #outlist.not.ident.[pos|neg] not connected to hmdb code! Then look for m/z values from the ident. one. 
scanmode <- 'Positive'

for (i in 1:nrow(ORGZ_SEL)){
  hmdb_codes <- strsplit(ORGZ_SEL$HMDB_code_5[i], "\r\n")
  hmdb_codes <- unlist(hmdb_codes)
  pattern <- paste0(hmdb_codes, collapse = "|")
  pattern <- gsub('\\s',"",pattern)
  matching_rows <- dataset_in[grep(pattern,dataset_in$HMDB_code),] #change 2x dataset_in
  matching_rows$pattern <- pattern
  hmdb_names <- rundata$HMDB_name[grep(pattern, rundata$HMDB_code)]
  hmdb_names <- paste(hmdb_names, collapse = '|')
  matching_rows$hmdb_names <- hmdb_names
  hmdb_codes_adduct <- unlist(dataset_in$HMDB_code[i], pattern)
  for (i in 1:nrow(matching_rows)) {
    adduct_pattern <- paste0('^',pattern,'(_[1-9]|(1[0-1]))?')
    hmdb_codes_adduct <- unlist(strsplit(matching_rows$HMDB_code[i],';'))
    match_index <- grep(adduct_pattern, hmdb_codes_adduct)
    adduct_type <- paste(hmdb_codes_adduct[match_index],collapse='|')
    matching_rows[i, "adduct_type"] <- adduct_type
    matching_rows$scanmode <- scanmode
  }
  RUN_ORGZ_adducts <- rbind(RUN_ORGZ_adducts,matching_rows) #change 2x dataset_out 
}

RUN_ORGZ_adducts_neg <- RUN_ORGZ_adducts
RUN_ORGZ_adducts_pos <- RUN_ORGZ_adducts

# --------- until here per scanmode 

### Match the adduct_type to the adducts 
# load the adducts and the adducts indexes
negative_adducts <- c('[M-H]-',
                      '[M+Cl]-',
                      '[M+For]-',
                      '[M+NaCl]-',
                      '[M+KCl]-',
                      '[M+H2PO4]-',
                      '[M+HSO4]-',
                      '[M+Na-H]-',
                      '[M+K-H]-',
                      '[M-H2O]',
                      '[M-2H]-',
                      '[M+I]-')
index_negative_adducts <- c(';|$',paste0('_',1:11))
positive_adducts <-  c('[M+H]+',
                       '[M+Na]+',
                       '[M+K]+',
                       '[M+NaCl]+',
                       '[M+NH4]+',
                       '[M+2Na-H]+',
                       '[M+CH3OH]+',
                       '[M+KCl]+',
                       '[M+NaK-H]+')
index_positive_adducts <- c(';|$',paste0('_',1:8))
color_codes <- c(
  "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
  "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf",
  "#1f77b4", "#aec7e8", "#ffbb78", "#98df8a", "#ff9896")
color_descriptions <- c(                     
  "Blue", "Orange", "Green", "Red", "Purple",
  "Brown", "Pink", "Gray", "Olive", "Teal",
  "Light Blue", "Lighter Blue", "Light Orange", "Light Green", "Light Red"
)

# create the dataframes for the pos and neg mode 
pos_adducts <- data.frame(adduct_index = index_positive_adducts, adduct_type = positive_adducts, adduct_colorcode = color_codes[1:9], color_descr = color_descriptions[1:9])
neg_adducts <- data.frame(adduct_index = index_negative_adducts, adduct_type = negative_adducts, adduct_colorcode = color_codes[1:12], color_descr = color_descriptions[1:12])
# colnames(pos_adducts) <- c('adduct_index','adduct_type')
# colnames(neg_adducts) <- c('adduct_index','adduct_type')

# LET OP: pos_adducts en adduct_db_pos bestaan beide --> misschien beter om 1 bestand van te maken? 
# hoogstwaarschijnlijk nodig om binnenkort scripts te herorganiseren voor overzicht!

# loop over RUN4_ORGZ_adducts to check adduct_type and extract the adduct.type
for (i in 1:nrow(neg_adducts)) {
  for (j in 1:nrow(RUN_ORGZ_adducts_neg)) {
    if (grepl(neg_adducts$adduct_index[i], RUN_ORGZ_adducts_neg[j, 'adduct_type']) && RUN_ORGZ_adducts_neg[j, 'scanmode'] == 'Negative') {
      RUN_ORGZ_adducts_neg[j, 'adduct.type'] <- neg_adducts$adduct_type[i]
    } 
  }
}

for (i in 1:nrow(pos_adducts)) {
  for (j in 1:nrow(RUN_ORGZ_adducts_pos)) {
    if (grepl(pos_adducts$adduct_index[i], RUN_ORGZ_adducts_pos[j, 'adduct_type']) && RUN_ORGZ_adducts_pos[j, 'scanmode'] == 'Positive') {
      RUN_ORGZ_adducts_pos[j, 'adduct.type'] <- pos_adducts$adduct_type[i]
    } 
  }
}

# ----- need to have run pos and neg by here ------- 
library(openxlsx)

ORGZ_RUN <- createWorkbook()

# sums worksheet
addWorksheet(ORGZ_RUN, sheetName = "RUN_ORGZ_sums")
writeData(ORGZ_RUN, sheet = "RUN_ORGZ_sums", x = RUN_ORGZ ,startRow = 1, startCol = 1, rowNames = TRUE)

# aducts worksheets for both pos and neg 
addWorksheet(ORGZ_RUN, sheetName = "RUN_ORGZ_adducts_neg")
writeData(ORGZ_RUN, sheet = "RUN_ORGZ_adducts_neg", x = RUN_ORGZ_adducts_neg, startRow = 1, startCol = 1, rowNames = TRUE)
addWorksheet(ORGZ_RUN, sheetName = "RUN_ORGZ_adducts_pos")
writeData(ORGZ_RUN, sheet = "RUN_ORGZ_adducts_pos", x = RUN_ORGZ_adducts_pos, startRow = 1, startCol = 1, rowNames = TRUE)

saveWorkbook(ORGZ_RUN, file = paste0(path, '/',run_name,'ORGZ_selection_RUN.xlsx'))

# Save the extended version 
# --------- create plots 

# INPUT FOR CODE BELOW 
df <- RUN_ORGZ_adducts_pos
mode_adducts <- pos_adducts 

# extract sample and ORGZ names 
unique_names <- unique(df$hmdb_names) 
print(ORGZ_SEL[,c('Biomarker','HMDB_name')])
sample_names <- colnames(df)[7:31]

# # Combine adduct types and color codes into a named vector
# adduct_color_mapping <- c(negative_adducts, positive_adducts)
# names(adduct_color_mapping) <- c(color_codes[1:12], color_codes[1:9])
# unique_adduct_colors <- unique(df_melted[, c("adduct.type", "color")])
# print(unique_adduct_colors)
# adduct_color_mapping <- setNames(adduct_colors[1:length(all_adduct_types)], all_adduct_types)

# # Define plot dimensions
# plot_width <- 6  # Adjust as needed
# plot_height <- 4  # Adjust as needed

# add color codes to df per adduct type 
for (i in 1:nrow(df)){
  for (j in 1:nrow(mode_adducts)){
    if (df$adduct.type[i] == mode_adducts$adduct_type[j]){
      df$color[i] <- mode_adducts$adduct_colorcode[j]
    }
  }
}

# Create a PDF file to save all plots
pdf(paste0(path,"/ORGZ_plots_RUN5_pos.pdf"), width = 8.27, height = 11.69)

# loop over every ORGZ and create subdf&graph per ORGZ
plots <- list()
for (i in 1:length(unique_names)) {
  #graph_name <- unique_names[i]
  graph_name <- ORGZ_sel[i]
  df_data <- df[df$hmdb_names == unique_names[i], c(sample_names,"adduct.type",'color')]
  df_melted <- tidyr::gather(df_data, key = "Sample", value = "Intensity", -adduct.type, -color)
  plot <- ggplot(data = df_melted, aes(x = Sample, y = Intensity, group = adduct.type, color = adduct.type)) + 
    geom_line() +
    labs(x = "Sample Names", y = "Intensities", title = graph_name) +  
    scale_color_manual(values = unique_adduct_colors$color) +  #values = adduct_color_mapping # turns grey, why? 
    theme_minimal() + 
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
          plot.margin = margin(1, 1, 1.3, 1, "cm"),
          legend.position = "bottom",           # Position legend below the plot
          legend.box = "horizontal",            # Arrange legend items horizontally
          legend.text = element_text(size = 8), # Decrease legend text size
          legend.title = element_text(size = 10), 
          legend.key.width = unit(0.5, "cm")) +   # Increase legend width
    guides(color = guide_legend(title.position = "top", title.hjust = 0.5, title.vjust = 0, ncol = 3, byrow=F)) 
  # plot <- plot + guides(color = guide_legend(nrow = 3, byrow = TRUE))
  
    # guides(color = guide_legend(title = "Adduct Type"))  
  # print(plot)
  # Duplicate plot with y-axis range from 0 to 1E4
  plot_y_range <- plot + ylim(0, 1E4)
  
  # Store both plots in the list
  #plots[[i]] <- plot
  plots[[2 * i - 1]] <- plot
  plots[[2 * i]] <- plot_y_range
  #print(plot_y_range)
}

# Loop over subsets of plots to create multiple pages
for (page in seq_len(ceiling(num_plots / plots_per_page))) {
  start_index <- (page - 1) * plots_per_page + 1
  end_index <- min(page * plots_per_page, num_plots)
  plots_subset <- plots[start_index:end_index]
  print(grid.arrange(grobs = plots_subset, ncol = num_cols, nrow = num_rows))
}

# Close the PDF device
dev.off()

#no idea anymore if i used this part of the one above, sorry
# adjust parameters for loop above 
num_plots <- length(plots)
num_cols <- 2  # Fixed number of columns
num_rows <- 2  # Fixed number of rows per page
plots_per_page <- num_cols * num_rows

# ---- 
# Print each plot to the single PDF file
# for (k in 1:length(plots)) {
#   # print(plots[[k]])
# }

# Close the PDF device
dev.off()


# from the workshop 
install.packages("styler")
install.packages("lintr")
library("styler")
lint('Search_adducts_for_selection.R')
styler('Search_adducts_for_selection.R')
install.packages('renv')
renv::init()
renv::activate()
renv::status()
renv::snapshot()
Y
getwd()
