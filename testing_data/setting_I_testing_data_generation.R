# generating setting I testing data
setwd('change_to_your_own_working_directory')

set.seed(2333)
library(truncnorm)

# key functions
s0 <- function(Z, X1){
  if(!is.matrix(Z)) Z <- matrix(Z, nrow = 1)
  return(1+Z[,1]+Z[,3])
}
s1 <- function(Z, X1){
  if(!is.matrix(Z)) Z <- matrix(Z, nrow = 1)
  return(1.5*Z[,1]+1.5*Z[,2]-Z[,7]-Z[,8]-X1)
}
s2 <- function(Z, X2){
  if(!is.matrix(Z)) Z <- matrix(Z, nrow = 1)
  return(1.5*Z[,1]+1.5*Z[,2]-Z[,7]-Z[,8]-X2)
}

# data generation
N <- 5000

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

# important time dependent covariates
X2 <- Z[,1]*X + X_intercept*(1 + A1/2) + rnorm(N, 0, 1)

# stage 2 treatment
P2_true <- X2/3 + A1/2
P2_true <- exp(P2_true)/(1+exp(P2_true))
A2 <- rep(NA, N)
for(n in 1:N){
  A2[n] <- rbinom(1, 1, P2_true[n])
}
A2 <- (A2-0.5)*2

# irrelevant time dependent covariates
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

# reward estimation function
reward_fun <- function(dat_testing, beta_est, s0, s1, s2){
  
  # read coefficients 
  beta2 <- beta_est$beta[[2]]
  beta02 <- beta_est$beta0[[2]]
  beta1 <- beta_est$beta[[1]]
  beta01 <- beta_est$beta0[[1]]
  
  # load data 
  Z <- dat_testing$Z_testing
  X1 <- dat_testing$X1_testng 
  W1 <- dat_testing$W1_testng 
  G1 <- dat_testing$G1_testng 
  X <- dat_testing$X_testing 
  X_intercept <- dat_testing$X_intercept_testing
  G <- dat_testing$G_testing 
  G_intercept <- dat_testing$G_intercept_testing
  W <- dat_testing$W_testing 
  W_intercept <- dat_testing$W_intercept_testing
  H1 <- dat_testing$H1
  H2 <- dat_testing$H2
  
  center2 <- attributes(H2)$`scaled:center`
  scale2  <- attributes(H2)$`scaled:scale`
  
  # start estimation
  set.seed(2233)
  N <- nrow(Z)
  Y_est <- rep(0, N)
  
  beta1 <- matrix(beta1, ncol = 1)
  beta2 <- matrix(beta2, ncol = 1)
  A1_est <- sign(H1%*%beta1 + beta01)
  
  for(n in 1:N){
    l <- c()
    
    x1 <- X1[n]
    x <- X[n]
    x_intercept <- X_intercept[n]
    g <- G[n]
    g_intercept <- G_intercept[n]
    w <- W[n]
    w_intercept <- W_intercept[n]
    z <- Z[n, ]
    a1 <- A1_est[n]
    for(s in 1:100){
      x2 <- z[1]*x + x_intercept*(1+a1/2) + rnorm(1, 0, 1)
      w2 <- z[1]*w + w_intercept*(1+a1/2) + rnorm(1, 0, 1)
      g2 <- Z[1]*g + g_intercept*(1+a1/2) + rnorm(1, 0, 1)
      vec <- matrix(c(x2,w2,g2,z,a1), nrow = 1)
      vec <- scale(vec, center = center2, scale = scale2)
      a2_est <- sign(vec%*%beta2 + beta02)
      l <- c(l, a2_est*s2(z,x2))
    }
    Y_est[n] <- s0(z,x1) + 2*a1*s1(z,x1) + 2*mean(l)
  }
  return(mean(Y_est))
}

out <- list(Y_testing = Y, H_list_testing = H_list, A_list_testing = A_list, P_list_testing = list(P1_true, P2_true),
            H1 = H1, H2 = H2, Z_testing = Z, 
            X1_testng = X1, W1_testng = W1, G1_testng = G1,
            X2_testng = X2, W2_testng = W2, G2_testng = G2,
            X_testing = X, X_intercept_testing = X_intercept,
            W_testing = W, W_intercept_testing = W_intercept,
            G_testing = G, G_intercept_testing = G_intercept,
            s0 = s0, s1 = s1, s2 = s2, reward_fun = reward_fun)

saveRDS(out, './testing_data/settingI_testing.rds')

