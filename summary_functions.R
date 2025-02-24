# auxiliary functions for summarizing the simulation results
sum_fun <- function(beta_est, dat_testing, method){
  if(is.null(beta_est)){
    return(data.frame(Reward = NA, 
                      N1_false_neg = NA, N1_false_pos = NA, rate1 = NA,
                      N2_false_neg = NA, N2_false_pos = NA, rate2 = NA,
                      method = method))
  }
  s0 <- dat_testing$s0
  s1 <- dat_testing$s1
  s2 <- dat_testing$s2
  reward_fun <- dat_testing$reward_fun
  
  Reward <- reward_fun(dat_testing, beta_est, s0, s1, s2)
  N1_false_neg <- sum(abs(beta_est$beta[[1]][c(1, 4, 5, 10, 11)])<10^(-6))
  N1_false_pos <- sum(abs(beta_est$beta[[1]][-c(1, 4, 5, 10, 11)])>10^(-6))
  rate1 <- (N1_false_neg + N1_false_pos)/15
  
  N2_false_neg <- sum(abs(beta_est$beta[[2]][c(1, 4, 5, 10, 11)])<10^(-6))
  N2_false_pos <- sum(abs(beta_est$beta[[2]][-c(1, 4, 5, 10, 11)])>10^(-6))
  rate2 <- (N2_false_neg + N2_false_pos)/15
  
  return(data.frame(Reward = Reward, 
                    N1_false_neg = N1_false_neg, N1_false_pos = N1_false_pos, rate1 = rate1,
                    N2_false_neg = N2_false_neg, N2_false_pos = N2_false_pos, rate2 = rate2,
                    method = method))
}

sign_new <- function(v){
  s <- sign(v)
  s[s==0] <- 1
  return(s)
}

