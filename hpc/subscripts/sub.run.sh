#!/bin/bash
#PBS -N run_sample
#PBS -l feature=largescratch
#PBS -l nodes=1:ppn=32,pmem=6g
#PBS -l walltime=24:00:00
#PBS -q long
#PBS -j oe

# how many threads do we have?
threads=32
run_humann=false # NB - this takes a while to run

module load conda
# a bit of a stupid solution - but if it works it works
source /opt/exp_soft/conda/anaconda3/etc/profile.d/conda.sh
conda init bash
conda activate stag-mwc

sample="$1" # that should contain the sample nums
home_path="$2"
taxon_db_path="$3"
human_ref_path="$4"
sample_path="$5"
resistome_path="$6"
f="/scratch/reinis01/reinis01_$sample"

# we need to move to the scratch dir to keep us from nuking their network infrastructure
cd "/scratch"
rm -rf "$f" # clear out the folder in case this sample has already been on this nod
mkdir -p "$f"
# # copy the database folders over - just use scratch instead of using the sample dir
# rm -rf "/scratch/reinis01/databases"
# cp -r "${taxon_db_path}" "/scratch/reinis01/databases"

if [ ! -d "/scratch/reinis01/databases" ]; then # NB: this will cause issues if we ever want to update the databases
    mkdir "/scratch/reinis01/databases"
    cp -r "${human_ref_path}" "/scratch/reinis01/databases"
    cp -r "${taxon_db_path}" "/scratch/reinis01/databases"
    cp -r "${resistome_path}" "/scratch/reinis01/databases"
    cp -r "${resistome_path}" "/scratch/reinis01/databases"

fi

cp -r "${home_path}/stag-mwc" "$f"
cp "${home_path}/rtu-stag/configs/config.hpc.yaml" "$f/stag-mwc/config.yaml" # changing the name to the default simplifies running
mkdir "$f/stag-mwc/input"
for fname in ${sample_path}${sample}_*.fq.gz; do # move both sample files
    trimmed=$(echo $fname | grep -o '[0-9]\+_[0-9]\+\.fq\.gz')
    trimmed2=$(echo $trimmed | grep -o "^[^_]*") # temporary fix until something better comes around
    cp $fname "$f/stag-mwc/input/$trimmed"
done

cp -r "${home_path}/kraken2" "/scratch/reinis01/kraken2"

cd "$f/stag-mwc"
snakemake --use-conda --cores $threads
cd ../.. # move back into the base dir
if [ "$run_humann" = true ] ; then
    # run the humann2 stuff outside of stag - just ripping the whole thing to deal with dep conflicts between humann2 and snakemake
    humann2_dir="$f/stag-mwc/output_dir/humann2/"
    metaphlan_dir="$f/stag-mwc/output_dir/metaphlan/"
    mkdir -p "$humann2_dir"
    mkdir -p "$metaphlan_dir"
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
    # ripping out humann2 to make the tests faster
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
    rm -rf "$f/stag-mwc/output_dir/humann2/*_humann2_temp/" # the 1 isn't supposed to be static - it corresponds with the sample num
fi
rm -rf "$f/stag-mwc/output_dir/fastp/"
rm -rf "$f/stag-mwc/output_dir/host_removal/"
#rm -rf "$f/stag-mwc/output_dir/logs/" # <- logs weigh borderline nothing - may as well leave them in
rm "$f/stag-mwc/output_dir/kraken2/$trimmed2.kraken" # wildcard does not work here for some reason, so a temp fix is used

# save the output folder and free up the space taken
datestamp=$(date -d "today" +"%Y%m%d%H%M")
mv "$f/stag-mwc/output_dir" "$sample_path/../outputs/${sample}_${datestamp}"
rm -rf "$f" # clean up after myself
for file in ${sample_path}${sample}_*.fq.gz; do # move both raw analysed sample files to another directory to ease file handling
    mv $file "$sample_path/../analysed_samples/"
done

# rm -rf "/scratch/reinis01/databases" # uncommenting for now to speed up analysis
