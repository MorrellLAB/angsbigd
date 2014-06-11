#!/bin/sh

#PBS -l mem=16gb,nodes=1,ppn=1,walltime=72:00:00
#PBS -m abe
#PBS -M konox006@umn.edu
#PBS -q lab

#   This is the ANGSD script from RILab's BigD study,
#   modified for running on MSI by TomJKono.

#   Last Modified: 2014-06-11

#   Since ANGSD's version is in the directory name, we reference them both
#   in this way
ANGSD_VERSION=0.602
ANGSD_DIR=/home/morrellp/shared/Software/angsd${ANGSD_VERSION}
#   Variable stores the division of the data we are looking at
#   e.g., wild, landrace or cultivar
#   We have a separate directory for associated data files
#   In this case, the TAXON_LIST variable contains the bam filelist file for
#   all the samples we are analyzing
TAXON=cultivar
TAXON_LIST=data/${TAXON}_samples.txt
#   For windowed analyses, we modify these variables.
#   These are in units of basepairs (bp)
WINDOW_SIZE=1000
WINDOW_STEP=500
#   The number of individuals in the taxon we are analyzing
#   We use an embedded command to do this
#   ( wc -l < FILE will return just the line count of FILE,
#   rather than the line count and the filename. More efficient than piping
#   to a separate 'cut' process!)
N_IND=`wc -l < ${TAXON_LIST}`
#   For ANGSD, the actual sample size is twice the number of individuals, since
#   each individual has two chromosomes. The individual inbreeding coefficents
#   take care of the mismatch between these two numbers
N_CHROM=`expr 2 \* ${N_IND}`
#   This is an important flag; it determines the minimum number of individuals
#   with missing data that are included in the analysis
MIN_IND=1
#   The genotype likelihood model to use.
#   They are explained here:
#       http://popgen.dk/angsd/index.php/Genotype_Likelihoods
#   We probably want to use 2, for GATK likelihoods?
GT_LIKELIHOOD=2
#   The minimum mapping quality to be used in calculations
#   This is the Phred-scaled probability that a read is mapped to the wrong
#   location
MIN_MAPQ=30
#   The number of compute cores to use
N_CORES=32
#   The location to operate over
REGION="-r 10:"

#   This first command estimates the site frequency spectrum
#   Options:
#       -bam [FILE]
#           List of bam file paths in [FILE]
#       -out [FILE]
#           Output SFS to [FILE]
#       -doSaf [1|2|3|4]
#           1: Assume HWE
#           2: Take into account individual inbreeding coefficients.
#              Requires the -indF argument (We will use this one)
#           3: Calculate posterior allele frequency dist. from the file 
#              generated by -doSaf 1. (Seems circular?)
#           4: Calculate posterior probabilities given genotype probabilities
#              from another source. Requires -beagle.
#       -uniqueOnly [0/1]
#           0: Do not use only unique reads
#           1: Use only uniquely mapped reads (we use this one)
#       -anc [FILE] ancestral sequence (see trip.sh script for how this is generated)
#       -minMapQ [INT] 40 minimum mapping quality of reads to accepy
#       -minQ [INT] 20 minimum bp quality
#       -setMaxDepth [INT] 20 sets max depth to accept -- useful to deal with highly repetitive regions
#       -baq [INT] 1=realign locally (I think)
#       -GL [1|2|3|4]
#           Model used to calculate genotype likelihoods
#           1: SAMTools
#           2: GATK (We will use this one)
#           3: SOAPsnp
#           4: SYK
#       -r [RANGE]
#           Operate only on [RANGE], given in standard genomic coordinate form
#           i.e., chr:start-stop (morex_contig_1:1-100)
#       -P [INT]
#           Use [INT] threads
#       -indF
#           individiual inbreeding coefficient. for inbred lines just make a
#           files of "1" on each line for each bamfile. otherwise use ngsF
#           to estimate (see inbreeding.sh script)

command="-bam data/"$taxon"_list.txt -out temp/"$taxon" -indF data/$taxon.indF -doSaf 2 -uniqueOnly 0 -anc data/TRIP.fa.gz -minMapQ $minMapQ -minQ 20 -nInd $nInd -minInd $minInd -baq 1 -ref /home/jri/genomes/Zea_mays.AGPv2.17.dna.toplevel.fa -GL $glikehood -P $cpu -doCounts -doDepth -dumpCounts $range"
echo $command
$angsdir/angsd $command

# not clear to me how to run folded, as -fold option seems to be deprecated?
# temp/"$taxon"_pest.saf output file from above run; prior on SFS?
# $n number of chromosomes; 2 x number of inds for diploids
# results/"$taxon"_pest.em.ml This output is the final estimated SFS
	# the file will be nat. log probabilities of the value of the SFS from 0:n
	# so if n=10, there will be 11 numbers.  To plot the SFS for polymorphic sites only, ignore the first and last numbers. e.g. for teosinte I get:
	# -0.133730 -3.724029 -4.246469 -4.981319 -5.453217 -5.803669 -6.076224 -6.330416 -6.501992 -6.713127 -6.882129 -6.970549 -7.289374 -7.434923 -7.308903 -7.057695 -7.457825 -7.740251 -7.665521 -7.683324 -7.788163 -7.702094 -7.562837 -7.491339 -7.416449 -7.364919 -7.107873 -6.870063 -6.458559 -6.044445 -2.994086
	# which corresponds to exp(-0.13)~0.9 or 90% of sites are fixed for ancestral allele, and exp(-2.994086) or ~5% are fixed for derived allele. 
	# remaining 5% are polymorphic
$angsdir/misc/emOptim2 temp/"$taxon".saf $n -P $cpu  > results/"$taxon".sfs

#(calculate thetas)
# this now uses the SFS to calculate stats
# -doThetas 1 : calculate nucleotide diversity, thetaH, thetaL, wattersons theta
# -pest this is the SFS estimated above
# output $taxon.thetas will look like and have data for EVERY bp, including ones where thera are no polymorphisms. 
# in example below it's estimating nucleotide diversity as 10^-10 for the first bp (probably not polymorphic)
# but at site 26926 the estimate is 0.21 for pairwise nucleotide diversity ( that's polymorphic )
#Chromo Pos     Watterson       Pairwise        thetaSingleton  thetaH  thetaL
#10      3370    -8.664392       -10.223986      -7.289949       -13.844801      -10.890724
#10      3371    -8.822116       -10.395367      -7.431857       -14.041094      -11.062746
#10      3372    -8.840759       -10.415518      -7.448764       -14.064022      -11.082968
#10	26926	-1.480456	-0.671793	-211.328599	-0.694813	-0.683237
$angsdir/angsd -bam data/"$taxon"_list.txt -out results/"$taxon" -doThetas 1 -doSaf 2 -GL $glikehood -indF data/$taxon.indF -pest results/"$taxon".sfs -anc data/TRIP.fa.gz -uniqueOnly 0 -minMapQ $minMapQ -minQ 20 -nInd $nInd -minInd $minInd -baq 1 -ref /home/jri/genomes/Zea_mays.AGPv2.17.dna.toplevel.fa -P $cpu -doCounts -doDepth -dumpCounts $range

#(calculate Tajimas.)
# this estiamtes TajD and other stats and makes a sortof bedfile output
$angsdir/misc/thetaStat make_bed results/"$taxon".thetas.gz results/"$taxon"

# this does a sliding window analysis
# -nChr number of chromosomes
# -step how many bp to step between windows
# -win window size
# output (in this case $taxon.pestPG will look like:
#(569,1175)(4000,5001)(4000,5000)        10      4500    4.536109        4.774793        1.392152        9.523595        7.149193        0.169980        1.0433
#(963,1565)(4706,5500)(4500,5500)        10      5000    2.850285        2.665415        1.624860        4.608032        3.636723        -0.196105       0.4532
# with information for each window (see ANGSD online documentation for some explanation of columns)
$angsdir/misc/thetaStat do_stat results/"$taxon" -nChr $n -win $windowsize -step $step
