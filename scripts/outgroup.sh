#!/bin/bash -l
#PBS -L ,mem=4gb,nodes=1:ppn=1; walltime=10:00:00
#PBS -m abe 
#PBS -M pmorrell@umn.edu
#PBS -q lab

# borrowing from Tom Kono's version of angsdo.sh
ANGSD_VERSION=0.609
ANGSD_DIR=/home/morrellp/shared/Software/angsd${ANGSD_VERSION}

# outgroup sample BAM file, aligned to reference
# currently this is a Hordeum bulbosum sample aligned to Morex WGS
ANCESTRAL=/home/morrellp/shared/Datasets/NGS/Alignments/2014-03-07_IPK_BAMs/Disk_3/bams/Sample_Bulbosum_UMN_rmdup.bam

#output fasta file
#automagically receives extensions .fa.gz
OUT=/home/pmorrell/shared/Datasets/NGS/Alignments/Deleterious_Mutations/Hbulbosum_UMN

${ANGSD_DIR}/angsd \
    -i $ANCESTRAL \
    -doFasta 2 \
    -doCounts 1 \
    -out $OUT
