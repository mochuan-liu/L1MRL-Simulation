#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=2g
#SBATCH -n 1
#SBATCH -t 2-
#SBATCH --job-name=SettingI_200_35578

module add r/4.1.3

Rscript main_settingI.R --seed 35578 --N 200 > SettingI_200_35578.out
