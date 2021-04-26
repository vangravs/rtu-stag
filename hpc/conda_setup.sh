#!/bin/bash

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
