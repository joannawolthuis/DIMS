#!/usr/bin/Rscript

.libPaths(new="/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

run <- function(resultDir, scanmode) {
  # resultDir="./results"
  # scanmode="negative"

  object.files = list.files(paste(resultDir, "adductSums", sep="/"), full.names=TRUE, pattern=paste(scanmode, "_", sep=""))

  outlist.tot=NULL
  for (i in 1:length(object.files)) {
    load(object.files[i])
    outlist.tot = rbind(outlist.tot, adductsum)
  }

  save(outlist.tot, file=paste0(resultDir, "/adductSums_", scanmode, ".RData"))
}

cat("Start collectSamplesAdded.R")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

run(cmd_args[1], cmd_args[2])

cat("Ready collectSamplesAdded.R")
