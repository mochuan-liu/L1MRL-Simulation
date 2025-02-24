#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=2g
#SBATCH -n 1
#SBATCH -t 1-
#SBATCH --job-name=SettingII_400_7905

module add r/4.1.0

Rscript main_settingII.R --seed 7905 --N 400 > SettingII_400_7905.out
