#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=2g
#SBATCH -n 1
#SBATCH -t 1-
#SBATCH --job-name=SettingI_400_68454

module add r/4.1.0

Rscript main_settingI.R --seed 68454 --N 400 > SettingI_400_68454.out
