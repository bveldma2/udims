load_outlists <- function(path) {
  # Load the outlist for the positive data
  load(paste0(path, "/outlist_identified_positive.RData"))
  outlist.ident.pos <- outlist.ident
  outlist.not.ident.pos <- outlist.not.ident
  # Load the outlist for the negative data
  load(paste0(path, "/outlist_identified_negative.RData"))
  outlist.ident.neg <- outlist.ident
  outlist.not.ident.neg <- outlist.not.ident
  # clear the environment 
  rm(outlist.not.ident) 
  rm(outlist.not.ident)
  # Assign variables to the global environment
  assign("outlist.ident.pos", outlist.ident.pos, envir = .GlobalEnv)
  assign("outlist.not.ident.pos", outlist.not.ident.pos, envir = .GlobalEnv)
  assign("outlist.ident.neg", outlist.ident.neg, envir = .GlobalEnv)
  assign("outlist.not.ident.neg", outlist.not.ident.neg, envir = .GlobalEnv)
}