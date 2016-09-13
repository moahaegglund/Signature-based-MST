#!/usr/bin/env python

'''
Script that calls different QIIME scripts in order to perform filtration of an OTU table and convert it to classic format.
by Moa Hammarstroem
'''

import sys
import subprocess
import os
import glob
import argparse

parser = argparse.ArgumentParser()
parser._optionals.title = "Options"
parser.add_argument('-i', nargs =1, help = 'OTU-table to filtrate. [Required]', required = True)
args = parser.parse_args()
arguments = vars(args)

name = ''.join(arguments['i']).split('/')[-1].split('.')[0]

## Filter singletons:
print('Performs filtration -n 2...')
cmd = 'filter_otus_from_otu_table.py -n 2 -i %s -o %s_n2.biom' % (''.join(arguments['i']), name)
subprocess.call(cmd, shell = True)

## Filter -s 3 and --min_count_fraction 0.00001:
print('Performs filtration -s 3 --min_count_fraction 0.00001...')
cmd = 'filter_otus_from_otu_table.py -s 3 --min_count_fraction 0.00001 -i %s_n2.biom -o %s_n2_s3_00001.biom' % (name, name)
subprocess.call(cmd, shell = True)

## Transform to classic format:
print('Transform to classic format...')
cmd = 'biom convert -i %s_n2_s3_00001.biom -o %s_n2_s3_00001_classic.txt --to-tsv --header-key taxonomy' % (name, name)
subprocess.call(cmd, shell = True)
