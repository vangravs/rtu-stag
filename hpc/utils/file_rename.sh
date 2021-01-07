#!/bin/bash

# future develop.
# simplify the script!
# run with the option to specify a csv input file.
# show error message instructing the user on correct usage and create an examplary CSV file.
# rsync/cat the files on rtu hpc from raw_mgi_data to renamed_samples folder.
# implement checksum comparing.
# paralellize the copying on compute nodes.
# compare the csv newname with the contents of analysed_samples and renamed_samples and proceed only if not present in either.

# Install dependencies (currently only pv)
#pkgs='pv'
#if ! dpkg -s $pkgs >/dev/null 2>&1; then
#  # sudo apt install $pkgs
#  exit "pipe-viewer not installed, please run 'sudo apt install pv' to continue"
#fi

# Set variables.
SOURCEDIR="/mnt/home/groups/lu_kpmi/raw_mgi_data"
OUTPUTDIR="/mnt/home/groups/lu_kpmi/renamed_samples"
REGEX="/mnt/home/groups/lu_kpmi/sample_list_data/sample_list*.csv"

cd $SOURCEDIR
for i in $(awk -F "," '{OFS=","; print $10, $11}' $REGEX); do # Read csv file.
  if [[ "${i}" == *\-* ]]; # check if sample spans multiple barcodes (has a dash in old name). If has a dash perform "seq -s" with comma delim.
  then
    a=$(echo ${i} | awk -F "_" '{sub(/-.*$/, "", $3); print $3 }') # get barcode range start.
    b=$(echo ${i} | awk -F "," '{sub(/.*-/, "", $1); print $1 }') # get barcode range stop.
    barcodes=$(seq -s , $a $b) 
    oldname=$(echo ${i} | awk -F "," '{print $1 }') # get old name from csv.
    newname=$(echo ${i} | awk -F "," '{print $2 }') # get new name from csv.
    searchname=${oldname%_$a-*}

    # merge and rename R1
    for b in $(echo $barcodes | sed "s/,/ /g")
    do
      arr_r1+=(-name "*${searchname}_${b}_1.fq.gz" -o)
    done
    find . -type f \( "${arr_r1[@]}" -name "*.dummy" \) | sort | xargs cat > "$OUTPUTDIR/${newname}_1.fq.gz" | echo "$OUTPUTDIR/${newname}_1.fq.gz" # rename R1 file combining seq and csv variables.
    unset arr_r1
    # merge and rename R2
    for b in $(echo $barcodes | sed "s/,/ /g")
    do
      arr_r2+=(-name "*${searchname}_${b}_2.fq.gz" -o)
    done
    find . -type f \( "${arr_r2[@]}" -name "*.dummy" \) | sort | xargs cat > "$OUTPUTDIR/${newname}_2.fq.gz" | echo "$OUTPUTDIR/${newname}_2.fq.gz" # rename R2 file combining seq and csv variables.
    unset arr_r2
  
  else # rename the files that dont span multiple barcodes by simply copying.
    oldname2=$(echo ${i} | awk -F "," '{print $1 }') # get old name from csv.
    newname2=$(echo ${i} | awk -F "," '{print $2 }') # get new name from csv. 
    # rename R1, no merging
    find . -type f -name "${oldname2}_1.fq.gz" | xargs cat > "$OUTPUTDIR/${newname2}_1.fq.gz" | echo "$OUTPUTDIR/${newname2}_1.fq.gz"
    # rename R2, no merging
    find . -type f -name "${oldname2}_2.fq.gz" | xargs cat > "$OUTPUTDIR/${newname2}_2.fq.gz" | echo "$OUTPUTDIR/${newname2}_2.fq.gz"
  fi
done

cd $OUTPUTDIR
find -name "*.fq.gz" -size 0 -delete # a workaround to get rid of empty files. Should avoid making empty files in the first place.