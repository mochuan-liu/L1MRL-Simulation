#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=2g
#SBATCH -n 1
#SBATCH -t 1-
#SBATCH --job-name=SettingII_400_66959

module add r/4.1.0

Rscript main_settingII.R --seed 66959 --N 400 > SettingII_400_66959.out
