#!/bin/bash
####
####Variables
####
LOGDATE=$(date +%F-%H%M%S);
EMAIL=/usr/bin/nail
ETO=lcudnekar@netechgoa.co.in
BKPLIB=/opt/script/bkplib.cfg
HOSTN=$(hostname)
####
####End Variables
####
#######Run Script

function sndEmail() {
#   echo "Email - $2"
   EDATE=$(echo -e "$(date +%d-%m-%Y-%H:%M:%S)\n ")
   MAILRC=/dev/null from=redmine@netechgoa.co.in smtp=192.168.5.102 $EMAIL -s "$1 $EDATE." $ETO <<< "Date:$EDATE$2"
   if ! [ "$?" = "0" ]; then
        echo "Error while sending email. Return value:$?" >> /opt/script/testt
   fi
}

chktarinteg() {
	echo "########"
        echo "Oracle Tar"
	TARDIR=$1
	#LS=$(ls -p $TARDIR  | grep -v /)
	LS=$(find $TARDIR -name *tar.Z)
	for USER in $LS
	do
		echo "####$USER####"
		tar tzf $USER > /dev/null
		if ! [ "$?" = "0" ]; then
        		echo "Tar.Gzip $USER is corrupt"
		else
			echo "Tar.Gzip $USER is ok"	
   		fi
	done
}

bkpdiskspace() {
	echo "########"
	echo "Partition"
	df -h | grep srv
	echo "########"
	echo "Oracle"
	du -sh /srv/backup/dbsvr/oracle/*
	echo "########"
	echo "Mysql"
	du -sh /srv/backup/dbsvr/mysql/mysqldump/*
	echo "########"
	echo "Saturn SVN"
	du -sh /srv/backup/saturn/svn/*
	echo "########"
	echo "Vobsrv SVN"
	du -sh /srv/backup/vobsrv/svn/*
	echo "########"
	echo "Redlotus Redmine"
	du -sh /srv/backup/redlotus/redmine/*
	echo "########"
}

retoutp=$(bkpdiskspace)
echo -e "$retoutp"
retoutp1=$(chktarinteg /srv/backup/dbsvr/oracle/)
echo -e "$retoutp1"
sndEmail "Disk Usage on backup server $HOSTN - $LOGDATE" "$retoutp $retoutp1"

