#!/bin/bash
#REPOLOC=/var/www/html/repo
REMSRV="root@192.168.5.248"
REMLOC=/var/www/html/neustar/oms/
FILE=$1
if [ -f $FILE ]; then
#    cp $FILE $REPOLOC
#    createrepo --update -s md5 $REPOLOC
     scp $FILE $REMSRV:$REMLOC
     ssh $REMSRV 'createrepo --update -s md5 /var/www/html/neustar/oms/'
else
    echo "File not found!"
fi
