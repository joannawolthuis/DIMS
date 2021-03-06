#!/usr/bin/Rscript

.libPaths(new="/hpc/local/CentOS7/dbg_mz/R_libs/3.2.2")

run <- function(resultDir, scanmode, normalization, scripts, db, z_score) {
  #resultDir <- "/Users/nunen/Documents/Metab/processed/test_old"
  #scanmode <- "negative"
  #normalization <- "disabled"
  #scripts <- "/Users/nunen/Documents/Metab/DIMS/scripts"
  #db <- "/Users/nunen/Documents/Metab/DIMS/db/HMDB_add_iso_corrNaCl_withIS_withC5OH.RData"
  #z_score <- 0
  
  object.files = list.files(paste(resultDir, "samplePeaksFilled", sep="/"), full.names=TRUE, pattern=scanmode)
  
  outlist.tot=NULL
  for (i in 1:length(object.files)) {
    load(object.files[i])
    outlist.tot = rbind(outlist.tot, final.outlist.idpat3)
  }
  
  source(paste(scripts, "AddOnFunctions/sourceDir.R", sep="/"))
  sourceDir(paste(scripts, "AddOnFunctions", sep="/"))
  
  # remove duplicates
  outlist.tot = mergeDuplicatedRows(outlist.tot)
  
  # sort on mass
  outlist.tot = outlist.tot[order(outlist.tot[,"mzmed.pgrp"]),]
  
  # normalization
  load(paste0(resultDir, "/repl.pattern.",scanmode,".RData"))
  load(db)
  
  if (scanmode=="negative"){
    label = "MNeg"
    HMDB_add_iso=HMDB_add_iso.Neg
    fileName = "Intensity_all_peaks_negative_norm"
  } else {
    label = "Mpos"
    HMDB_add_iso=HMDB_add_iso.Pos
    fileName = "Intensity_all_peaks_positive_norm"
  }
  
  if (normalization != "disabled") {
    outlist.tot = normalization_2.1(outlist.tot, fileName, names(repl.pattern.filtered), on=normalization, assi_label="assi_HMDB")
  }
  
  if (z_score == 1) {
    outlist.stats = statistics_z(outlist.tot, sortCol=NULL, adducts=FALSE)
    nr.removed.samples=length(which(repl.pattern.filtered[]=="character(0)"))
    order.index.int=order(colnames(outlist.stats)[8:(length(repl.pattern.filtered)-nr.removed.samples+7)])
    outlist.stats.more = cbind(outlist.stats[,1:7],
                               outlist.stats[,(length(repl.pattern.filtered)-nr.removed.samples+8):(length(repl.pattern.filtered)-nr.removed.samples+8+6)],
                               outlist.stats[,8:(length(repl.pattern.filtered)-nr.removed.samples+7)][order.index.int],
                               outlist.stats[,(length(repl.pattern.filtered)-nr.removed.samples+5+10):ncol(outlist.stats)])
    
    tmp.index=grep("_Zscore", colnames(outlist.stats.more), fixed = TRUE)
    tmp.index.order=order(colnames(outlist.stats.more[,tmp.index]))
    tmp = outlist.stats.more[,tmp.index[tmp.index.order]]
    outlist.stats.more=outlist.stats.more[,-tmp.index]
    outlist.stats.more=cbind(outlist.stats.more,tmp)
    outlist.tot = outlist.stats.more
  }
  
  # filter identified compounds
  index.1=which((outlist.tot[,"assi_HMDB"]!="") & (!is.na(outlist.tot[,"assi_HMDB"])))
  index.2=which((outlist.tot[,"iso_HMDB"]!="") & (!is.na(outlist.tot[,"iso_HMDB"])))
  index=union(index.1,index.2)
  outlist.ident = outlist.tot[index,]
  outlist.not.ident = outlist.tot[-index,]
  
  if (z_score == 1) {
    outlist.ident$ppmdev=as.numeric(outlist.ident$ppmdev)
  }
  # NAs in theormz_noise <======================================================================= uitzoeken!!!
  outlist.ident$theormz_noise[which(is.na(outlist.ident$theormz_noise))] = 0
  outlist.ident$theormz_noise=as.numeric(outlist.ident$theormz_noise)
  outlist.ident$theormz_noise[which(is.na(outlist.ident$theormz_noise))] = 0
  outlist.ident$theormz_noise=as.numeric(outlist.ident$theormz_noise)
  
  save(outlist.not.ident, outlist.ident, file=paste(resultDir, "/outlist_identified_", scanmode, ".RData", sep=""))
  
  # cut HMDB ##########################################################################################################################################
  outdir=paste(resultDir, "hmdb_part_adductSums", sep="/")
  dir.create(outdir, showWarnings = FALSE)
  load(paste(resultDir, "breaks.fwhm.RData", sep="/"))
  
  # filter mass range meassured!!!
  HMDB_add_iso = HMDB_add_iso[which(HMDB_add_iso[,label]>=breaks.fwhm[1] & HMDB_add_iso[,label]<=breaks.fwhm[length(breaks.fwhm)]),]
  
  outlist=HMDB_add_iso
  
  # remove adducts for summing the adducts!
  outlist_IS = outlist[grep("IS",rownames(outlist),fixed=TRUE),]
  outlist = outlist[grep("HMDB",rownames(outlist),fixed=TRUE),]
  outlist = outlist[-grep("_",rownames(outlist),fixed=TRUE),]
  outlist = rbind(outlist_IS, outlist)
  outlist = outlist[order(outlist[,label]),]
  
  n=dim(outlist)[1]
  sub=300
  end=0
  check=0
  
  if (n>=sub & (floor(n/sub))>=2){
    for (i in 1:floor(n/sub)){
      start=-(sub-1)+i*sub
      end=i*sub
      
      # message(paste("start:",start))
      # message(paste("end:",end))
      
      outlist_part = outlist[c(start:end),]
      save(outlist_part, file=paste(outdir, paste(scanmode, paste("hmdb",i,"RData", sep="."), sep="_"), sep="/"))
    }
  }
  
  start = end + 1
  end = n
  
  # message(paste("start:",start))
  # message(paste("end:",end))
  
  outlist_part = outlist[c(start:end),]
  save(outlist_part, file=paste(outdir, paste(scanmode, paste("hmdb",i+1,"RData", sep="."), sep="_"), sep="/"))
  
}

cat("Start collectSamplesFilled.R")
cat("==> reading arguments:\n", sep = "")

cmd_args = commandArgs(trailingOnly = TRUE)

for (arg in cmd_args) cat("  ", arg, "\n", sep="")

run(cmd_args[1], cmd_args[2], cmd_args[3], cmd_args[4], cmd_args[5], cmd_args[6])

cat("Ready collectSamplesFilled.R")
