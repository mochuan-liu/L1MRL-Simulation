setwd('change_to_your_own_working_directory')

source('./optim_functions.R')    # auxiliary functions of L1-MRL
source('./compared_methods.R')  # functions for conducting the competing methods 
source('./summary_functions.R') # auxiliary functions for summarizing the simulations results

# # set up random seed when simulation is conducted in parallel 
# # using Slurm
# suppressPackageStartupMessages(library(optparse))
# option_list <- list( 
#   make_option(c("--seed"), type  = "double", default = 1234,
#   make_option(c("--N"), type  = "double", default = 200)
# )
# opt <- parse_args(OptionParser(option_list = option_list))
# seed <- opt$seed
# N <- opt$N
seed <- 1122
N <- 200        # size of the training data

# set random seed
set.seed(seed)  

# load simulation model and testing data
dat_testing <- readRDS('./testing_data/settingI_testing.rds')
s0 <- dat_testing$s0
s1 <- dat_testing$s1
s2 <- dat_testing$s2

library(truncnorm) |> suppressMessages()
library(DTRlearn2) |> suppressMessages()


################################################################################
# generate training data
################################################################################

# baseline covariates 
Sigma <- matrix(0, ncol = 12, nrow = 12)
for(i in 1:12){
  for(j in 1:12){
    if(i<=6&j<=6&i!=j){
      Sigma[i,j] <- 0.2
    }
    if(i==j){
      Sigma[i,j] <- 1
    }
  }
}
L <- t(chol(Sigma))
Z <- matrix(0, nrow = N, ncol = 12)
for(n in 1:N){
  Z[n,] <- L%*%matrix(rnorm(12, 0, 1), ncol = 1)
}

# treatment randomization
X <- runif(N, 0, 1)
X_intercept <- rnorm(N, 0, 1)
X1 <- Z[,1]*X + X_intercept*1 + rnorm(N, 0, 1)

# stage 1 treatment
P1_true <- X1/3
P1_true <- exp(P1_true)/(1+exp(P1_true))
A1 <- rep(NA, N)
for(n in 1:N){
  A1[n] <- rbinom(1, 1, P1_true[n])
}
A1 <- (A1-0.5)*2

X2 <- Z[,1]*X + X_intercept*(1 + A1/2) + rnorm(N, 0, 1)

# stage 2 treatment
P2_true <- X2/3 + A1/2
P2_true <- exp(P2_true)/(1+exp(P2_true))
A2 <- rep(NA, N)
for(n in 1:N){
  A2[n] <- rbinom(1, 1, P2_true[n])
}
A2 <- (A2-0.5)*2

W <- runif(N, 0, 1)
W_intercept <- rnorm(N, 0, 1)
W1 <- Z[,1]*W + W_intercept*1 + rnorm(N, 0, 1)
W2 <- Z[,1]*W + W_intercept*(1 + A1/2) + rnorm(N, 0, 1)

G <- runif(N, 0, 1)
G_intercept <- rnorm(N, 0, 1)
G1 <- Z[,1]*G + G_intercept*1 + rnorm(N, 0, 1)
G2 <- Z[,1]*G + G_intercept*(1 + A1/2) + rnorm(N, 0, 1)

# create feature lists
H1 <- cbind(X1, W1, G1, Z) |> as.matrix()
H2 <- cbind(X2, W2, G2, Z, A1) |> as.matrix()
p1 <- dim(H1)[2]
p2 <- dim(H2)[2]

H_list <- list(H1 |> scale(), H2 |> scale())
A_list <- list(A1, A2)

# generate reward
Y <- rep(NA, N)
S0 <- s0(Z, X1)
S1 <- s1(Z, X1)
S2 <- s2(Z, X2)
for(n in 1:N){
  Y[n] <- S0[n] + 2*A1[n]*S1[n] + 2*A2[n]*S2[n] + rnorm(1, 0, 1)
}
H1 <- H1 |> scale()
H2 <- H2 |> scale()

################################################################################
# Estimate propensity score via Lasso Logistic regression
################################################################################
cv.model2 <- cv.glmnet(x = H2, y = factor(A2), family = 'binomial', type = 'deviance', alpha = 1)
lambda2 <- cv.model2$lambda.min
model2 <-glmnet(x = H2, y = factor(A2), family = 'binomial', alpha = 1, lambda = lambda2)
P2_est <- predict(model2, type = 'response', newx = H2) |> as.vector()
P2 <- ifelse(A2==1, P2_est, 1-P2_est)

cv.model1 <- cv.glmnet(x = H1, y = factor(A1), family = 'binomial', type = 'deviance', alpha = 1)
lambda1 <- cv.model1$lambda.min
model1 <-glmnet(x = H1, y = factor(A1), family = 'binomial', alpha = 1, lambda = lambda1)
P1_est <- predict(model1, type = 'response', newx = H1) |> as.vector()
P1 <- ifelse(A1==1, P1_est, 1-P1_est)

P_list <- list(P1, P2)

################################################################################
# L1-MRL
################################################################################
# calculate the L1-MRL adaptive coefficient through owl
res_O <- try(owl(H = H_list, AA = A_list, RR = list(rep(0, N), Y), n = N, K = 2, pi = list(P1, P2), augment = TRUE, c = 2^(-2:2))
             , silent = TRUE)
beta1 <- res_O$stage1$beta |> matrix(ncol = 1)
beta01 <- res_O$stage1$beta0
beta2 <- res_O$stage2$beta |> matrix(ncol = 1)
beta02 <- res_O$stage2$beta0

beta_init_un <- list(beta = list(beta1, beta2), 
                     beta0 = list(beta01, beta02))
beta_O <- beta_init_un

T <- length(H_list)
P <- ncol(H_list[[1]])
adaptive_coef <- c()
vec_constant <- c()
for(t in 1:T){
  vec_constant[t] <- norm(beta_init_un$beta[[t]][1:P], '2')
}
for(p in 1:P){
  vec <- c()
  for(t in 1:T){
    vec <- c(vec, beta_init_un$beta[[t]][p]/vec_constant[t])
  }
  adaptive_coef <- c(adaptive_coef, norm(vec, '2'))
}

# implement L1-MRL
P_vec <- P1*P2
lambda_vec <- 2^(0:10)
eta_vec <- 10^(-3:-5)
mu <- 10^(-8)
P <- dim(H1)[2]
cv.folds <- 2

res_l1mrl <- l1mrl_cv(H_list = H_list, A_list = A_list, Y = Y, P_vec = P_vec, 
                    lambda_vec = lambda_vec, eta_vec = eta_vec, mu = mu, 
                    beta_init_un = beta_init_un,
                    adaptive_coef = adaptive_coef, P = P, cv.folds = cv.folds)
beta_L1MRL <- res_l1mrl$coef_list

################################################################################
# compared methods
################################################################################
beta_A <- alearning(Y, A1, A2, H1, H2, P1, P2) # A-learning
beta_Q <- qlearning(Y, A1, A2, H1, H2, P1, P2) # Q-learning
beta_O <- olearning(Y, A1, A2, H1, H2, P1, P2) # O-learning
beta_dWOLS <- dWOLS(Y, A1, A2, H1, H2, P1, P2)      # dWOLS


################################################################################
# create summary table
################################################################################

# load testing data
Y_testing <- dat_testing$Y_testing
H_list_testing <- dat_testing$H_list_testing
A_list_testing <- dat_testing$A_list_testing
P_list_testing <- dat_testing$P_list_testing
P_testing <- ifelse(A_list_testing[[1]]==1, P_list_testing[[1]], 1 - P_list_testing[[1]])*ifelse(A_list_testing[[2]]==1, P_list_testing[[2]], 1 - P_list_testing[[2]])

dat_summary <- c()
dat_summary <- rbind(dat_summary, sum_fun(beta_L1MRL, dat_testing, method = 'L1-MRL'))
dat_summary <- rbind(dat_summary, sum_fun(beta_A, dat_testing, method = 'A-learning'))
dat_summary <- rbind(dat_summary, sum_fun(beta_Q, dat_testing, method = 'Q-learning'))
dat_summary <- rbind(dat_summary, sum_fun(beta_O, dat_testing, method = 'O-learning'))
dat_summary <- rbind(dat_summary, sum_fun(beta_dWOLS, dat_testing, method = 'dWOLS'))


Out <- list(beta_L1MRL = beta_L1MRL, 
            beta_A = beta_A, beta_Q = beta_Q, beta_O = beta_O, beta_dWOLS = beta_dWOLS,
            dat_summary = dat_summary,
            lambda_L1MRL_selected = res_l1mrl$lambda, 
            eta_L1MRL_selected = res_l1mrl$eta, 
            res_L1MRL = res_l1mrl,
            H_list = H_list, 
            A_list = A_list, 
            P_list = P_list,
            Y = Y, P_vec = P_vec, 
            beta_init_un = beta_init_un, 
            adaptive_coef = adaptive_coef)

file_name <- sprintf('./output/L1MRL_SettingI_%s_%s_summary.rds', N, seed)
saveRDS(Out, file_name)
