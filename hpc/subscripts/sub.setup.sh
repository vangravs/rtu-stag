#!/bin/bash
#PBS -N setup_stag
#PBS -l nodes=1:ppn=8,pmem=6g
#PBS -l walltime=16:00:00
#PBS -q long
#PBS -j oe

# how many threads do we have?
threads=8

# create a conda env 
# pipe yes to overwrite the env
module load conda
# a bit of a stupid solution - but if it works it works
source /opt/exp_soft/conda/anaconda3/etc/profile.d/conda.sh

conda init bash
conda activate stag-mwc

# set up the kraken2 database that we'll be matching our taxons agains
mkdir -p databases/taxon_databases
cd databases/taxon_databases
../../kraken2/kraken2-build --download-taxonomy --db kraken_taxon --threads $threads --use-ftp  # use ftp gets ignored if it's at the beginning (?)
../../kraken2/kraken2-build --download-library archaea --db kraken_taxon --threads $threads --use-ftp --no-masking
../../kraken2/kraken2-build --download-library bacteria --db kraken_taxon --threads $threads --use-ftp --no-masking
../../kraken2/kraken2-build --download-library fungi --db kraken_taxon --threads $threads --use-ftp --no-masking
../../kraken2/kraken2-build --build --db kraken_taxon --threads $threads
rm -rf kraken_taxon/library # get rid of the 4 gig library source files
# set up the refence database that we'll be using to filter the reads (note that it's the GRCh38 reference)
mkdir human_reference
mv kraken_taxon/taxonomy human_reference/taxonomy # this takes up around 30 gigs - if we can avoid downloading it again we should
../../kraken2/kraken2-build --download-library human --db human_reference --threads $threads --use-ftp --no-masking
../../kraken2/kraken2-build --build --db human_reference --threads $threads
rm -rf human_reference/library # get rid of the 76 gig taxonomy library files
rm -rf human_reference/taxonomy # get rid of the 30 gig taxonomy source files

# move back to the base dir
cd ../..
# set up the new stag instance that we'll be using
mkdir -p process/process_func_db
cp -r stag-mwc process/process_func_db/stag-mwc
cp rtu-stag/configs/config.db.hpc.yaml process/process_func_db/stag-mwc/config.yaml # changing the name to the default simplifies running

# making fake input files to make stag happy (it throws errors without a sample to work with)
cd process/process_func_db/stag-mwc
mkdir input
touch input/1_1.fq.gz
touch input/1_2.fq.gz
# build up the databases using stag
snakemake create_groot_index --cores $threads
# set up metaphlan
metaphlan --install

conda activate humann2
# download_humann2_databases
cd ../../.. # path out of the stag copy and move back to the base dir
humann2_databases --download chocophlan full databases/func_databases/humann2
humann2_databases --download uniref uniref90_diamond databases/func_databases/humann2