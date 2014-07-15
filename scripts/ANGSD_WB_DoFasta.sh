#!/bin/sh
#PBS -l mem=16gb,nodes=1:ppn=1,walltime=72:00:00
#PBS -m abe
#PBS -M konox006@umn.edu
#PBS -q lab

#   First we specify values for all of our ANGSD analyses
SHARED=/home/morrellp/shared
DATA_DIR=/scratch2/tkono/ANGSD/WB
#   The directory of our reference sequence
REF_DIR=${SHARED}/References/Reference_Sequences/Barley/Morex
#   This sequence is the pseudo-scaffolds from Martin
REF_SEQ=131012_morex_pseudoscaffolds.fasta
ANGSD_DIR=/scratch2/tkono/ANGSD/angsd0.609
BAM_LIST=Wild_IPK_list.txt

cd ${DATA_DIR}

#	Generate a FASTA file for each WB sample, using the most common base
#	We can't use regions file, since doFasta doesn't understand that option
for x in `cat ${BAM_LIST}`
do
	IN=$x
	OUT=`echo $x | cut -d '/' -f 11 | cut -d '_' -f 1-2`.fasta
	${ANGSD_DIR}/angsd -doFasta 2 -i ${IN} -out ${OUT} -doCounts 1
done

