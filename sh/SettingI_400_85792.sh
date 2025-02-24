#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=2g
#SBATCH -n 1
#SBATCH -t 1-
#SBATCH --job-name=SettingI_400_85792

module add r/4.1.0

Rscript main_settingI.R --seed 85792 --N 400 > SettingI_400_85792.out
