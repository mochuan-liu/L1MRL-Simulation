#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=2g
#SBATCH -n 1
#SBATCH -t 2-
#SBATCH --job-name=SettingII_200_25528

module add r/4.1.3

Rscript main_settingII.R --seed 25528 --N 200 > SettingII_200_25528.out