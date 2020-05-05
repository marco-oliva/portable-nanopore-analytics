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

pc_working_dir="${working_dir}/kraken"

############################################################
## Check necessary commands
echo "[Setup] checking necessary commands"
declare -a commands=('adb')

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
## Get mobile kraken and monitor.sh
echo "[Setup] Get and push kraken arm"
adb push ${tools_dir}/kraken/classify.ae /data/local/tmp/classify_e

echo "[Setup] Get and push monitor arm"
adb push ${tools_dir}/monitor.sh /data/local/tmp/monitor.sh

## Check kraken and monitor.sh
pred='adb shell "[ -e "/data/local/tmp/classify_e" ] && echo "$?""'
check_predicate "$pred" "classify_e arm install ok" "classify_e arm error while installing"

pred='adb shell "[ -e "/data/local/tmp/monitor.sh" ] && echo "$?""'
check_predicate "$pred" "monitor.sh arm install ok" "monitor.sh not found"

echo "[Setup] chmod +x monitor.sh classify_e"
adb shell "chmod +x /data/local/tmp/classify_e /data/local/tmp/monitor.sh"

echo "[Setup] Checking Kraken Database"
pred='adb shell "[ -d '"$sp_base_folder/kraken"' ] && echo "$?""'
check_predicate "$pred" "Kraken Database ok" "Kraken Database not in expected folers"
k_db="${sp_base_folder}/kraken"

############################################################
## For each file: download, run tests, store outcomes
for i in "${metagenomic_idxs[@]}"
do
	echo "[${i}] Creating ${i}_results dir"
	mkdir -p $pc_working_dir/${i}_results

	#download fastq
	echo "[${i}] Pushing fastq"
	adb push $sra_dir/${i}.fastq $sp_working_dir

	echo "[${i}] Kraken Mapping: mapping to 400MB bacteria database"
	set -x # printing the command
	adb shell "{ time ( cd $sp_working_dir && /data/local/tmp/classify_e -H ${k_db}/hash.k2d -t ${k_db}/taxo.k2d -o ${k_db}/opts.k2d -p 8 -Q 0 -T 0 $sp_working_dir/${i}.fastq > /dev/null 2> $sp_working_dir/${i}_mapping.log ); } 2> $sp_working_dir/${i}_mapping_time.log & /data/local/tmp/monitor.sh classify_e > $sp_working_dir/${i}_mapping_ram.log"
	set +x

	adb pull $sp_working_dir/${i}_mapping.log $pc_working_dir/${i}_results/${i}_mapping.log
	adb pull $sp_working_dir/${i}_mapping_time.log $pc_working_dir/${i}_results/${i}_mapping_time.log
	adb pull $sp_working_dir/${i}_mapping_ram.log $pc_working_dir/${i}_results/${i}_mapping_ram.log

	#remove
	echo "[${i}] Removing all files"
	adb shell "rm -rf $sp_working_dir/*"
	rm -f $pc_working_dir/${i}.fastq

	#let the device cool down
	echo "[${i}] Sleeping: ${inter_batch_sleep_time}"
	sleep ${inter_batch_sleep_time}				

done

print_header "ALL TESTS DONE"
