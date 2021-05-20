#!/bin/sh
# This invokes screen if not already inside a screen which invokes /bin/bash, which invokes the script again.
if [ -z "$STY" ]; then exec screen -dm -S lftp-file-transfer /bin/bash "$0"; fi

# Set the variables for ftp connection.
PROTOCOL="ftp"
URL="10.245.1.138"
LOCALDIR="/mnt/home/groups/lu_kpmi/raw_mgi_data"
REMOTEDIR="/home"
USER=`awk  -F, '{print $1}' /mnt/home/groups/lu_kpmi/archive/mgi_lftp_user-pass_cred/cred.txt`
PASS=`awk  -F, '{print $2}' /mnt/home/groups/lu_kpmi/archive/mgi_lftp_user-pass_cred/cred.txt`
#REGEX="*.txt"
#LOG="${HOME}/tests/script.log"

#cd $LOCALDIR
#if [  ! $? -eq 0 ]; then
#	echo "$(date "+%d/%m/%Y-%T") Cant cd to $LOCALDIR. Please make sure this local directory is valid" >> $LOG
#fi
lftp $PROTOCOL://$URL  <<- DOWNLOAD
        set ftp:use-site-utime2 false
        set ssl:verify-certificate no
        set ftp:ssl-auth TLS
        user $USER "$PASS"
        cd $REMOTEDIR
        ls
        mirror -c --use-pget-n=10 --parallel=2 --only-missing --max-errors=1 /home $LOCALDIR
DOWNLOAD
chmod g+w -R $LOCALDIR

#mget -E $REGEX
#if [ ! $? -eq 0 ]; then
#	echo "$(date "+%d/%m/%Y-%T") Cant download files. Make sure the credentials and server information are correc$
#fi

# Manual termination of the screen -> $ screen -XS [session # you want to quit] quit
# For some reason after, quitting the screen, the lftp dl process turns into a zombie and keeps running so in order to terminate, 
# find PID via htop and use $ kill SIGNAL PID
