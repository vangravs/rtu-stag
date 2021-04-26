#!/bin/bash
# we need to keep the samples from running in parallel - building up dummy environments for
# the individual samples
#
# how many threads do we have?
threads=12
run_humann=false # NB - this makes the whole process A LOT more taxing on your cpu and power delivery system
verify_checksums=true 
# https://github.com/conda/conda/issues/7980
# these are the two default locations I've encountered
#source /etc/profile.d/conda.sh 
source ~/anaconda3/etc/profile.d/conda.sh

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

# move back to the base folder
cd ../..
rm -rf process/process_* # get rid of all of the old files
# work through all of the samples
for f in rtu-stag/samples/*.gz; do
    echo $f
    # get the trimmed down file name
    trimmed=$(echo $f | grep -o '[0-9]\+_[0-9]\+\.fq\.gz')
    # get the sample number
    sample=$(echo $f | grep -o '[0-9]\+_[0-9]\+\.fq\.gz' | grep -o '[0-9]\+_' | grep -o '[0-9]\+')

    # create the folder that his samples stag environment will live in
    # only do stuff if we've not set up this sample already
    if [ ! -d "process/process_$sample" ]; then 
        mkdir -p "process/process_$sample"
        # move stag into this samples folder
        cp -r stag-mwc "process/process_$sample/stag-mwc"
        cp rtu-stag/configs/config.local.yaml "process/process_$sample/stag-mwc/config.yaml" # changing the name to the default simplifies running
        mkdir "process/process_$sample/stag-mwc/input"
    fi
    # move the sample to the stag folder
    cp $f "process/process_$sample/stag-mwc/input/$trimmed"
done

# make directory for outputs in case it doesn't exist
mkdir -p outputs

for f in process/process_*; do
    # get the sample number
    sample=$(echo $f | grep -o '[0-9]\+')
    cd "$f/stag-mwc"
    conda activate stag-mwc
    snakemake --use-conda --cores $threads
    cd ../../.. # move back into the base dir
    if [ "$run_humann" = true ] ; then
        # run the humann2 stuff outside of stag - just ripping the whole thing to deal with dep conflicts between humann2 and snakemake
        humann2_dir="$f/stag-mwc/output_dir/humann2/"
        metaphlan_dir="$f/stag-mwc/output_dir/metaphlan/"
        mkdir -p $humann2_dir
        mkdir -p $metaphlan_dir
        # at this point we know that host_removal samples exist due to them being made for groot
        echo "#SampleID\t$sample" > mpa2_table-v2.7.7.txt
        # metaphlan had to run before humann2
        metaphlan --input_type fastq --nproc $threads --sample_id ${sample} --bowtie2out "${metaphlan_dir}${sample}.bowtie2.bz2" "$f/stag-mwc/output_dir/host_removal/${sample}_1.fq.gz","$f/stag-mwc/output_dir/host_removal/${sample}_2.fq.gz" -o "${metaphlan_dir}${sample}.metaphlan.txt"   
        # looks like metaphlan 3 has broken downloads as well
        #
        # Convert MPA 3 output to something like MPA2 v2.7.7 output 
        # so it can be used with HUMAnN2, avoids StaG issue #138.
        # TODO: Remove this once HUMANn2 v2.9 is out.
        sed '/#/d' "${metaphlan_dir}${sample}.metaphlan.txt" | cut -f1,3 >> "${humann2_dir}mpa2_table-v2.7.7.txt"
        cat "$f/stag-mwc/output_dir/host_removal/${sample}_1.fq.gz" "$f/stag-mwc/output_dir/host_removal/${sample}_2.fq.gz" > "${humann2_dir}concat_input_reads.fq.gz"
        # humann2
        conda activate humann2
        humann2 --input "${humann2_dir}concat_input_reads.fq.gz" --output $humann2_dir --nucleotide-database "databases/func_databases/humann2/chocophlan" --protein-database "databases/func_databases/humann2/uniref" --output-basename $sample --threads $threads --taxonomic-profile "${humann2_dir}mpa2_table-v2.7.7.txt" 
        # normalize_humann2_tables
        humann2_renorm_table --input "${humann2_dir}${sample}_genefamilies.tsv" --output "${humann2_dir}${sample}_genefamilies_relab.tsv" --units relab --mode community 
        humann2_renorm_table --input "${humann2_dir}${sample}_pathabundance.tsv" --output "${humann2_dir}${sample}_pathabundance_relab.tsv" --units relab --mode community
        # join_humann2_tables
        humann2_join_tables --input $humann2_dir --output "${humann2_dir}all_samples.humann2_genefamilies.tsv" --file_name genefamilies_relab
        humann2_join_tables --input $humann2_dir --output "${humann2_dir}all_samples.humann2_pathabundance.tsv" --file_name pathcoverage
        humann2_join_tables --input $humann2_dir --output "${humann2_dir}all_samples.humann2_pathcoverage.tsv" --file_name pathabundance_relab
        # cleanup after finishing  
        rm "$f/stag-mwc/output_dir/humann2/concat_input_reads.fq.gz"
        rm -rf "$f/stag-mwc/output_dir/humann2/*_humann2_temp"
    fi
    # cleanup after finishing    
    #rm -rf "$f/stag-mwc/output_dir/fastp/"
    #rm -rf "$f/stag-mwc/output_dir/host_removal/"
    #rm -rf "$f/stag-mwc/output_dir/logs/" # <- logs weigh borderline nothing - may as well leave them in
    # save the output folder and free up the space taken
    datestamp=$(date -d "today" +"%Y%m%d%H%M")
    mv "$f/stag-mwc/output_dir" "outputs/output_dir_${sample}_${datestamp}"
    mv "$f/stag-mwc/input" "outputs/output_dir_${sample}_${datestamp}/input"
    rm -rf $f
done