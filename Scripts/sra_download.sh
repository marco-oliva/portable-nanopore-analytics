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

############################################################
## Check necessary commands
echo "[Setup] checking necessary commands"
declare -a commands=('fastq-dump')

for c in "${commands[@]}"
do
	check_command_available ${c}
done

# Make needed directories
pred='[ ! -d '"$sra_dir"' ] && echo $?'
check_predicate "$pred" "creating $sra_dir" "$sra_dir exists, change directory"

mkdir -p $sra_dir 2> /dev/null
pred='[ -d '"$sra_dir"' ] && echo $?'
check_predicate "$pred" "SRA dir: $sra_dir" "$sra_dir permisison denied"


print_header "Download"

############################################################
## For each file: download, run tests, store outcomes
for i in "${all_idxs[@]}"
do
	#download fastq
	echo "[${i}] Download fastq"
	fastq-dump ${i} -O ${sra_dir}
done
