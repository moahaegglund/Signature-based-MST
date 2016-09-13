#!/usr/bin/env Rscript

## Script to produce a PCoA plot that visualize the result of a beta diversity analysis performed in QIIME. 
## The script is called from the function "beta_diversity_analysis.py"
## Dependencies: phyloseq, ggplot2.
## by Moa Hammarstroem

args = commandArgs(trailingOnly = TRUE)
require(ggplot2)
require(phyloseq)

biomtable = import_biom(args[1], parseFunction = parse_taxonomy_greengenes)
map = import_qiime_sample_data(mapfilename=args[2])
qiimedata = merge_phyloseq(biomtable, map)
unweighted = read.table(args[3],header=T,row.names=1)
unweighted=as.dist(unweighted)
GP.ord <- ordinate(qiimedata, method='PCoA', distance=unweighted)

postscript(args[4])
plot_ordination(qiimedata, GP.ord, title = "Unweighted unifrac")+ geom_point(size=3)
dev.off()

## Code to use in order to change color and shape of the dots in the ordination.
# sample_data(qiimedata)$Location = factor(sample_data(qiimedata)$Location)
# sample_data(qiimedata)$Season = factor(sample_data(qiimedata)$Season)
# plot_ordination(qiimedata, GP.ord, title = "Unweighted unifrac",color="Location", shape='Season')+ geom_point(size=3)
