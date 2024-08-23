#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=2g
#SBATCH -n 1
#SBATCH -t 2-
#SBATCH --job-name=SettingII_200_18991

module add r/4.1.3

Rscript main_settingII.R --seed 18991 --N 200 > SettingII_200_18991.out
