#!/bin/bash
#PBS -A P93300670
#PBS -N U_BenCS 
#PBS -l walltime=01:00:00
#PBS -M riley.brady@colorado.edu
#PBS -q regular
#PBS -l select=1:ncpus=18
#PBS -m abe

`source activate py36`

script=generate_regional_residuals.py
EBU=BenCS
VAR=U

python ${script} ${VAR}


