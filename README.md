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
demultiplex_V4.py -r1 [the R1 file] -r2 [the R2 file] -i1 [the I1 file] -i2 [the I2 file] -p [path to the folder 'scripts_needed_for_demultiplexing'] -o [name of output directory]
</code>

### beta_diversity_analysis.py
The script beta_diversity_analysis.py calls the function produce_beta_diversity_plot.R
