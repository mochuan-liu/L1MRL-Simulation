This repository contains the R code to conduct L1-MRL and reproduce the simulation results from the paper "Simultaneous Feature Selection for Optimal Dynamic Treatment Regimens". The repository includes the following scripts and folders:

- 'main_settingI.R' and 'main_settingII.R': : These are the main scripts. Users can replicate one simulation under Setting I and Setting II using the respective main script. The simulation results, including the estimated coefficients from L1-MRL and four competing methods, are outputted in an RDS file (the default output path is './output'). The scripts are compatible with parallel computing using SLURM by specifying the number of training samples (N) and the random seed (seed). The original simulation results were obtained via parallel computing, and the shell scripts are provided in the 'sh' folder.
- 'summary_functions.R': This script contains auxiliary functions to generate the simulation results for the two main scripts.
- 'create_summary_table.R': This script summarizes the simulation results from multiple simulations and organizes them into a single table, similar to Table 1 in the paper.
- 'optim_functions.R': This script includes the main and auxiliary functions for implementing L1-MRL.
- 'compared_methods.R': This script provides the interface for the four competing methods.
- 'other_methods': This folder contains functional auxiliary scripts for implementing the competing methods. Most of the code is forked and modified from public GitHub repositories or CRAN packages. Please refer to the comments in the scripts for more information about the source of each piece of code.
- 'testing_data': This folder includes the generated testing data (saved in RDS format) for replicating the simulation results in Table 1. Two R scripts, 'setting_I_testing_data_generation.R' and 'setting_II_testing_data_generation.R',  which generate the testing data, are also provided.


Users can call function l1mrl_cv() in 'optim_functions.R' to implement L1-MRL. The function inputs are as follows:

H_list: A list of standardized input feature matrices from t=1 to T. Feature matrices must be reorganized so that the first P columns are the features considered for variable selection.
A_list: A list of input observed treatment vectors from t=1 to T (encoded as +1 and -1).
Y: A vector of observed cumulative reward.P_vec: A vector of the product of treatment assignment probabilities p(A_1|H_1)*...*p(A_T|H_T).
lambda_vec: A vector of tuning grid values for the tuning parameter lambda
eta_vec: A vector of tuning grid values for the tuning parameter eta
mu: A scalar of smoothing parameter mu
beta_init_un: A list with two attributes - 'beta' and 'beta0'. The beta attribute is a list of vectors (length = T) containing initial values for the non-intercept terms. The beta0 attribute is a list of scalars (length = T) containing initial values for the intercept terms.
adaptive_coef: A vector of adaptive coefficients (see the main scripts for constructing adaptive_coef from AOWL).
cv.folds: The number of cross-validation folds for selecting the optimal tuning parameters.

The output of l1mrl_cv() is a list with three attributes:

coef_list: A list of two attributes, 'beta' and 'beta0'. Attribute 'beta' is a list of vectors containing the estimated optimal coefficients for the non-intercept terms. Attribute 'beta0' is a list of scalars containing the estimated optimal intercept terms.
lambda: The optimal lambda selected by the cross-validation.
eta: The optimal eta selected by the cross-validation.





