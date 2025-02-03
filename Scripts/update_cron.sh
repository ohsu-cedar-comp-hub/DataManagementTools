#!/bin/bash


### RDS storage
df -h --direct /home/groups/CEDAR > disc.txt

### Gscratch storage
df -h --direct /home/exacloud/gscratch/CEDAR >> disc.txt
echo >> disc.txt


## Add Usage Tracking + Budget Info to same file 
CPUBudgetMonthly=660000
GPUBudgetMonthly=6000



# FYTD - x months before 
echo "FYTD - ARC + Exacloud" >> disc.txt

if [ "$(date +%m)" -lt 7 ]; then
    start_fy=$(date -d "$(date +%Y)-07-01 -1 year" +"%Y-%m-%d")
else 
    start_fy=$(date -d "$(date +%Y)-07-01" +"%Y-%m-%d")

fi 


/usr/local/bin/sreport-accts-summary Accounts=CEDAR,CEDAR2 Start=$start_fy > test.txt

# Budget needs to be calcd depending on # of months 
# 2628288 seconds in a month
months=$(echo "scale=2; ($(date -d "$(date +"%Y-%m-%d")" +%s) - $(date -d "$start_fy" +%s)) / 2628288" | bc)

CPUBudgetFYTD=$(echo "$CPUBudgetMonthly * $months" | bc)
GPUBudgetFYTD=$(echo "$GPUBudgetMonthly * $months" | bc)

echo "${months} months - Budget - CPU: ${CPUBudgetFYTD} hrs ; GPU: ${GPUBudgetFYTD} hrs" >> disc.txt

echo "" >> disc.txt
awk -v CPUproratedBudget=$CPUBudgetFYTD -v GPUproratedBudget=$GPUBudgetFYTD '

NR < 5 {
    print $0;
    next;  # Skip to the next line without further processing
}

NR == 6 {# print headers
print "Account|CPUused|GPUused|%CPUProratedBudget|%GPUProratedBudget";
} 

NR >= 6 {
    split($0, fields, "|");
    CPUused = fields[2];
    GPUused = fields[3];
    if (fields[1] == "cedar"){
        CPUused += 651241; # adding exacloud data 
        GPUused += 21662; }
    else if (fields[1] == "cedar2") {
        CPUused += 1301103;
        GPUused += 0;
    }
    total_CPUused += CPUused;
    total_GPUused += GPUused;

    print fields[1] "|" CPUused "|" GPUused "|" "|"


}

END {
    CPUProratedPercent = (total_CPUused / CPUproratedBudget) * 100;
    GPUProratedPercent = (total_GPUused / GPUproratedBudget) * 100;
    print "TOTAL|" total_CPUused "|"  total_GPUused "|" CPUProratedPercent "%" "|" GPUProratedPercent "%";
}
' test.txt >> disc.txt


echo "" >> disc.txt
# MTD - just 1 month ago 
echo "MTD - ARC " >> disc.txt
echo "1 month -  Budget - CPU: 660000 hrs ; GPU: 6000 hrs" >> disc.txt
echo "" >> disc.txt
total_CPUused=0
total_GPUused=0

Start=$(date -d "-1 month" +"%Y-%m-%d")

/usr/local/bin/sreport-accts-summary Accounts=CEDAR,CEDAR2 Start=$Start > test.txt 

# Budget : 110 CPU units (660000 hrs) / month + 10 GPU units (6000 hrs) / month 
awk -v CPUproratedBudget=$CPUBudgetMonthly -v GPUproratedBudget=$GPUBudgetMonthly '

NR < 5 {
    print $0;
    next;  
}

NR == 6 {
print "Account|CPUused|GPUused|%CPUProratedBudget|%GPUProratedBudget";
} 

NR >= 6 {
    split($0, fields, "|");
    CPUused = fields[2];
    GPUused = fields[3];
    
    total_CPUused += CPUused;
    total_GPUused += GPUused;

    print $0 "|" "|"

}

END {
    CPUProratedPercent = (total_CPUused / CPUproratedBudget) * 100;
    GPUProratedPercent = (total_GPUused / GPUproratedBudget) * 100;
    print "TOTAL|" total_CPUused "|"  total_GPUused "|" CPUProratedPercent "%" "|" GPUProratedPercent "%";
}
' test.txt >> disc.txt

echo >> disc.txt

rm test.txt

### Daily update

for recips in `cat recips.txt`
do
 mail -s "Exacloud diskspace" $recips < disc.txt
done

### Update local copy    
date >> RDS.txt
df -h --direct /home/groups/CEDAR >> RDS.txt
date >> Gscratch.txt
df -h --direct /home/exacloud/gscratch/CEDAR >> Gscratch.txt
