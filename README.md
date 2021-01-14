# Portable Nanopore Analytics: Are We There Yet?
We have uploaded in this repository all the scripts and executables nedded to reproduce our results.

## Directory structure
  - Scripts: bash scripts used to perform all mobile tests
  - Binaries: aarch64 binaries of compiled software
  - Data: excel file containing all the data


## Usage
Once installed fastq-dump and adb, you can reproduce the tests on an Android (aarch64) device following these instructions:  

1. Clone this repository and edit `Scripts/vars.sh` inserting your working paths.
2. Download test files from *ncbi* using `Scripts/sra_download.sh`
3. Now you can run the test scripts

```bash
./dsk.sh
./bcalm.sh
./diamond.sh
./kraken.sh
./minimap.sh
./bowtie.sh
./lambda.sh
```

## Citing 

Marco Oliva, Franco Milicchio, Kaden King, Grace Benson, Christina Boucher and Mattia Prosperi: "Portable Nanopore Analytics: Are We There Yet?", Bioinformatics, DOI: https://doi.org/10.1093/bioinformatics/btaa237
