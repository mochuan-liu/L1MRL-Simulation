Under construction!

This repo contains the R codes to conduct L1-MRL and reproduce the simulation results of 'Simultaneous Feature Selection for Optimal Dynamic Treatment Regimens'. The repo includes the following scripts/folders:

- 'main_settingI.R' and 'main_settingII.R' are two main scripts. Users can replicate 1 simulation under setting I and setting II using the main script respectively. Simulation results, including the estimated coefficients from L1-MRL and 4 competing methods, are outputted in an RDS file (the default output path is './output'). The scripts are also compatibale with parallel computing using SLURM by providing the number of training samples (N) and the random seed. The original simulation results are obtained via parallel computing and the shell scripts used are provided in folder 'sh'. 
- 'summary_functions.R' contains the auxiliary functions to generate the simulation result of two main scripts.
- 'create_summary_table.R' contains the R script to summarize the simulation results from multiple simulations and organize the results into one single table similar to Table 1 in the paper. 
- 'optim_functions.R' includes the functional auxiliary functions for implementing the L1-MRL
- 'compared_methods.R' contains the interface of 4 competing methods.
- 'other_methods' folder includes the functional auxiliary functions for implementing the competing methods. A major part of the codes are forked and modified from public GitHub repo/CRAN packages. Please see the comments in the scripts for more information about the source of each piece of code. 
- 'testing_data' includes the generated testing data (saved in RDS format) for replicating the simulation results in Table 1. Two R scripts 'setting_I_testing_data_generation.R' and 'setting_II_testing_data_generation.R' generating the testing data are also provided.