#!/bin/bash

### RDS storage
df -h --direct /home/groups/CEDAR > disc.txt

### Gscratch storage
gsize=`lfs quota -h -p 3901  /home/exacloud/gscratch/CEDAR |  tail -1 | awk '{print $3}' | sed "s|T| |g"`
gused=`lfs quota -h -p 3901  /home/exacloud/gscratch/CEDAR |  tail -1 | awk '{print $1}' | sed "s|T| |g"`
gavai=`echo $gsize $gused | awk '{print $1-$2}'`
gpuse=`echo $gused $gsize | awk '{printf"%d",$1/$2*100}'`
echo $gsize $gused $gavai $gpuse | awk '{printf"\t\t%d%s%d%s%d%s%d%s%s\n",$1,"T  ",$2,"T   ",$3,"T  ",$4,"% ","/home/exacloud/gscratch/CEDAR"}' >> disc.txt
echo >> disc.txt

### Add Usage Tracking to same file 
echo "Daily" >> disc.txt
/usr/local/bin/sreport-accts-summary Accounts=CEDAR,CEDAR2 Start=$(date +"%Y-%m-%d") >> disc.txt
echo >> disc.txt
echo "MTD" >> disc.txt
/usr/local/bin/sreport-accts-summary Accounts=CEDAR,CEDAR2 Start=$(date -d "-1 month" +"%Y-%m-%d") >> disc.txt
echo >> disc.txt
echo "FYTD" >> disc.txt
if [ "$(date +%m)" -lt 7 ]; then
    start_fy=$(date -d "$(date +%Y)-07-01 -1 year" +"%Y-%m-%d")
else 
    start_fy=$(date -d "$(date +%Y)-07-01" +"%Y-%m-%d")

fi 

/usr/local/bin/sreport-accts-summary Accounts=CEDAR,CEDAR2 Start=$start_fy >> disc.txt


#echo "FYTD" >> $curr/disc.txt
#/usr/local/bin/sreport-accts-summary Accounts=CEDAR,CEDAR2 Start=$(date -d "-1 year" +"%Y-%m-%d") >> $curr/disc.txt
 


### Daily update

for recips in `cat recips.txt`
do
    mail -s "Exacloud diskspace" $recips < disc.txt
done

### Update local copy    
date >> RDS.txt
df -h --direct /home/groups/CEDAR >> RDS.txt
date >> Gscratch.txt
df -h --direct /home/groups/CEDAR | head -1 >> Gscratch.txt
echo $gsize $gused $gavai $gpuse | awk '{printf"\t\t%d%s%d%s%d%s%d%s%s\n",$1,"T  ",$2,"T   ",$3,"T  ",$4,"% ","/home/exacloud/gscratch/CEDAR"}' >> Gscratch.txt



