#!/bin/bash
scripts=$1
outdir=$2
inpdir=$3
thresh=$4
resol=$5
scanmode=$6
normalization=$7

echo "### Inputs queuePeakGrouping.sh ###############################################"
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

find "$outdir/hmdb_part" -iname $label | while read hmdb;
 do
     echo "Grouping on $hmdb"
     qsub -l h_rt=01:00:00 -l h_vmem=8G -N "grouping_$scanmode" $scripts/runPeakGrouping.sh $hmdb $scripts $outdir $resol $scanmode
 done

qsub -l h_rt=00:15:00 -l h_vmem=8G -N "collect1_$scanmode" -hold_jid "grouping_$scanmode" $scripts/runCollectSamplesGroupedHMDB.sh $scripts $outdir $scanmode
qsub -l h_rt=00:10:00 -l h_vmem=1G -N "queueGroupingRest_$scanmode" -hold_jid "collect1_$scanmode" $scripts/queuePeakGroupingRest.sh $scripts $outdir $inpdir $thresh $resol $scanmode $normalization