#!/usr/bin/env python

import subprocess
import sys
import os
import argparse
import glob

parser = argparse.ArgumentParser()
parser._optionals.title = "Options"
parser.add_argument('-m', nargs = 1, help = 'Mapping file. [Required]', required = True)
parser.add_argument('-i', nargs = 1, help = 'OTU table. [Required]', required = True)
parser.add_argument('-t', nargs = 1, help = 'A phylogenetic tree.', required = True)
parser.add_argument('-o', nargs = 1, help = 'A name that is given to the output files. [Required]', required = True)
args = parser.parse_args()
arguments = vars(args)

output_name = ''.join(arguments['o'])

cmd = "beta_diversity.py -m unweighted_unifrac -t %s -o Beta_diversity_%s -i %s" % (''.join(arguments['t']), output_name, ''.join(arguments['i']))
subprocess.call(cmd, shell = True)

beta_div_file = glob.glob('Beta_diversity_%s/*.txt' % output_name)

cmd = "principal_coordinates.py -i %s -o Beta_diversity_%s/unweighted_unifrac" % (beta_div_file[0], output_name)
subprocess.call(cmd, shell = True)

cmd = "make_2d_plots.py -i Beta_diversity_%s/unweighted_unifrac -m %s -o Beta_diversity_%s" % (output_name, ''.join(arguments['m']), output_name)
subprocess.call(cmd, shell = True)

file_name = 'Beta_diversity_%s/plot_generated_by_phyloseq.eps' % output_name

cmd = "biom convert -i %s -o json_format_%s --table-type='OTU table' --to-json" % (''.join(arguments['i']),''.join(arguments['i']))
subprocess.call(cmd, shell = True)

cmd = "Rscript produce_beta_diversity_plots.R json_format_%s %s %s %s" % (''.join(arguments['i']), ''.join(arguments['m']), beta_div_file[0], file_name) 
subprocess.call(cmd, shell = True)

cmd = "rm json_format_%s" % ''.join(arguments['i'])
subprocess.call(cmd, shell = True)
