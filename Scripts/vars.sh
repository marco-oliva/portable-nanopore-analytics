#!/bin/bash
############################################################
## Author: Marco Oliva marco.oliva@ufl.edu
############################################################

## Declare these
working_dir=""
tools_dir=""
sra_dir=""

## This should point to the S9's sdcard, if nothing has
##  changed on the smartphne this path should be correct
sp_base_folder="/storage/6434-6530"

############################################################
## Functions

### fail
# $1: message
function fail {
	echo "[Setup] Fail: $1"
	exit
}

### success
# $1: message
function success {
	echo "[Setup] Success: $1"
}

### check_predicate
# $1: predicate $2: success message $3:fail message  #pred example: [ -e '"$sp_base_folder"' ] && echo $?
function check_predicate {
	out=$(sh -c "$1")

	if [ -n "$out" ]; then
		success "$2"
	else
		fail "$3"
	fi
}

function check_command_available {
	pred='[ 1 -eq $(command -v '"$1"' | wc -l) ] && echo $?'
	check_predicate "$pred" "$1 found" "$1 not found, install it"
}

function print_header {
	printf '\n'
	size=${#1}
	printf '## %s ' ${1}
	i=1
	while [ "$i" -le "$((60 - 4 - ${size}))" ]; do
		printf '#'	  
		i=$(($i + 1))
	done
	printf '\n'
}


############################################################
## Vars

## File with reference genomes
declare -a ref_idxs=(
	'DRR164915'
	'ERR2571299'
	'ERR2564376'
	'SRR7765365'
	'SRR7762336'
	'ERR2612749'
)

## Reference genomes for each sra_idx (associative array)
declare -A genome_links
genome_links['DRR164915']='ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/482/505/GCF_000482505.1_ASM48250v1/GCF_000482505.1_ASM48250v1_genomic.fna.gz'
genome_links['ERR2571299']='ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/900/464/855/GCA_900464855.1_ASM90046485v1/GCA_900464855.1_ASM90046485v1_genomic.fna.gz'
genome_links['ERR2564376']='ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/695/525/GCF_000695525.1_BOL/GCF_000695525.1_BOL_genomic.fna.gz'
genome_links['SRR7765365']='ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/313/135/GCF_000313135.1_Acastellanii.strNEFF_v1/GCF_000313135.1_Acastellanii.strNEFF_v1_genomic.fna.gz'
genome_links['SRR7762336']='ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/150/955/GCF_000150955.2_ASM15095v2/GCF_000150955.2_ASM15095v2_genomic.fna.gz'
genome_links['ERR2612749']='ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/002/495/GCF_000002495.2_MG8/GCF_000002495.2_MG8_genomic.fna.gz'


## Metagenomic files
declare -a metagenomic_idxs=(
	'ERR2900440'
	'ERR2900442'
	'ERR2900428'
	'ERR2625614'
	'SRR6037114'
	'SRR6037129'
	'ERR2662964'
	'SRR5889392'
)

## All files
declare -a all_idxs=(
	'ERR2900440'
	'ERR2900442'
	'ERR2900428'
	'SRX5210081'
	'DRR164915'
	'ERR2625614'
	'SRR6037114'
	'SRR6037129'
	'ERR2571299'
	'ERR2564376'
	'SRR7765365'
	'ERR2662964'
	'SRR5889392'
	'SRR7762336'
	'ERR2612749'
) 

## Sleep time
inter_batch_sleep_time=120 #2 min
