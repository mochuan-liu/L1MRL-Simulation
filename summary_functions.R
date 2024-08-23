# auxiliary functions for summarizing the simulation results
sum_fun <- function(beta_est, dat_testing, method){
  if(is.null(beta_est)){
    return(data.frame(Reward = NA, N1_nonenagtive = NA, N2_nonenagtive = NA,
                      method = method))
  }
  s0 <- dat_testing$s0
  s1 <- dat_testing$s1
  s2 <- dat_testing$s2
  reward_fun <- dat_testing$reward_fun
  
  Reward <- reward_fun(dat_testing, beta_est, s0, s1, s2)
  N1_nonenagtive <- sum(abs(beta_est$beta[[1]][1:P])>10^(-6))
  N2_nonenagtive <- sum(abs(beta_est$beta[[2]][1:P])>10^(-6))
  
  return(data.frame(Reward = Reward, N1_nonenagtive = N1_nonenagtive, N2_nonenagtive = N2_nonenagtive,
                    method = method))
}

sign_new <- function(v){
  s <- sign(v)
  s[s==0] <- 1
  return(s)
}

