#!/bin/bash

# This currently depends on hand-currated files sample_list*.csv.
# TODO: automate?


# This invokes screen if not already inside a screen which invokes /bin/bash, which invokes the script again.
if [ -z "$STY" ]; then exec screen -dm -S lftp-file-transfer /bin/bash "$0"; fi

# Set variables.
SOURCEDIR="/mnt/home/groups/lu_kpmi/raw_mgi_data"
OUTPUTDIR="/mnt/home/groups/lu_kpmi/renamed_samples"
ANALYSEDDIR="/mnt/home/groups/lu_kpmi/analysed_samples"
REGEX="/mnt/home/groups/lu_kpmi/sample_list_data/sample_list*.csv"

skiplist=$((ls $OUTPUTDIR; ls $ANALYSEDDIR) | sed 's:_[1-2]\.fq\.gz$::' | sort | uniq)

for i in $(awk -F "," 'NF {OFS=","; print $10, $11}' $REGEX); do # Read csv file.
  oldname=$(echo ${i} | awk -F "," '{print $1 }') # get old name from csv.
  newname=$(echo ${i} | awk -F "," '{print $2 }') # get new name from csv.

  echo "Processing ${oldname} -> ${newname}"

  skip=false
  for f in $skiplist; do
    if [[ $f == ${newname} ]]; then
      skip=true
    fi
  done
  if $skip; then
    echo "${newname} is already present, skip."
    continue;
  fi

  if [[ "${i}" == *\-* ]]; # check if sample spans multiple barcodes (has a dash in old name).
  then
    # Get barcode range
    from=$(echo ${i} | awk -F "_" '{sub(/-.*$/, "", $3); print $3 }')
    to=$(echo ${i} | awk -F "," '{sub(/.*-/, "", $1); print $1 }')

    searchname=${oldname%_$from-*}

    # Concatenate all files in the form ${searchname}_${barcode}_${direction}.fq.gz where ${barcode} is in the indicated range.
    for direction in $(seq 1 2); do
      for barcode in $(seq $from $to); do
        arr+=(-name "*${searchname}_${barcode}_${direction}.fq.gz" -o)
      done
      find ${SOURCEDIR} -type f \( "${arr[@]}" -name "*.dummy" \) | sort | xargs cat > "${OUTPUTDIR}/${newname}_${direction}.fq.gz"
      echo "${OUTPUTDIR}/${newname}_${direction}.fq.gz" # rename file combining seq and csv variables.
      unset arr
    done

  else # rename the files that dont span multiple barcodes by simply copying.
    # rename R1, no merging
    find $SOURCEDIR -type f -name "${oldname}_1.fq.gz" | xargs cat > "$OUTPUTDIR/${newname}_1.fq.gz"
    echo "$OUTPUTDIR/${newname}_1.fq.gz"
    # rename R2, no merging
    find $SOURCEDIR -type f -name "${oldname}_2.fq.gz" | xargs cat > "$OUTPUTDIR/${newname}_2.fq.gz"
    echo "$OUTPUTDIR/${newname}_2.fq.gz"
  fi
done

