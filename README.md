# udims 

## Project description 
This script is used in untargeted metabolomics analysis in urine using Direct-Infusion Massa Spec (DIMS). DIMS output consists of two outlists, one for negative scanning mode, and one for positive scanning mode. The outlists have been annotated with the use of HDMB database (ppm < 5). Utargeted metabolomics returns large datasets, this code is used to look at a subselection (ORGZ_sel), with names derived from the remote Unique_markers_urine dataframe. In the outlists, no sum has yet been made for all adducts for one compound. Adduct types are indicated in the outlist in the column 'assi_HMDB'.

## configuration
This project uses Rstudio to run scripts.

specify path & runname; change ORGZ_sel if preferred 

input: 
data/raw/runname/outlists_identified_negative.Rdata
data/raw/runname/outlists_identified_positive.Rdata 
data/raw/Unique_markers_urine.RDS 

output: 
data/processed/runname/ORGZ_plots_RUN5_pos.pdf   #pdf file with plots for your selection
data/processed/runname/ORGZ_selection_RUN.xlsx   #excel workbook for your selection 

## dependencies 

Required packages: 
ggplot2
openxlsx

## workflow 

Open the main script: 
R/Search_adducts_for_selection.R 

specify path & runname; change ORGZ_sel if preferred 

Load AddOnFunctions: [TempPackage]
R/AddOnFunctions/load_outlists.R 

Load unique-markers: 
R/AddOnFunctions/unique-markers.RDS 






# -----
# OLD TEMPLATE 
# udims

This project template is a demonstration for the RepCo workshop.

## Usage

Click "Use this template" at the top of this page to create a new repository with the same folder structure.

## Project Structure

The project structure distinguishes three kinds of folders:
- read-only (RO): not edited by either code or researcher
- human-writeable (HW): edited by the researcher only.
- project-generated (PG): folders generated when running the code; these folders can be deleted or emptied and will be completely reconstituted as the project is run.


```
.
├── .gitignore
├── CITATION.cff
├── LICENSE
├── README.md
├── requirements.txt
├── data               <- All project data, ignored by git
│   ├── processed      <- The final, canonical data sets for modeling. (PG)
│   ├── raw            <- The original, immutable data dump. (RO)
│   └── temp           <- Intermediate data that has been transformed. (PG)
├── docs               <- Documentation notebook for users (HW)
│   ├── manuscript     <- Manuscript source, e.g., LaTeX, Markdown, etc. (HW)
│   └── reports        <- Other project reports and notebooks (e.g. Jupyter, .Rmd) (HW)
├── results
│   ├── figures        <- Figures for the manuscript or reports (PG)
│   └── output         <- Other output for the manuscript or reports (PG)
└── R                  <- Source code for this project (HW)

```

## Add a citation file
Create a citation file for your repository using [cffinit](https://citation-file-format.github.io/cff-initializer-javascript/#/)

## License

This project is licensed under the terms of the [MIT License](/LICENSE).
