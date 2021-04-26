#!/bin/bash
verify_checksums=false

mkdir -p ~/outputs

if $verify_checksums; then
    # work out if all files have downloaded properly by verifying checksums
    cd ../samples
    all_good=true

    for f in *.fq.gz
    do
        checksum="$(shasum -a512 $f)"

        if ! grep -q "$checksum" checksums.txt ; then
            echo "The checksum for $f could not be matched - please either delete the sample or redownload it"
            all_good=false
        fi
    done

    if ! $all_good; then
        echo "Please review damaged sample files and restart the script"
        exit 1
    fi
fi

cd ~/
home_path="$PWD"
taxon_db_path="/home/groups/lu_kpmi/databases/full_ref_bafp"
human_ref_path="/home/groups/lu_kpmi/databases/human_reference"
sample_path="/home/groups/lu_kpmi/renamed_samples/"
resistome_path="/home/groups/lu_kpmi/databases/groot_db/arg-annot_index"

cd ~/rtu-stag/hpc/subscripts/

for f in ${sample_path}*_1.fq.gz; do # for name generation, don't want to trigger twice - limiting myself to the first file of the pair
    sample=$(echo $f | sed 's:.*/::' | sed 's/_[^_]*$//')
    qsub sub.run.sh -F "$sample $home_path $taxon_db_path $human_ref_path $sample_path $resistome_path" # create jobs for all of the samples
done
