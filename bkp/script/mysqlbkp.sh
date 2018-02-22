#!/bin/bash
### MySQL Server Login Info ###
MUSER="root"
MPASS="myPass09"
MHOST="192.168.5.28"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
BAK="/backup/mysql"
GZIP="$(which gzip)"
NOW=$(date +"%d-%m-%Y")
 
DBS="$($MYSQL -u $MUSER -h $MHOST -p$MPASS -Bse 'show databases')"
for db in $DBS
do
 FILE=$BAK/$db.$NOW-$(date +"%T").gz
 echo $BAK/$db.$NOW-$(date +"%T").gz
# $MYSQLDUMP -u $MUSER -h $MHOST -p$MPASS $db | $GZIP -9 > $FILE
done
