#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=2g
#SBATCH -n 1
#SBATCH -t 1-
#SBATCH --job-name=SettingII_200_31153

module add r/4.1.0

Rscript main_settingII.R --seed 31153 --N 200 > SettingII_200_31153.out
