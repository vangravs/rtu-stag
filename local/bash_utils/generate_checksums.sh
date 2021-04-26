cd ../../samples

rm checksums.txt
touch checksums.txt

for f in *.fq.gz
do
    gunzip -k $f

    for i in *.fq
    do
        shasum -a512 "$i.gz" >> checksums.txt
    done

    rm *.fq
done