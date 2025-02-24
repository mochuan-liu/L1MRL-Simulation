#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=2g
#SBATCH -n 1
#SBATCH -t 1-
#SBATCH --job-name=SettingII_200_42421

module add r/4.1.0

Rscript main_settingII.R --seed 42421 --N 200 > SettingII_200_42421.out
