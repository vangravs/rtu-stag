#!/bin/bash
#PBS -N fill_db
#PBS -l nodes=1:ppn=1,pmem=6g
#PBS -l walltime=96:00:00
#PBS -q long
#PBS -j oe

kraken2/kraken2-build --download-taxonomy --db full_ref --use-ftp

for f in refseq/*.fna.gz
do 
	gunzip $f 
	kraken2/kraken2-build --add-to-library refseq/*.fna --db full_ref
	rm refseq/*.fna
done

