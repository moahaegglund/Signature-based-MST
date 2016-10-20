# Signature based MST


### demultiplex_V4.py
Script to perform demultiplexing of dual index sequencing data using QIIME. The script is adapted for demultiplexing of the V4 region utilizing the primers 515f/806r.
#### Dependencies
The folder "scripts_needed_for_demultiplexing" has to be supplied along with the following dependencies:
* QIIME
* flash
* cutadapt
* Biopython

#### Example
<code>
demultiplex_V4.py -r1 [the R1 file] -r2 [the R2 file] -i1 [the I1 file] -i2 [the I2 file] -p [path to the folder /scripts_needed_for_demultiplexing] -o [name of output directory]
</code>

### create_phylogenetic_tree.py
A wrapper of different QIIME scripts that creates a phylogenetic tree. The phylogenetic tree is created from the representative set where each OTU is represented by its reference sequence in the database (for example GreenGenes).

#### Dependencies
* QIIME
* Database, for example GreenGenes

#### Example
<code>
create_phylogenetic_tree.py -i [OTU mapping file] -O [number of jobs] -r [reference sequences from GreenGenes] -a [template alignment from GreenGenes]
</code>

### filter_otu_table.py
A wrapper of different QIIME scripts that performs filtration of an OTU table and transforms it into classic format. The following filtrations are performed:
* Removal of singletons.
* Dicard the OTUs with a number of sequences >0.001% of the total number of sequences.
* An OTU must be observed in at least 3 samples to be retained.

#### Dependencies
* QIIME

#### Example
<code>
filter_otu_table.py -i [OTU table]
</code>

### beta_diversity_analysis.py
The script beta_diversity_analysis.py calls the function produce_beta_diversity_plot.R

#### Dependencies
* The script  "produce_beta_diversity_plot.R"
* QIIME
* Phyloseq
* ggplot2

### modify_full_results.R
