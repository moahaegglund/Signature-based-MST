#!/usr/bin/env python

'''
Script that combines different QIIME scripts in order to create a phylogenetic tree.
by Moa Hammarstroem
'''

import sys
import subprocess
import os
import glob
import argparse


parser = argparse.ArgumentParser()
parser._optionals.title = "Parameters"
parser.add_argument('-i', nargs ='+', help = 'OTU mapping file. [Required]', required = True)
parser.add_argument('-O', nargs=1, help = 'Number of jobs to start. [Default is 8.]')
parser.add_argument('-r', nargs=1, help = 'Reference sequences, for example from Greengenes. [Required]', required = True)
parser.add_argument('-a', nargs=1, help = 'Template alignment, for example from Greengenes. [Required]', required = True)
args = parser.parse_args()
arguments = vars(args)

if arguments['O']:
	nr = int(''.join(arguments['O']))
else:
	nr = 8

cmd = "mkdir Representative_set"
subprocess.call(cmd, shell = True)
print "Construction of a representative set...\n"
cmd = "pick_rep_set.py -i %s -o Representative_set/rep_set.fna -r %s" % (''.join(arguments['i']),''.join(arguments['r']))
subprocess.call(cmd, shell = True)

print "Alignment of the representative set...\n"
cmd = "parallel_align_seqs_pynast.py -i Representative_set/rep_set.fna -o Representative_set/Alignment_of_rep_set -O %i -t %s" % (nr,''.join(arguments['a']))
subprocess.call(cmd, shell = True)

print "Filtration of the alignment...\n"
cmd = "filter_alignment.py -i Representative_set/Alignment_of_rep_set/rep_set_aligned.fasta -o Representative_set/Alignment_of_rep_set/filtered_alignment"
subprocess.call(cmd, shell = True)

print "Construction of the phylogenetic tree...\n"
cmd = "make_phylogeny.py -i Representative_set/Alignment_of_rep_set/filtered_alignment/*_pfiltered.fasta -o Representative_set/rep_set.tre"
subprocess.call(cmd, shell = True)
