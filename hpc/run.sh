#!/bin/bash
verify_checksums=false

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

work_path="$PWD/../../"
taxon_db_path="/home/groups/lu_kpmi/databases/full_ref_bafp"
human_ref_path="/home/groups/lu_kpmi/databases/human_reference"
<<<<<<< HEAD
sample_path="/home/groups/lu_kpmi/renamed_samples/"
=======
sample_path="/home/groups/lu_kpmi/renamed_samples"
>>>>>>> 4f3fb32eb3dd999bced58eb31ccdf2d9579f37c5
resistome_path="/home/groups/lu_kpmi/databases/groot_db/arg-annot_index"

for f in ${sample_path}/*_1.fq.gz; do # for name generation, don't want to trigger twice - limiting myself to the first file of the pair
    sample=$(echo $f | sed 's:.*/::' | sed 's/_[^_]*$//')
    qsub subscripts/sub.run.sh -F "$sample $work_path $taxon_db_path $human_ref_path $sample_path $resistome_path" # create jobs for all of the samples
done
