#!/bin/bash
scripts=$1
outdir=$2
inpdir=$3
thresh=$4
resol=$5
scanmode=$6
normalization=$7

echo "### Inputs queuePeakGroupingRest.sh ###############################################"
echo "	scripts:	${scripts}"
echo "	outdir:		${outdir}"
echo "	inpdir:		${inpdir}"
echo "	thresh:   ${thresh}"
echo "	resol:    ${resol}"
echo "	scanmode: ${scanmode}"
echo "	normalization: ${normalization}"
echo "#############################################################################"

if [ "$scanmode" == "negative" ]; then
 label="negative_*"
else
 label="positive_*"
fi

find "$outdir/specpks_all_rest" -iname $label | while read file;
 do
     echo "Grouping on $file"
     qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping2_$scanmode" $scripts/runPeakGroupingRest.sh $file $scripts $outdir $resol $scanmode
 done

qsub -l h_rt=01:00:00 -l h_vmem=8G -N "queueFillMissing_$scanmode" -hold_jid "grouping2_$scanmode" $scripts/queuefillMissing.sh $scanmode $resol $outdir $thresh $scripts $normalization