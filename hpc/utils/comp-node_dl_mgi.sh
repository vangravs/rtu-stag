#!/bin/bash
#PBS -N dl_mgi
#PBS -l nodes=1:ppn=1,pmem=6g
#PBS -l walltime=96:00:00
#PBS -q long
#PBS -j oe

# This will only work if RTU HPC enable connection to GDN 
#"Savienojums ar Genomikas datu tīklu, tostarp MGI, šobrīd ir iespējams tikai no login nodes ui-1.hpc.rtu.lv. 
#Compute nodes šobrīd nav savienotas ar šo tīklu. Ja ir tāda vajadzība lejupielādēt datus uz compute nodi, tad izskatīsim iespēju tās savienot ar šo tīklu."

module load conda
# a bit of a stupid solution - but if it works it works
source /opt/exp_soft/conda/anaconda3/etc/profile.d/conda.sh
conda init bash
conda activate stag-mwc

PROTOCOL="ftp"
URL="10.245.1.138"
LOCALDIR="/mnt/home/groups/lu_kpmi/raw_mgi_data"
REMOTEDIR="/home"
USER="LU_metagenome"
PASS="wLBCMu>3"
#REGEX="*.txt"
#LOG="/mnt/home/reinis01/tests/script.log"

#cd $LOCALDIR
#if [  ! $? -eq 0 ]; then
#	echo "$(date "+%d/%m/%Y-%T") Cant cd to $LOCALDIR. Please make sure this local directory is valid" >> $LOG
#fi

lftp  $PROTOCOL://$URL  <<- DOWNLOAD
        set ftp:use-site-utime2 false
        set ssl:verify-certificate no
        set ftp:ssl-auth TLS
        user $USER "$PASS"
        cd $REMOTEDIR
        ls
        mirror -c --use-pget-n=10 --parallel=2 --only-missing --max-errors=1 /home $LOCALDIR
DOWNLOAD

#mget -E $REGEX
#if [ ! $? -eq 0 ]; then
#	echo "$(date "+%d/%m/%Y-%T") Cant download files. Make sure the credentials and server information are correc$
#fi
