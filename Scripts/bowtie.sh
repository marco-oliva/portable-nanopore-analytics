#!/bin/bash
############################################################
## Author: Marco Oliva marco.oliva@ufl.edu
############################################################
## Run all tests
##    following tools must be in the
##    system path (Desktop)
##   - adb
############################################################

if [ -f ./vars.sh ]; then
    source ./vars.sh
else 
	echo "./vars.sh not found!"
    exit
fi

pc_working_dir="${working_dir}/bowtie"

############################################################
## Check necessary commands
echo "[Setup] checking necessary commands"
declare -a commands=('adb' 'gunzip' 'wget')

for c in "${commands[@]}"
do
	check_command_available ${c}
done

# Make needed directories
pred='[ ! -d '"$pc_working_dir"' ] && echo $?'
check_predicate "$pred" "creating $pc_working_dir" "$pc_working_dir exists, change directory"

mkdir -p $pc_working_dir 2> /dev/null
pred='[ -d '"$pc_working_dir"' ] && echo $?'
check_predicate "$pred" "PC Working dir: $pc_working_dir" "$pc_working_dir permisison denied"

############################################################
#################### MOBILE ################################
############################################################

print_header "MOBILE"

############################################################
## Check device and external storage
pred='adb get-state 2 >/dev/null && echo $?'
check_predicate "$pred" "adb device attached" "adb device not attached"

echo "[Setup] Checking eternal storage folder"
pred='adb shell "[ -d '"$sp_base_folder"' ] && echo "$?""'
check_predicate "$pred" "External storage folder ok" "External storage folder does not exist"

sp_working_dir="${sp_base_folder}/Tests"
adb shell "mkdir -p $sp_working_dir"
echo "[Setup] SP Working dir:    $sp_working_dir"

############################################################
## Get mobile bowtie and monitor.sh
echo "[Setup] Push bowtie2-build-l arm"
adb push ${tools_dir}/bowtie2/bowtie2-build-l /data/local/tmp/bowbl_e

echo "[Setup] Push bowtie2-build-s arm"
adb push ${tools_dir}/bowtie2/bowtie2-build-s /data/local/tmp/bowbs_e

echo "[Setup] Push bowtie2-allign-l arm"
adb push ${tools_dir}/bowtie2/bowtie2-align-l /data/local/tmp/bowal_e

echo "[Setup] Push bowtie2-allign-s arm"
adb push ${tools_dir}/bowtie2/bowtie2-align-s /data/local/tmp/bowas_e

echo "[Setup] Get and push monitor arm"
adb push ${tools_dir}/monitor.sh /data/local/tmp/monitor.sh

## Check bowtie and monitor.sh
pred='adb shell "[ -e "/data/local/tmp/bowbl_e" ] && echo "$?""'
check_predicate "$pred" "bowbl_e arm install ok" "bowbl_e arm error while installing"

pred='adb shell "[ -e "/data/local/tmp/bowbs_e" ] && echo "$?""'
check_predicate "$pred" "bowbs_e arm install ok" "bowbs_e arm error while installing"

pred='adb shell "[ -e "/data/local/tmp/bowal_e" ] && echo "$?""'
check_predicate "$pred" "bowal_e arm install ok" "bowal_e arm error while installing"

pred='adb shell "[ -e "/data/local/tmp/bowas_e" ] && echo "$?""'
check_predicate "$pred" "bowas_e arm install ok" "bowas_e arm error while installing"

pred='adb shell "[ -e "/data/local/tmp/monitor.sh" ] && echo "$?""'
check_predicate "$pred" "monitor.sh arm install ok" "monitor.sh not found"

echo "[Setup] chmod +x monitor.sh bowtie"
adb shell "chmod +x /data/local/tmp/bowbl_e /data/local/tmp/bowbs_e /data/local/tmp/bowal_e /data/local/tmp/bowas_e /data/local/tmp/monitor.sh"


############################################################
## For each file: download, run tests, store outcomes
for i in "${ref_idxs[@]}"
do
	echo "[${i}] Creating ${i}_results dir"
	mkdir -p $pc_working_dir/${i}_results

	#download fastq
	echo "[${i}] Pushing fastq"
	adb push $sra_dir/${i}.fastq $sp_working_dir

	#download reference genome
	echo "[${i}] Downloading reference genome"
	wget -q ${genome_links[${i}]} -O $pc_working_dir/${i}_ref.fa.gz
	gunzip $pc_working_dir/${i}_ref.fa.gz
	echo "[${i}] Pushing reference genome"
	adb push $pc_working_dir/${i}_ref.fa $sp_working_dir

	#run bowtie
	echo "[${i}] Bowtie2: creating index"
	adb shell "{ time ( cd $sp_working_dir && /data/local/tmp/bowbs_e --wrapper basic-0 --threads 8 ${i}_ref.fa ${i} > /dev/null  2>$sp_working_dir/${i}_idx.log ); } 2> $sp_working_dir/${i}_idx_time.log & /data/local/tmp/monitor.sh bowbs_e > $sp_working_dir/${i}_idx_ram.log"

	echo "[${i}] Bowtie2: mapping"
	adb shell "{ time ( cd $sp_working_dir && /data/local/tmp/bowas_e --wrapper basic-0 --threads 2 -x ${i} -q ${i}.fastq > /dev/null 2> $sp_working_dir/${i}_mapping.log ); } 2> $sp_working_dir/${i}_mapping_time.log & /data/local/tmp/monitor.sh lambda2_e > $sp_working_dir/${i}_mapping_ram.log"

	adb pull $sp_working_dir/${i}_idx.log $pc_working_dir/${i}_results/${i}_idx.log
	adb pull $sp_working_dir/${i}_idx_time.log $pc_working_dir/${i}_results/${i}_idx_time.log
	adb pull $sp_working_dir/${i}_idx_ram.log $pc_working_dir/${i}_results/${i}_idx_ram.log

	adb pull $sp_working_dir/${i}_mapping.log $pc_working_dir/${i}_results/${i}_mapping.log
	adb pull $sp_working_dir/${i}_mapping_time.log $pc_working_dir/${i}_results/${i}_mapping_time.log
	adb pull $sp_working_dir/${i}_mapping_ram.log $pc_working_dir/${i}_results/${i}_mapping_ram.log

	#remove
	echo "[${i}] Removing all files"
	adb shell "rm -r $sp_working_dir/*"
	rm -f $pc_working_dir/${i}_ref.fa

	#let the device cool down
	echo "[${i}] Sleeping: ${inter_batch_sleep_time}"
	sleep ${inter_batch_sleep_time}				

done

print_header "ALL TESTS DONE"

