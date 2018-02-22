#!/bin/bash
HOMEDIR=/export/home
REMDIR=192.168.5.249:/srv/backup/homesrv/home
LOCDIR=/mnt/backup
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
#        sndEmail "Error while mounting $1 on $HOSTN" "Error while mounting $1 on $HOSTN . Return value:$?"
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
#        sndEmail "Error while unmounting $1 on $HOSTN" "Error while unmounting $1 on $HOSTN . Return value:$?"
   else
        echo "#######################################################################"
           echo "UNMount successfull on $HOSTN . Return value:$?"
        echo "#######################################################################"
   fi
}


LS=( 'bchimulcar' 'hydgw' 'malphonso' 'vdesai' 'agauncar' 'bkatkar' 'pdesai' 'vibhav' 'akholkar' 'dkurtarkar' 'jcardozo' 'pgaonkar' 'vibhavs' 'akurtarkar' 'dpereira' 'mshirsat' 'pkamat' 'apednekar' 'karolkar' 'pkarmali' 'app' 'freddy' 'kinjal' 'vsardessai' 'ganaokar' 'prnaik' 'cchari' 'psalgaonkar' 'ydalvi' 'ggaonkar'  'pshetkar' 'asawardeker'  'chintan' 'qatest' 'atilvi' 'cnaik' 'goaftp' 'cndesai' 'harish' 'cndesi' 'hshaik' 'lsoaadm' 'oracle' 'lcudnekar' )

echo "#######################################################################"
echo "   Started Home directory backup on $HOSTN"
echo "#######################################################################"

mntRemDir $REMDIR $LOCDIR

echo hello1

for USER in  "${LS[@]}"
do
   echo "#####################$USER#############################################"
   DATE1=$(date +%d%m%Y)
   DATE2=$(date  +%H%M%S)
   if [ -d $HOMEDIR/$USER ] ; then
   	echo "$LOCDIR/hbkp.$USER.$DATE1.$DATE2.tar.Z"	
	tar cvjf $LOCDIR/hbkp.$USER.$DATE1.$DATE2.tar.Z  $HOMEDIR/$USER
   else
	echo "dir not found $USER"
 #       sndEMAIL "HOMESRV Backup - Dir $USER not found" "HOMESRV Backup - Dir $USER not found
   fi
done

echo "#######################################################################"
echo "Home Directory backup Finished" 
echo "#######################################################################"

umntRemDir $REMDIR

