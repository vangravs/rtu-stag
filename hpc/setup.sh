#!/bin/bash
#
# clear out the old installation folders
cd ../..
rm -rf stag-mwc

# first thing's first clone stag if it's not here already
git clone https://github.com/kcivkulis/stag-mwc stag-mwc

# go into the folder and pull changes (mostly to deal with a case where the repohas already been pulled)
cd stag-mwc
git checkout hpc_mod # the modded branch that we're working with
git pull

# clear out the old installation folders
cd ..
rm -rf kraken2

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
rm -rf process/process_func_db # clear out the old database stag setup in case we've changed something
rm -rf databases/func_databases # get rid of the functional classification databases before recreating them

# trying plan B - maybe the conda envs need to get manipulated outside of the nodes for us to be able to consistently finish
# create a conda env 
# pipe yes to overwrite the env
module load conda
# a bit of a stupid solution - but if it works it works
source /opt/exp_soft/conda/anaconda3/etc/profile.d/conda.sh

conda init bash
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
# 09/05/2020 => metaphlan2 seems to be broken due to the database repo being set to private
echo "y" | conda install groot==0.8.4 bbmap==38.68 metaphlan==3.0

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

# remember that you're in the home dir (and we're expecting the repo to be cloned in the home dir)
# and there's a bit of an odd issue in that I can only use git in the login node for some reason
cd rtu-stag/hpc/subscripts
qsub sub.setup.sh