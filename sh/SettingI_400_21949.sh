#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=2g
#SBATCH -n 1
#SBATCH -t 2-
#SBATCH --job-name=SettingI_400_21949

module add r/4.1.3

Rscript main_settingI.R --seed 21949 --N 400 > SettingI_400_21949.out
