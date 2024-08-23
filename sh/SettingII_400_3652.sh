#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=2g
#SBATCH -n 1
#SBATCH -t 2-
#SBATCH --job-name=SettingII_400_3652

module add r/4.1.3

Rscript main_settingII.R --seed 3652 --N 400 > SettingII_400_3652.out
