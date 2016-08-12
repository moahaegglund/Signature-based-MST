#!/usr/bin/env python

'''
Script that performs a beta diversity analysis using the metric unweighted unifrac.
Dependencies: QIIME, the script "produce_beta_diversity_plot.R".
by Moa Hammarstrom
'''

import subprocess
import sys
import os
import argparse
import glob

parser = argparse.ArgumentParser()
parser._optionals.title = "Parameters"
parser.add_argument('-m', nargs = 1, help = 'Mapping file. [Required]', required = True)
parser.add_argument('-i', nargs = 1, help = 'OTU table. [Required]', required = True)
parser.add_argument('-t', nargs = 1, help = 'A phylogenetic tree. [Required]', required = True)
parser.add_argument('-p', nargs = 1, help = 'Path to the script produce_beta_diversity_plot.R. [Required]', required = True)
args = parser.parse_args()
arguments = vars(args)

cmd = "beta_diversity.py -m unweighted_unifrac -t %s -o Beta_diversity -i %s" % (''.join(arguments['t']), ''.join(arguments['i']))
subprocess.call(cmd, shell = True)

beta_div_file = glob.glob('Beta_diversity/*.txt')

cmd = "principal_coordinates.py -i %s -o Beta_diversity/unweighted_unifrac" % beta_div_file[0]
subprocess.call(cmd, shell = True)

cmd = "make_2d_plots.py -i Beta_diversity/unweighted_unifrac -m %s -o Beta_diversity" % ''.join(arguments['m'])
subprocess.call(cmd, shell = True)

file_name = 'Beta_diversity/plot_generated_by_phyloseq.eps'

cmd = "biom convert -i %s -o json_format_%s --table-type='OTU table' --to-json" % (''.join(arguments['i']),''.join(arguments['i']))
subprocess.call(cmd, shell = True)

cmd = "Rscript %s json_format_%s %s %s %s" % (''.join(arguments['p']), ''.join(arguments['i']), ''.join(arguments['m']), beta_div_file[0], file_name) 
subprocess.call(cmd, shell = True)
