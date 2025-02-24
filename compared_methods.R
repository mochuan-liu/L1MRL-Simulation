################################################################################
# A-learning:
# The R codes are modified from CRAN ITRSelect package source code.
# Depended package list can be found at 
# GitHub repo https://github.com/cran/ITRSelect.
# Please see  Shi, et al (2018) and 
# https://github.com/cran/ITRSelect for more details.
################################################################################
source('./other_methods/alearning/PAL.control.R')
source('./other_methods/alearning/PAL.fit.R')
source('./other_methods/alearning/PAL.R')

alearning <- function(Y, A1, A2, H1, H2, P1, P2){
  
  a1 <- (A1/2+0.5)
  a2 <- (A2/2+0.5)
  
  result <- try(PAL(Y~H1|a1|H2|a2, pi1.est = P1, pi2.est = P2), silent = TRUE) 
  
  if(!is.character(result)){
    beta1 <-  result$beta1.est[2:(dim(H1)[2]+1)] |> matrix(ncol = 1)
    beta01 <- result$beta1.est[1]
    beta2 <-  result$beta2.est[2:(dim(H2)[2]+1)] |> matrix(ncol = 1)
    beta02 <- result$beta2.est[1]
    
    beta_A <- list(beta = list(beta1, beta2), 
                   beta0 = list(beta01, beta02))
    
  }else{
    beta_A <- NULL
  }
  
  return(beta_A)
}

################################################################################
# Q-learning:
# Function ql() from CRAN package DTRlearn2 is used
# to conduct the Q-learning estimation.
# See https://cran.r-project.org/web/packages/DTRlearn2/index.html 
# for more package information.
################################################################################
require(DTRlearn2) |> suppressMessages()

qlearning <- function(Y, A1, A2, H1, H2, P1, P2){
  N <- length(Y)
  p1 <- dim(H1)[2]
  p2 <- dim(H2)[2]
  res_Q <- try(ql(H = list(H1, H2), AA = list(A1, A2), RR = list(rep(0, N), Y), K = 2, pi = list(P1, P2), lasso = TRUE), silent = TRUE)
  beta_Q <- list(beta = list(matrix(res_Q$stage1$co[(p1+3):(2*p1+2)], ncol = 1), matrix(res_Q$stage2$co[(p2+3):(2*p2+2)], ncol = 1)), 
                 beta0 = list(res_Q$stage1$co[p1+2], res_Q$stage2$co[p2+2]))
  
  return(beta_Q)
}

################################################################################
# L1 O-learning:
# The implementation requires CRAN R package lpSolve.
################################################################################
require(lpSolve) |> suppressMessages()
source('./other_methods/olearning/l1owl.R')

olearning <- function(Y, A1, A2, H1, H2, P1, P2, lambda_vec = 10^(-5:5), cv.folds = 2){
  res_OL1 <- try(owl2_l1(list(H1, H2), list(A1, A2), list(P1, P2), Y, lambda_vec = lambda_vec, cv.folds = cv.folds)
                 , silent = TRUE)
  beta_OL1 <- list(beta = res_OL1$beta, beta0 = res_OL1$beta0)
  
  return(beta_OL1)
}

################################################################################
# dWOLS:
# The sourced file './dWOLS/sail.R' is forked and modified from 
# GitHub repo https://github.com/ZeyuBian/pdwols.
# Installation instruction of depended package 'sail' can be found 
# in GitHub repo https://github.com/sahirbhatnagar/sail.
# Please see Bian, et al (2023) for more information.
################################################################################
require(sail) |> suppressMessages()
source('./other_methods/dWOLS/sail.R')

dWOLS <- function(Y, A1, A2, H1, H2, P1, P2){
  
  beta_pd <- NULL
  
  a1 <- (A1/2+0.5)
  a2 <- (A2/2+0.5)
  Y2 <- Y
  w <- abs(a2 - P2)
  p <- ncol(H2)
  pfac2 <- c(rep(1,p),0,rep(1,p))
  pfac2 <- pfac2/sum(pfac2) * (2*p+1)
  pfac2 <- c(pfac2[p+1],pfac2[-p-1])
  
  n_try <- 1
  while(n_try <= 5){
    m <- try(cv.sail(y = Y2, e = a2, x = H2, nfolds = 2, weights = w, penalty.factor = pfac2,
                     parallel = FALSE, basis=function(i) i), silent = TRUE)
    n_try <- n_try + 1
    if(!is.character(m)) break
  }  
  
  if(!is.character(m)){
    sail2 <- coef(m, s = 'lambda.min')[(p+2):(2*p+2)]
    beta2 <- sail2[2:(p+1)] |> matrix(ncol = 1)
    beta02 <- sail2[1]
    
    aopt <- as.numeric(cbind(1, H2)%*%sail2>0)
    Y1 <- Y2 + (aopt - a2)*cbind(1, H2)%*%sail2
    
    w <- abs(a1 - P1)
    p <- ncol(H1)
    pfac1 <- c(rep(1,p),0,rep(1,p))
    pfac1 <- pfac1/sum(pfac1) * (2*p+1)
    pfac1 <- c(pfac1[p+1],pfac1[-p-1])
    
    n_try <- 1
    while(n_try <= 5){
      m <- try(cv.sail(y = Y1, e = a1, x = H1, nfolds = 2, weights = w, penalty.factor = pfac1,
                       parallel = FALSE, basis=function(i) i), silent = TRUE)
      n_try <- n_try + 1
      if(!is.character(m)) break
    }
    
    if(!is.character(m)){
      sail1 <- coef(m, s = 'lambda.min')
      
      beta1 <- sail1[2:(p+1)] |> matrix(ncol = 1)
      beta01 <- sail2[1]
      
      beta_pd <- list(beta = list(beta1, beta2), 
                      beta0 = list(beta01, beta02))
    }
  }
  
  return(beta_pd)
}
























