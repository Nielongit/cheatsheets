#/bin/bash
HOSTN=$(hostname)
##EMAIL##
EMAIL=$(which mail)
ESMTP=192.168.5.102
EFROM=redmine@netechgoa.co.in
ET=lcudnekar@netechgoa.co.in

##MOUNT##
MOUNT=$(which mount)
UMOUNT=$(which umount)

function sndEmail() {
   EDATE=$(date +%d-%m-%Y-%H:%M:%S)
   $EMAIL -S smtp=$ESMTP -S from=$EFROM  -s "$1 $EDATE"  $ETO <<< "$2 - $EDATE"
   if ! [ "$?" = "0" ]; then
	echo "Error while sending email. Return value:$?"
   fi 
}

function mntRemDir() {
   $MOUNT $1 $2
   if ! [ "$?" = "0" ]; then
        echo "#######################################################################"
	echo "Error while mounting $1 on $HOSTN . Return value:$?"
	echo "#######################################################################"
	sndEMAIL "Error while mounting $1 on $HOSTN" "Error while mounting $1 on $HOSTN . Return value:$?"
	exit 1
   fi
   echo "#######################################################################"
        echo "Mount successfull on $HOSTN . Return value:$?"
   echo "#######################################################################"
}

function umntRemDir() {
   $UMOUNT -f $1 
   if ! [ "$?" = "0" ]; then
	echo "#######################################################################"
        echo "Error while unmounting $1 on $HOSTN . Return value:$?"
        echo "#######################################################################"
        sndEMAIL "Error while unmounting $1 on $HOSTN" "Error while unmounting $1 on $HOSTN . Return value:$?"
   else
   	echo "#######################################################################"
           echo "UNMount successfull on $HOSTN . Return value:$?"
   	echo "#######################################################################"
   fi
}
