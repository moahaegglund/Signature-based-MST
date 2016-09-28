#!/bin/bash


verbose=0
NREP=50
MREADS=100000
NRAW=4
NPOL=2
DIR="/mnt/powervault/jonhall/Desktop/QIIME/Simulation/"
GG="/mnt/powervault/andrsjod/qiime_db/gg_13_8_otus/"
nthread=7
library="library/Without_stormwaters_filtered_data/Without_stormwaters_filtered.biom"
mincount=0.00001
sep=3
classic=0
while getopts "h?r:p:c:ve:n:u:w:b:g:t:l:m:s:x" opt
   do
     case $opt in
        r ) WATER=$OPTARG;;
        p ) POLLUTION=$OPTARG;;
        c ) CONC=$OPTARG;;
        h|\? ) 
            echo "usage: simulation.sh -r raw water source(s) -p polluting source(s) -c number of reads of polluting source(s) -e total number of reads in simulated sample (default 100,000) -n number of repetitions (50) -v verbosity -u number of water samples to sample reads from (4) -w number of polluting samples to sample reads from (2) -b path to parent directory of the raw water and fecal data -g GreenGenes location (parent directory) -t number of threads used in QIIME scripts (7) -l path to sourcetracking reference data -m minimum count fraction for an OTU to be retained (0.00001) -s number of samples that an OTU needs to be present in to be retained (3) -x flag for making an classic otu table" 
            echo " "
            echo "Requires that a parent directory contains subfolders where (1) raw water data from plant 'name' as fasta files are stored (folder name: name_data), (2) pollution data as fasta files, one folder for each source (folder name: source), (3) background water data in a fasta file (path name: name_background/Background_name_filtered.biom where 'name' is the raw water plant name)"
            echo " "
            echo "Requires scripts (in the same directory as simulation.sh): pipeline_mix_reads.pl, rename_sim_samples.pl, remove_sim_samples.pl and remove_sim_samples_map_unp.pl."
            exit 0
        ;;
        v ) verbose=1;;
        e ) MREADS=$OPTARG;;
        n ) NREP=$OPTARG;;
        u ) NRAW=$OPTARG;;
        w ) NPOL=$OPTARG;;
        b ) DIR=$OPTARG;;
        g ) GG=$OPTARG;;
        t ) nthread=$OPTARG;;
        l ) library=$OPTARG;;
        m ) mincount=$OPTARG;;
        s ) sep=$OPTARG;;
        x ) classic=1;;
     esac
done

#echo RAW WATER SOURCE  = "${WATER}"
#echo POLLUTION SOURCE     = "${POLLUTION}"
#echo CONCENTRATION    = "${CONC}"
#echo VERBOSE    = "${verbose}"
#echo MAX READS    = "${MREADS}"
#echo NREP    = "${NREP}"
#echo NRAW = "${NRAW}"
#echo NPOL = "${NPOL}"
#echo DIR = "${DIR}"
#echo GreenGene path = "${GG}"

echo "Script for creating simulated data of contamination events."
echo "Requires Oligotyping and QIIME pipelines"
echo "By Jon Ahlinder"



echo "Subsample reads from samples (step 1)..."
source activate Oligotyping

IFS=' ' read -ra ADDR1 <<< "${WATER}"
IFS=' ' read -ra ADDR2 <<< "${POLLUTION}"
IFS=' ' read -ra ADDR3 <<< "${CONC}"
for i in "${ADDR1[@]}"; do
  for j in "${ADDR2[@]}"; do
    for k in "${ADDR3[@]}"; do
        ./pipeline_mix_reads.pl ${DIR}$j ${NPOL} $k ${DIR}${i}_data ${NRAW} $((${MREADS}/${NRAW} - ${k}/${NRAW})) ${DIR}${i}_${j}/${j}_${i}_${k} ${NREP} ${verbose}
    done
  done
done
echo "Step 1 done!"
echo "Rename simulated data (i.e. headers in fasta files) (step 2)..."
for i in "${ADDR1[@]}"; do
  for j in "${ADDR2[@]}"; do
    for k in "${ADDR3[@]}"; do
      for (( c=1; c<=${NREP}; c++ )); do
          ./rename_sim_samples.pl ${DIR}${i}_${j}/${j}_${i}_${k}_${c}.fasta > ${DIR}${i}_${j}/${j}_${i}_${k}_${c}_name.fasta
          rm ${DIR}${i}_${j}/${j}_${i}_${k}_${c}.fasta
      done
    done
  done
done
echo "Step 2 done!"

source activate qiimeEnv

echo "Closed OTU picking. NB! This step is time consuming! (step 3)..."

for i in "${ADDR1[@]}"; do
  for j in "${ADDR2[@]}"; do
    for k in "${ADDR3[@]}"; do
      for (( c=1; c<=${NREP}; c++ )); do
          pick_closed_reference_otus.py -t ${GG}taxonomy/97_otu_taxonomy.txt -r ${GG}rep_set/97_otus.fasta -aO ${nthread} -i ${DIR}${i}_${j}/${j}_${i}_${k}_${c}_name.fasta -o ${DIR}${i}_${j}/otu_picking_${j}_${i}_${k}_${c} -f
      done
    done
  done
done
echo "Step 3 done!"
echo "Merge the otu tables (library + background + simulated data) (step 4)..."

for i in "${ADDR1[@]}"; do
  for j in "${ADDR2[@]}"; do
    for k in "${ADDR3[@]}"; do
      for (( c=1; c<=${NREP}; c++ )); do
        merge_otu_tables.py -i ${DIR}${i}_background/Background_${i}_filtered.biom,${DIR}${i}_${j}/otu_picking_${j}_${i}_${k}_${c}/otu_table.biom,${DIR}${library} -o ${DIR}${i}_${j}/otu_table_library_${i}_${j}_${k}_${c}.biom
      done
    done
  done
done
echo "Step 4 done!"
echo "Remove samples used in simulation: first, make a list (step 5)..."

for i in "${ADDR1[@]}"; do
  for j in "${ADDR2[@]}"; do
    for k in "${ADDR3[@]}"; do
      for (( c=1; c<=${NREP}; c++ )); do
        ./remove_sim_samples.pl ${DIR}${i}_library_list.txt ${DIR}${i}_${j}/${j}_${i}_${k}_${c}.log > ${DIR}${i}_${j}/samples_to_keep_${i}_${j}_${k}_${c}.txt
        echo "${j}_${i}_${k}_${c}" > ${DIR}sample_name_tmp.txt
        cat ${DIR}${i}_${j}/samples_to_keep_${i}_${j}_${k}_${c}.txt ${DIR}sample_name_tmp.txt > ${DIR}${i}_${j}/samples_to_keep_tmp_${i}_${j}_${k}_${c}.txt
        rm ${DIR}${i}_${j}/samples_to_keep_${i}_${j}_${k}_${c}.txt
      done
    done
  done
done
echo "Step 5 done!"
echo "Remove samples (NB! Time consuming) (step 6)..."
for i in "${ADDR1[@]}"; do
  for j in "${ADDR2[@]}"; do
    for k in "${ADDR3[@]}"; do
      for (( c=1; c<=${NREP}; c++ )); do
        filter_samples_from_otu_table.py --sample_id_fp ${DIR}${i}_${j}/samples_to_keep_tmp_${i}_${j}_${k}_${c}.txt -i ${DIR}${i}_${j}/otu_table_library_${i}_${j}_${k}_${c}.biom -o ${DIR}${i}_${j}/otu_table_final_${i}_${j}_${k}_${c}.biom
      done
    done
  done
done
echo "Step 6 done!"

echo "Update mapping file (step 7)..."

for i in "${ADDR1[@]}"; do
  for j in "${ADDR2[@]}"; do
    for k in "${ADDR3[@]}"; do
      for (( c=1; c<=${NREP}; c++ )); do
        ./remove_sim_samples_map_unp.pl ${DIR}mapping_file_${i}2.txt ${DIR}${i}_${j}/${j}_${i}_${k}_${c}.log ${j}_${i}_${k}_${c} > ${DIR}${i}_${j}/map_${i}_${j}_${k}_${c}.txt
      done
    done
  done
done
echo "Step 7 done!"
echo "Filter OTU tables for singletons, OTU should be kept in at least ${sep} samples, and min frequency of OTU to 0.000 (step 8)..."
for i in "${ADDR1[@]}"; do
  for j in "${ADDR2[@]}"; do
    for k in "${ADDR3[@]}"; do
      for (( c=1; c<=${NREP}; c++ )); do
        filter_otus_from_otu_table.py -n 2 -i ${DIR}${i}_${j}/otu_table_final_${i}_${j}_${k}_${c}.biom -o ${DIR}${i}_${j}/otu_table_final_n2_${i}_${j}_${k}_${c}.biom
        filter_otus_from_otu_table.py --min_count_fraction ${mincount} -s ${sep} -i ${DIR}${i}_${j}/otu_table_final_n2_${i}_${j}_${k}_${c}.biom -o ${DIR}${i}_${j}/otu_table_final_00001_${i}_${j}_${k}_${c}.biom
        rm ${DIR}${i}_${j}/otu_table_final_n2_${i}_${j}_${k}_${c}.biom
      done
    done
  done
done
echo "Step 8 done!"
if [$classic -eq 1 ]; then
  echo "Convert OTU table to classic format (step 9)..."
  for i in "${ADDR1[@]}"; do
    for j in "${ADDR2[@]}"; do
      for k in "${ADDR3[@]}"; do
        for (( c=1; c<=${NREP}; c++ )); do
          biom convert --to-tsv -i ${DIR}${i}_${j}/otu_table_final_00001_${i}_${j}_${k}_${c}.biom -o ${DIR}${i}_${j}/otu_table_final_00001_${i}_${j}_${k}_${c}.txt
        done
      done
    done
  done
  echo "Step 9 done!"
fi
echo "Simulation finished!"
