#!/bin/bash
#PBS -A P93300670
#PBS -N SST_CalCS_gregress
#PBS -l walltime=00:45:00
#PBS -M riley.brady@colorado.edu
#PBS -q economy 
#PBS -l select=1:ncpus=1
#PBS -m abe

# Author  : Riley X. Brady
# Date    : 06/01/2017
# Purpose : Use basic UNIX constructs to throughput a number of ensemble members into a
# Python script (with independent operations of course).

# Bring in the virtual environment python
`source activate py36`

script=global_regression_map.py
EBU=CalCS
GLOBAL_VAR=SST
GLOBAL_DIR=/glade/scratch/rbrady/EBUS_BGC_Variability/global_residuals/${GLOBAL_VAR}/
OUT_DIR=/glade/p/work/rbrady/EBUS_BGC_Variability/global_regressions/${GLOBAL_VAR}/${EBU}/lag${L}/

python ${script} ${EBU} ${GLOBAL_VAR} ${L} ${ensemble} ${GLOBAL_DIR} ${OUT_DIR} 