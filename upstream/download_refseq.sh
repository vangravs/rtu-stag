#!/bin/bash

ncbi="ftp.ncbi.nlm.nih.gov"
src="/refseq/release/bacteria/ /refseq/release/archaea/ /refseq/release/protozoa/ /refseq/release/fungi/"
localdir=../../refseq

wget https://ftp.ncbi.nlm.nih.gov/refseq/release/release-catalog/release205.files.installed -O checksums

mkdir -p $localdir

for s in $src; do
    echo "Processing" $s
    for f in $(curl ftp://$ncbi$s -l | grep "\.genomic\.fna\.gz$"); do
        wget -nc ftp://$ncbi$s$f -P $localdir
        grep "$(cksum $localdir/$f | awk '{print $1}')\s$f" checksums -q || { echo "Checksums don't match, aborting."; exit 1; }
    done
done

echo "All checksums match"
