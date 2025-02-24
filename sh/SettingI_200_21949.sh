#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=2g
#SBATCH -n 1
#SBATCH -t 1-
#SBATCH --job-name=SettingI_200_21949

module add r/4.1.0

Rscript main_settingI.R --seed 21949 --N 200 > SettingI_200_21949.out
