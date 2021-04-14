#!/bin/bash
# the goal of this script is to get the environment as a whole set up 
# 
# how many threads do we have?
threads=12
pull_kraken=false # NB - this takes a while to run and kraken2 has a habit of failing silently
pull_humann=false # no point in pulling the humann2 databases if we're not using them atm

# https://github.com/conda/conda/issues/7980
# these are the two default locations I've encountered
#source /etc/profile.d/conda.sh 
source ~/anaconda3/etc/profile.d/conda.sh

# clear out the old installation folders
cd ../..
rm -rf stag-mwc

# first thing's first clone stag if it's not here already
git clone https://github.com/kcivkulis/stag-mwc stag-mwc

# go into the folder and pull changes (mostly to deal with a case where the repohas already been pulled)
cd stag-mwc
git checkout hpc_mod # the modded branch that we're working with
git pull

# create a conda env 
# pipe yes to overwrite the env
echo "y" | conda create --name stag-mwc python=3
conda activate stag-mwc

# and add needed channels
#
# order matters - https://forum.biobakery.org/t/metaphlan3-installation-fails/350/2
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge

# at this point we've cloned stag and need to run their setup process - conda is expected to be installed already
# pipe yes into the install to silence prompts
echo "y" | conda install -c bioconda -c conda-forge snakemake==5.5.4

# clear out the old installation folders
cd ..
rm -rf kraken2

echo pwd

# we need to download and compile kraken2 to avoid using the segfaulting conda version
#
# remeber that build-essential have to be installed (at least in the wsl ubuntu build)
# apt-get install build-essential
git clone https://github.com/DerrickWood/kraken2.git kraken2
cd kraken2
./install_kraken2.sh ../kraken2_installed
# get rid of the repo folder and move the installation dir to a nicer looking folder name
cd ..
rm -rf kraken2
mv kraken2_installed kraken2

# setting up the kraken2 taxon database
#
# purge any databases that we may have set up for this already
rm -rf databases/taxon_databases

# set up the kraken2 database that we'll be matching our taxons agains
mkdir -p databases/taxon_databases
cd databases/taxon_databases
if [ "$pull_kraken" = true ] ; then
    ../../kraken2/kraken2-build --download-taxonomy --db kraken_taxon --threads $threads --use-ftp  # use ftp gets ignored if it's at the beginning (?)
    ../../kraken2/kraken2-build --download-library archaea --db kraken_taxon --threads $threads --use-ftp --no-masking
    ../../kraken2/kraken2-build --download-library bacteria --db kraken_taxon --threads $threads --use-ftp --no-masking
    ../../kraken2/kraken2-build --download-library fungi --db kraken_taxon --threads $threads --use-ftp --no-masking
    ../../kraken2/kraken2-build --build --db kraken_taxon --threads $threads
    rm -rf kraken_taxon/library # get rid of the 4 gig library source files
    # set up the refence database that we'll be using to filter the reads (note that it's the GRCh38 reference)
    mkdir human_reference
    mv kraken_taxon/taxonomy human_reference/taxonomy # this takes up around 30 gigs - if we can avoid downloading it again we should
fi
if [ "$pull_kraken" = false ] ; then
    # we're not pulling the taxonomy database via kraken2 - fetch minikraken instead
    wget ftp://ftp.ccb.jhu.edu/pub/data/kraken2_dbs/old/minikraken2_v2_8GB_201904.tgz -O minikraken2_v2_8GB_201904.tgz
    tar zxvf minikraken2_v2_8GB_201904.tgz
    rm minikraken2_v2_8GB_201904.tgz
    mv minikraken2_v2_8GB_201904_UPDATE kraken_taxon
    # taxonomies didn't get pulled for the taxon base - need to pull them now
    ../../kraken2/kraken2-build --download-taxonomy --db human_reference --threads $threads --use-ftp
fi
../../kraken2/kraken2-build --use-ftp --no-masking --download-library human --db human_reference --threads $threads
../../kraken2/kraken2-build --build --db human_reference --threads $threads
rm -rf human_reference/library # get rid of the 76 gig taxonomy library files
rm -rf human_reference/taxonomy # get rid of the 30 gig taxonomy source files

# 09/05/2020 => metaphlan2 seems to be broken due to the database repo being set to private
echo "y" | conda install groot==0.8.4 bbmap==38.68 metaphlan==3.0

# move back to the base dir
cd ../..
rm -rf process/process_func_db # clear out the old database stag setup in case we've changed something
rm -rf databases/func_databases # get rid of the functional classification databases before recreating them

# set up the new stag instance that we'll be using
mkdir -p process/process_func_db
cp -r stag-mwc process/process_func_db/stag-mwc
cp rtu-stag/configs/config.db.local.yaml process/process_func_db/stag-mwc/config.yaml # changing the name to the default simplifies running

# making fake input files to make stag happy (it throws errors without a sample to work with)
cd process/process_func_db/stag-mwc
mkdir input
touch input/1_1.fq.gz
touch input/1_2.fq.gz
# build up the databases using stag
snakemake create_groot_index --cores $threads

if [ "$pull_humann" = true ] ; then
    # set up metaphlan
    metaphlan --install # I'm pretty sure we only need metaphlan if we're dealing with humann2
    # humann2 is being needlesly annoying due to dependency conflicts
    # will just rip the commands out of stag and run it as is
    # snakemake download_humann2_databases --cores 12
    #
    # setup a conda env running python 2
    # pipe yes to overwrite the env
    echo "y" | conda create --name humann2 python=2
    conda activate humann2
    # and add needed channels
    conda config --add channels defaults
    conda config --add channels bioconda
    conda config --add channels conda-forge
    # pipe yes into the install to silence prompts
    echo "y" | conda install -c bioconda -c conda-forge humann2==2.8.1 
    # download_humann2_databases
    cd ../../.. # path out of the stag copy and move back to the base dir
    humann2_databases --download chocophlan full databases/func_databases/humann2
    humann2_databases --download uniref uniref90_diamond databases/func_databases/humann2
fi
