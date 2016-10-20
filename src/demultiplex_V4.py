#!/usr/bin/env python

import subprocess
import sys
import os
import argparse

parser = argparse.ArgumentParser()
parser._optionals.title = "Options"
parser.add_argument('-m', nargs = 1, help = 'Mapping file. [Required]', required = True)
parser.add_argument('-r1', nargs = 1, help = 'The R1 file (named *_R1_*.fastq.gz). [Required]', required = True)
parser.add_argument('-r2', nargs = 1, help = 'The R2 file (named *_R2_*.fastq.gz). [Required]', required = True)
parser.add_argument('-i1', nargs = 1, help = 'The I1 file (named *_I1_*.fastq.gz). [Required]', required = True)
parser.add_argument('-i2', nargs = 1, help = 'The I2 file (named *_I2_*.fastq.gz). [Required]', required = True)
parser.add_argument('-p', nargs = 1, help = 'Path to the folder where the scripts are stored. [Required]', required = True)
parser.add_argument('-o', nargs = 1, help = 'A name that is given to the output files. [Required]', required = True)
parser.add_argument('--keep_temp', action ='store_true', help = 'If given, the files that are produced during the script will be kept.')
args = parser.parse_args()
arguments = vars(args)

r1 = ''.join(arguments['r1'])
r2 = ''.join(arguments['r2'])
i1 = ''.join(arguments['i1'])
i2 = ''.join(arguments['i2'])
output_name = ''.join(arguments['o'])
scripts_dir = ''.join(arguments['p'])

if arguments['keep_temp']:
	print("********************************************************\n\nAll files created in the script will be kept in the folder deplex_temporary_files.\n\n********************************************************")
	keep = True
else:
	keep = False

I1 = i1.split('/')[-1].strip('.gz')
I2 = i2.split('/')[-1].strip('.gz')

print("Demultiplexing started...")

cmd = "mkdir deplex_temporary_files_%s" % output_name
subprocess.call(cmd, shell = True)

## Unpack and move index files to current folder
cmd1 = "gunzip -c %s > deplex_temporary_files_%s/%s" % (i1, output_name, I1)
subprocess.call(cmd1, shell = True)
cmd2 = "gunzip -c %s > deplex_temporary_files_%s/%s" % (i2, output_name, I2)
subprocess.call(cmd2, shell = True)

cmd = "validate_mapping_file.py -m %s -o deplex_temporary_files_%s/check_map" % (''.join(arguments['m']), output_name)
subprocess.call(cmd, shell = True)

cmd = "%sfix_mappingfile.py deplex_temporary_files_%s/check_map/*_corrected.txt deplex_temporary_files_%s" % (scripts_dir, output_name, output_name)
subprocess.call(cmd, shell = True)

## Demultiplexing and get quality filtering.
cmd1 = "split_libraries_fastq.py -o deplex_temporary_files_%s/mapping_%s_1 -i %s -b deplex_temporary_files_%s/%s   --rev_comp_mapping_barcodes -m deplex_temporary_files_%s/*_corrected_1.txt  --store_demultiplexed_fastq" % (output_name, output_name, r1, output_name, I1, output_name)
cmd2 = "split_libraries_fastq.py -o deplex_temporary_files_%s/mapping_%s_2 -i %s -b deplex_temporary_files_%s/%s   --rev_comp_mapping_barcodes -m deplex_temporary_files_%s/*_corrected_1.txt  --store_demultiplexed_fastq" % (output_name, output_name, r2, output_name, I1, output_name)

print("In progress: demultiplexing and quality filtering of the R1 data...")
subprocess.call(cmd1, shell = True)
print("In progress: demultiplexing and quality filtering of the R2 data...")
subprocess.call(cmd2, shell = True)


## Syncing
cmd = "%ssyncsort_fq deplex_temporary_files_%s/mapping_%s_1/seqs.fastq deplex_temporary_files_%s/mapping_%s_2/seqs.fastq deplex_temporary_files_%s" % (scripts_dir, output_name, output_name, output_name, output_name, output_name)
subprocess.call(cmd, shell = True)

## Cutadapt
## 16S ATTAGAWACCCBDGTAGTCC TTACCGCGGCKGCTGGCAC Since there are variation among the primers it can be helpful to set the -e (allowed error rate) parameter a little less stringent. default = 0.1
cmd = "cutadapt -a ATTAGATACCCTAGTAGTCC deplex_temporary_files_%s/mapping_%s_1/seqs.fastq_paired.fq -o deplex_temporary_files_%s/%s_only_R1_clean.fq -e 0.2" % (output_name, output_name, output_name, output_name)
subprocess.call(cmd, shell = True)
cmd = "cutadapt -a TTACCGCGGCTGCTGTCAC deplex_temporary_files_%s/mapping_%s_2/seqs.fastq_paired.fq -o deplex_temporary_files_%s/%s_only_R2_clean.fq -e 0.2" % (output_name, output_name, output_name, output_name)
subprocess.call(cmd, shell = True)

## Flash
cmd = "flash -m 10 -M 250 -r 250 -f 253 -t 12 -o deplex_temporary_files_%s/%s deplex_temporary_files_%s/%s_only_R1_clean.fq  deplex_temporary_files_%s/%s_only_R2_clean.fq" % (output_name, output_name, output_name, output_name, output_name, output_name)
subprocess.call(cmd, shell = True)

## Syncing
cmd = "%ssyncsort_fq_readindex deplex_temporary_files_%s/%s.extendedFrags.fastq deplex_temporary_files_%s/%s deplex_temporary_files_%s/%s" % (scripts_dir, output_name, output_name, output_name, I1, output_name, I2)
subprocess.call(cmd, shell = True)

## Splitting
print("In progress: split_libraries_fastq.py...")
cmd = "split_libraries_fastq.py -o deplex_temporary_files_%s/mapping_%s -i deplex_temporary_files_%s/%s.extendedFrags.fastq_synced.fq -b deplex_temporary_files_%s/%s_synced.fq  --rev_comp_mapping_barcodes -m deplex_temporary_files_%s/*_corrected_1.txt  --store_demultiplexed_fastq --phred_offset 33 -p 0.6" % (output_name, output_name, output_name, output_name, output_name, I1, output_name)
subprocess.call(cmd, shell = True)

cmd = "%ssplit_fastq.py deplex_temporary_files_%s/mapping_%s/seqs.fastq deplex_temporary_files_%s/%s_synced.fq" % (scripts_dir, output_name, output_name, output_name, I2)
out = subprocess.Popen(cmd, stdout = subprocess.PIPE, shell = True).communicate()
barcodes = out[0].split('\n')[4].split(' ')

for barcode in barcodes:
	print('Analysing ' + barcode)
	cmd = "split_libraries_fastq.py -o deplex_temporary_files_%s/mapping_%s -i deplex_temporary_files_%s/mapping_%s/seqs_%s.fastq -b deplex_temporary_files_%s/mapping_%s/seqs_%s_barcode.fastq   --rev_comp_mapping_barcodes -m deplex_temporary_files_%s/*_corrected_2.txt  --store_demultiplexed_fastq --rev_comp_barcode --phred_offset 33 -p 0.6" % (output_name, barcode, output_name, output_name, barcode, output_name, output_name, barcode, output_name)
	subprocess.call(cmd, shell = True)
	cmd = "chmod 755 -R deplex_temporary_files_%s/mapping_%s" % (output_name, barcode)
	subprocess.call(cmd, shell = True)

cmd = "mkdir deplex_temporary_files_%s/mapping_all" % output_name
subprocess.call(cmd, shell = True)
cmd = "mkdir deplex_temporary_files_%s/mapping_all_fastq" % output_name
subprocess.call(cmd, shell = True)

for barcode in barcodes:
	print('Copying ' + barcode)
	cmd = "cp deplex_temporary_files_%s/mapping_%s/seqs.fna deplex_temporary_files_%s/mapping_all/seqs_%s.fna" % (output_name, barcode, output_name, barcode)
	subprocess.call(cmd, shell = True)
	cmd = "cp deplex_temporary_files_%s/mapping_%s/seqs.fastq deplex_temporary_files_%s/mapping_all_fastq/seqs_%s.fastq" % (output_name, barcode, output_name, barcode)
	subprocess.call(cmd, shell = True)

for barcode in barcodes:
	print('Fixing fasta and fastq file for ' + barcode)
	cmd = "%sfix_header.py deplex_temporary_files_%s/check_map/*_corrected.txt deplex_temporary_files_%s/mapping_all/seqs_%s.fna %s deplex_temporary_files_%s" % (scripts_dir, output_name, output_name, barcode, barcode, output_name)
	subprocess.call(cmd, shell = True)
	cmd = "%sfix_header_fastq.py deplex_temporary_files_%s/check_map/*_corrected.txt deplex_temporary_files_%s/mapping_all_fastq/seqs_%s.fastq %s deplex_temporary_files_%s" % (scripts_dir, output_name, output_name, barcode, barcode, output_name)
	subprocess.call(cmd, shell = True)

## Fix final fasta and fastq files
cmd = "cat deplex_temporary_files_%s/corrected_*.fna > deplex_temporary_files_%s/corrected_tmp.fna" % (output_name, output_name)
subprocess.call(cmd, shell = True)
cmd = "cat deplex_temporary_files_%s/corrected_*.fastq > deplex_temporary_files_%s/corrected_tmp.fastq" % (output_name, output_name)
subprocess.call(cmd, shell = True)
cmd = "%sfix_ID.py deplex_temporary_files_%s/corrected_tmp.fna deplex_temporary_files_%s" % (scripts_dir, output_name, output_name)
subprocess.call(cmd, shell = True)
cmd = "%sfix_ID_fastq.py deplex_temporary_files_%s/corrected_tmp.fastq deplex_temporary_files_%s" % (scripts_dir, output_name, output_name)
subprocess.call(cmd, shell = True)

## Move the created files that should be kept to new locations.
cmd = "mkdir %s_demultiplexed_data" % output_name
subprocess.call(cmd, shell = True)
cmd = "mkdir %s_demultiplexed_data/Histograms" % output_name
subprocess.call(cmd, shell = True)
cmd = "mv deplex_temporary_files_%s/%s.hist* %s_demultiplexed_data/Histograms/." % (output_name, output_name, output_name) 
subprocess.call(cmd, shell = True)
cmd = "mv deplex_temporary_files_%s/check_map/*_corrected.txt %s_demultiplexed_data/." % (output_name, output_name)
subprocess.call(cmd, shell = True)
cmd = "mv deplex_temporary_files_%s/corrected_all.fna %s_demultiplexed_data/%s.fna" % (output_name, output_name, output_name)
subprocess.call(cmd, shell = True)
cmd = "mv deplex_temporary_files_%s/corrected_all.fastq %s_demultiplexed_data/%s.fastq" % (output_name, output_name, output_name)
subprocess.call(cmd, shell = True)


## Remove the files that are created during the script. 
if keep == False:
	cmd = "rm -R deplex_temporary_files_%s" % output_name
	subprocess.call(cmd, shell = True)

cmd = "cat %s_demultiplexed_data/*_corrected.txt | cut -f 1" % output_name
complete = subprocess.Popen(cmd, stdout = subprocess.PIPE, shell = True).communicate()
all_samples = filter(None, complete[0].split('\n')[1:])

f = open('%s_demultiplexed_data/%s_number_of_reads.txt' % (output_name, output_name), 'w')
f.write('%-20s\t\t%10s\n' % ('#SampleID', 'Number of reads'))
for sampleID in all_samples:
	cmd = "grep %s_ %s_demultiplexed_data/%s.fna | wc -l" % (sampleID, output_name, output_name)
	line = subprocess.Popen(cmd, stdout = subprocess.PIPE, shell = True).communicate()
	f.write('%-20s \t\t %10s\n' % (sampleID, line[0].split('\n')[0]))
f.close()

print("********************************************************\n\nDemultiplexing is done, the fasta file is now available!\n\n********************************************************")
