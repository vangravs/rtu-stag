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
