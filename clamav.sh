#!/bin/bash
##
## Bash Script to scan repository
## From http://code.google.com/p/clamav-cron/
##
## @ Author : Fabien VINCENT (fabien@beufa.net)
## @ Last Update : 2017-07-24
##
## USAGE
#     sh clamav.sh [/var]
# 	if no option specified, scan everything except /proc /sys and /dev
#
## Required :
#     apt-get install clamav
#
## Options
#     HOSTNAME        = server hostname
#     MAILTO          = to address separate by space

HOSTNAME="clamav"
MAILTO="who@test.net"

## Global variables in case of custom clamav installation
CLAM_ROOT="/etc/clamav"
CLAMAV_USER="clamav"
CLAM_LOG_DIR="/var/log/clamav"
CLAM_DB_DIR="/var/lib/clamav"
CLAM_RUN_DIR="/var/run/clamav"
CLAM_TMP_DIR="/tmp"
CLAMC_LOGFILE="/opt/scripts/cronclam/clamav.log"
# Date d'exécution
CLAMC_DATE=`date "+%Y-%m-%d"`
# Paramètres d'envoi de mail
CLAMC_MAILFROM="clamav@server.test"
CLAMC_MAILTO=$MAILTO
CLAMC_MAILTO_CC=$MAILCC
CLAMC_SUBJECT="["$HOSTNAME"] Antivirus Scan Report ("$CLAMC_DATE")"

# Command line default
CLAMC_SCAN_DEFAULT=" -ri / --exclude --exclude=/proc --exclude=/sys --exclude=/dev"

# Clean Log file before start
if [ -e $CLAMC_LOGFILE ]
then
        rm -f $CLAMC_LOGFILE
fi
touch $CLAMC_LOGFILE
chown $CLAMAV_USER $CLAMC_LOGFILE
chmod 660 $CLAMC_LOGFILE

# If no option, else target
if [ -z "$1" ]
then CLAMC_TARGET=$CLAMC_SCAN_DEFAULT
else CLAMC_TARGET=" -ri "$1" --exclude --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/usr/share/doc/clamav*/test"
fi

# Write logfile
echo -e $CLAMC_SUBJECT - $(date) '\n' > $CLAMC_LOGFILE
echo -e Scanned: $CLAMC_TARGET on $HOSTNAME'\n' > $CLAMC_LOGFILE
# Update database
/usr/bin/freshclam --quiet --log=$CLAMC_LOGFILE --user $CLAMAV_USER
# Start output
echo -e '------------------------------------\n'
/usr/bin/clamscan --log=$CLAMC_LOGFILE $CLAMC_TARGET
CLAMSCAN=$?

echo -e "ClamScan done !"

# Update subject if error or virus found
if [ "$CLAMSCAN" -eq "1" ]
then
        CLAMC_SUBJECT="[!VIRUS!] "$CLAMC_SUBJECT
elif [ "$CLAMSCAN" -gt "1" ]
then
        CLAMC_SUBJECT="[!ERROR!] "$CLAMC_SUBJECT
fi

# sendmail ;)
/bin/mail -a "From: $CLAMC_MAILFROM" -s "$CLAMC_SUBJECT" $CLAMC_MAILTO < $CLAMC_LOGFILE
