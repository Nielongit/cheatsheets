#!/bin/bash
cat /etc/hosts
ls -la /tmp
LS=( 'bchimulcar' 'hydgw' 'malphonso' 'vdesai' 'agauncar' 'bkatkar' 'pdesai' 'vibhav' 'akholkar' 'dkurtarkar' 'jcardozo' 'pgaonkar' 'vibhavs' 'akurtarkar' 'dpereira' 'mshirsat' 'pkamat' 'apednekar' 'karolkar' 'pkarmali' 'app' 'freddy' 'kinjal' 'vsardessai' 'ganaokar' 'prnaik' 'cchari' 'psalgaonkar' 'ydalvi' 'ggaonkar'  'pshetkar' 'asawardeker'  'chintan' 'qatest' 'atilvi' 'cnaik' 'goaftp' 'cndesai' 'harish' 'cndesi' 'hshaik' 'lsoaadm' 'oracle' 'lcudnekar' )
for i in "${LS[@]}"
do
   
   echo "dir $i"
done
