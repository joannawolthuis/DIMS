#!/bin/bash

INDIR=$1
OUTDIR=$2
SCRIPTS=$3
LOGDIR=$4
MAIL=$5

scanmode=$6
thresh=$7
label=$8
adducts=$9

. $INDIR/settings.config

find "$OUTDIR/grouping_rest" -iname "${scanmode}_*" | while read rdata;
 do
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME'"_${rdata}.txt" -e $LOGDIR/'$JOB_NAME'"_${rdata}.txt" $SCRIPTS/13-runFillMissing.sh $rdata $OUTDIR $scanmode $thresh $resol $SCRIPTS/R
  #Rscript runFillMissing.R $rdata $scanmode $resol $OUTDIR $thresh $SCRIPTS
 done

find "$OUTDIR/grouping_hmdb" -iname "*_${scanmode}.RData" | while read rdata2;
 do
  qsub -l h_rt=02:00:00 -l h_vmem=8G -N "peakFilling2_$scanmode" -hold_jid "peakFilling_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME_${rdata2}.txt" -e $LOGDIR/'$JOB_NAME_${rdata2}.txt" $SCRIPTS/13-runFillMissing.sh $rdata2 $OUTDIR $scanmode $thresh $resol $SCRIPTS/R
  #Rscript runFillMissing.R $rdata2 $scanmode $resol $OUTDIR $thresh $SCRIPTS
 done

qsub -l h_rt=01:00:00 -l h_vmem=8G -N "collect2_$scanmode" -hold_jid "peakFilling2_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME.txt' -e $LOGDIR/'$JOB_NAME.txt' $SCRIPTS/14-runCollectSamplesFilled.sh $OUTDIR $scanmode $normalization $SCRIPTS/R
#Rscript collectSamplesFilled.R $OUTDIR $scanmode $SCRIPTS $normalization

qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueSumAdducts_$scanmode" -hold_jid "collect2_$scanmode" -m as -M $MAIL -o $LOGDIR/'$JOB_NAME.txt' -e $LOGDIR/'$JOB_NAME.txt' $SCRIPTS/15-queueSumAdducts.sh $INDIR $OUTDIR $SCRIPTS $LOGDIR $MAIL $scanmode $thresh $label $adducts
