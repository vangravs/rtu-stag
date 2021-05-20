#!/bin/bash
#PBS -N build_db
#PBS -l nodes=1:ppn=32,pmem=6g
#PBS -l walltime=96:00:00
#PBS -q long
#PBS -j oe
#PBS -d .

# TODO: This might not fit in 96 hours. Probably have to split in multiple scripts.

module load conda
# a bit of a stupid solution - but if it works it works
source /opt/exp_soft/conda/anaconda3/etc/profile.d/conda.sh
conda init bash
conda activate stag-mwc

cd ../..

# Build kraken2 BAFP database

kraken2/kraken2-build --download-taxonomy --db full_ref --use-ftp

add_to_library()
{
	echo "Processing" $1
	gunzip $1
	kraken2/kraken2-build --add-to-library ${1%.gz} --db full_ref || exit 1
	rm -v ${1%.gz}
	echo "Processed" $1
}

cur=0

for f in refseq/*.fna.gz
do
	add_to_library $f &
	((cur=(cur+1)%32))
	((cur==0)) && { wait; echo "Batch processed"; }
done
wait

kraken2/kraken2-build --build --db full_ref --threads 32

bracken-build -d /mnt/home/groups/lu_kpmi/full_ref -t 30 -k 35 -l 150

# Build human reference database

mkdir -p human_reference

mv full_ref/taxonomy human_reference/taxonomy # this takes up around 30 gigs - if we can avoid downloading it again we should
kraken2/kraken2-build --download-library human --db human_reference --threads 32 --use-ftp --no-masking
kraken2/kraken2-build --build --db human_reference --threads 32

# TODO: The code below is unchecked

# # set up the new stag instance that we'll be using
# mkdir -p process/process_func_db
# cp -r stag-mwc process/process_func_db/stag-mwc
# export ENABLE_QC_READS=False
# export ENABLE_HOST_REMOVAL=False
# export ENABLE_KRAKEN2=False
# export ENABLE_GROOT=False
# export prefix=""
# envsubst < rtu-stag/configs/config.hpc.yaml > process/process_func_db/stag-mwc/config.yaml # changing the name to the default simplifies running
#
# # making fake input files to make stag happy (it throws errors without a sample to work with)
# cd process/process_func_db/stag-mwc
# mkdir input
# touch input/1_1.fq.gz
# touch input/1_2.fq.gz
# # build up the databases using stag
# snakemake create_groot_index --cores $threads
#
# if [ "$pull_humann" = true ] ; then
#     # set up metaphlan
#     metaphlan --install # I'm pretty sure we only need metaphlan if we're dealing with humann2
#
#     conda activate humann2
#     # download_humann2_databases
#     cd ../../.. # path out of the stag copy and move back to the base dir
#     humann2_databases --download chocophlan full databases/func_databases/humann2
#     humann2_databases --download uniref uniref90_diamond databases/func_databases/humann2
# fi
