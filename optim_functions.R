# default optimization parameters
epsilon_max = 10^(-3)
iteration_max = 50

# single dc iteration optimization
solve_single_optim <- function(psi_coef, psi_intercept, psi_c, psi_coef_weight,
                               g_coef, g_intercept, g_c, g_coef_weight, lambda, c){
  
  # length of each function
  N1 <- length(psi_coef_weight)
  N2 <- length(g_coef_weight)
  
  # search optimal beta according to derivatives
  beta_grid <- c((psi_c-psi_intercept)/psi_coef, 0, (g_c-g_intercept)/g_coef, (-g_c-g_intercept)/g_coef) |> sort()
  derivative_grid <- rep(0, length(beta_grid))
  
  # test if monotone 
  K <- length(beta_grid)
  
  for(k in c(1,K)){
    
    beta_now <- beta_grid[k]
    
    for(i in 1:N1){
      if(psi_coef[i]>=0 & beta_now*psi_coef[i]+psi_intercept[i]>=psi_c[i]){
        derivative_grid[k] <- derivative_grid[k] + psi_coef_weight[i]
      }
      if(psi_coef[i]<0  & beta_now*psi_coef[i]+psi_intercept[i]>psi_c[i]){
        derivative_grid[k] <- derivative_grid[k] + psi_coef_weight[i]
      }
    }
    
    for(i in 1:N2){
      if(g_coef[i]<0){
        if(beta_now*g_coef[i]+g_intercept[i]>   g_c[i]){
          derivative_grid[k] <- derivative_grid[k] + g_coef_weight[i]
        }
        if(beta_now*g_coef[i]+g_intercept[i]<= -g_c[i]){
          derivative_grid[k] <- derivative_grid[k] - g_coef_weight[i]
        }
      }
      
      if(g_coef[i]>=0){
        if(beta_now*g_coef[i]+g_intercept[i]>= g_c[i]){
          derivative_grid[k] <- derivative_grid[k] + g_coef_weight[i]
        }
        if(beta_now*g_coef[i]+g_intercept[i]< -g_c[i]){
          derivative_grid[k] <- derivative_grid[k] - g_coef_weight[i]
        }
      }
    }
    
    if(beta_now<0){
      derivative_grid[k] <- derivative_grid[k] - lambda + c
    }else{
      derivative_grid[k] <- derivative_grid[k] + lambda + c
    }
  }
  
  if(derivative_grid[1]>=0){
    return(beta_grid[1])
  }
  
  if(derivative_grid[K]<=0){
    return(beta_grid[K])
  }
  
  # calculate derivatives
  for(k in c(2:K)){
    
    beta_now <- beta_grid[k]
    
    for(i in 1:N1){
      if(psi_coef[i]>=0 & beta_now*psi_coef[i]+psi_intercept[i]>=psi_c[i]){
        derivative_grid[k] <- derivative_grid[k] + psi_coef_weight[i]
      }
      if(psi_coef[i]<0  & beta_now*psi_coef[i]+psi_intercept[i]>psi_c[i]){
        derivative_grid[k] <- derivative_grid[k] + psi_coef_weight[i]
      }
    }
    
    for(i in 1:N2){
      if(g_coef[i]<0){
        if(beta_now*g_coef[i]+g_intercept[i]>   g_c[i]){
          derivative_grid[k] <- derivative_grid[k] + g_coef_weight[i]
        }
        if(beta_now*g_coef[i]+g_intercept[i]<= -g_c[i]){
          derivative_grid[k] <- derivative_grid[k] - g_coef_weight[i]
        }
      }
      
      if(g_coef[i]>=0){
        if(beta_now*g_coef[i]+g_intercept[i]>= g_c[i]){
          derivative_grid[k] <- derivative_grid[k] + g_coef_weight[i]
        }
        if(beta_now*g_coef[i]+g_intercept[i]< -g_c[i]){
          derivative_grid[k] <- derivative_grid[k] - g_coef_weight[i]
        }
      }
    }
    
    if(beta_now<0){
      derivative_grid[k] <- derivative_grid[k] - lambda + c
    }else{
      derivative_grid[k] <- derivative_grid[k] + lambda + c
    }
    
    if(sign(derivative_grid[k])*sign(derivative_grid[k-1])<0){
      return(beta_grid[k])
    }
    
    if(sign(derivative_grid[k])==0){
      return(beta_grid[k])
    }
  }
}

# single dc update
solve_single_dc <- function(psi_coef, psi_intercept, psi_c, psi_c_2, psi_weight, 
                            g_coef, g_intercept, g_c, g_weight, lambda, 
                            beta_init, mu = 10^(-8)){
  
  # get initial beta
  beta_old <- beta_init
  psi_coef_weight <- psi_coef*psi_weight
  g_coef_weight <- g_coef*g_weight
  
  # initiate dc
  epsilon_now <- Inf
  n_iteration <- 1
  
  while(epsilon_now>epsilon_max&n_iteration<=iteration_max){
    
    # calculate initial intercept term
    derivative_max <- sapply((psi_c_2-beta_old*psi_coef-psi_intercept)/mu, FUN = function(x) 1/(1+exp(x)))*psi_coef_weight
    derivative_g  <- sapply((g_coef*beta_old+g_intercept), FUN = abs_derivative)*g_coef_weight
    
    c_new <- -sum(derivative_max) - sum(derivative_g)
    beta_new <- solve_single_optim(psi_coef = psi_coef, psi_intercept = psi_intercept, psi_c = psi_c, psi_coef_weight = psi_coef_weight,
                                   g_coef = g_coef, g_intercept = g_intercept, g_c = g_c, g_coef_weight = g_coef_weight, 
                                   lambda = lambda, c = c_new)
    epsilon_now <- abs(beta_new-beta_old)
    n_iteration <- n_iteration + 1
    beta_old <- beta_new
    
    if(n_iteration==iteration_max){
      warnings('DC reached maximum iteration limits!')
    }
    
  }
  
  return(beta_new)
}

# psi function
psi_fun <- function(x, eta = 1){
  if(eta == 0){
    return(ifelse(x>0, 1, 0))
  }else{
    return(max(min(x/eta,1),0))
  }
}

abs_derivative <- function(x){
  if(x<0) return(-1)
  if(x>0) return(1)
  if(x==0) return(0)
}

# coordinate decent without CV
l1mrl <- function(H_list, A_list, Y, lambda, adaptive_coef, mu = 10^(-8), beta_init, P, eta){
  
  # subtract mean from Y
  N <- length(Y)
  T <- length(H_list)
  O <- subtract_mean(Y/N, H_list[[1]])
  
  flag_intercept <- rep(0, T)
  for(t in 1:T){
    if(ncol(H_list[[t]])==0){
      H_list[[t]] <- rep(0, N) |> matrix(ncol = 1)
      flag_intercept[t] <- 1
      beta_init$beta[[t]] <- matrix(1, nrow = 1, ncol = 1)
    }
  }
  
  # get the negative index
  index_negative <- which(O<0)
  
  # get input values
  H_list_negative <- list()
  A_list_negative <- list()
  O_negative <- -O[index_negative]
  N_negative <- length(O_negative)
  for(t in 1:T){
    H_list_negative[[t]] <- H_list[[t]][index_negative, , drop = FALSE]
    A_list_negative[[t]] <- A_list[[t]][index_negative]
  }
  
  # begin coordinate decent
  d <- ifelse(O>0, 1, 0)
  psi_weight <- abs(O)
  g_weight <- O_negative
  
  epsilon_now <- Inf
  n_iteration <- 1
  beta_old <- beta_init
  while(epsilon_now>epsilon_max&n_iteration<=iteration_max){
    
    beta_new <- beta_old
    for(t in 1:T){
      # update coefficients via DC
      psi_c_1 <- rep(-Inf, N)
      psi_c_2 <- rep(-Inf, N)
      g_c <- rep(Inf, N_negative)
      for(tt in 1:T){
        if(tt==t) next
        psi_c_1 <- pmax(psi_c_1, -A_list[[tt]]*(H_list[[tt]]%*%beta_new$beta[[tt]]+beta_new$beta0[[tt]]))
        g_c <- pmin(g_c, sapply(abs(H_list_negative[[tt]]%*%beta_new$beta[[tt]]+beta_new$beta0[[tt]]),  FUN = function(x) psi_fun(x, eta = eta)))
      }
      psi_c_2 <- psi_c_1
      psi_c_1 <- pmax(psi_c_1/eta, -d)
      psi_c_2 <- pmax(psi_c_2/eta, -(1-d))
      
      if(ncol(H_list[[t]])==1){
        if(flag_intercept[t]!=1){
          psi_coef <- -A_list[[t]]*H_list[[t]][,1]/eta
          psi_intercept <- rep(0, length(psi_coef))
          
          g_coef <- H_list_negative[[t]][,1]/eta
          g_intercept <- rep(0, length(g_coef))
          
          beta_new$beta[[t]][1] <- solve_single_dc(psi_coef = psi_coef, psi_intercept = psi_intercept, psi_c = psi_c_1, 
                                                   psi_c_2 = psi_c_2, psi_weight = psi_weight, 
                                                   g_coef = g_coef, g_intercept = g_intercept, g_c = g_c, g_weight = g_weight, 
                                                   lambda = lambda/adaptive_coef[1], 
                                                   beta_init = beta_new$beta[[t]][1], 
                                                   mu = mu)
        }
      }else{
        if(P!=0){
          for(p in 1:P){
            psi_coef <- -A_list[[t]]*H_list[[t]][,p]/eta
            psi_intercept <- -A_list[[t]]*(H_list[[t]][,-p, drop = FALSE]%*%beta_new$beta[[t]][-p]+beta_new$beta0[[t]])/eta
            
            g_coef <- H_list_negative[[t]][,p]/eta
            g_intercept <- (H_list_negative[[t]][,-p, drop = FALSE]%*%beta_new$beta[[t]][-p]+beta_new$beta0[[t]])/eta
            
            beta_new$beta[[t]][p] <- solve_single_dc(psi_coef = psi_coef, psi_intercept = psi_intercept, psi_c = psi_c_1, 
                                                     psi_c_2 = psi_c_2, psi_weight = psi_weight, 
                                                     g_coef = g_coef, g_intercept = g_intercept, g_c = g_c, g_weight = g_weight, 
                                                     lambda = lambda/adaptive_coef[p], 
                                                     beta_init = beta_new$beta[[t]][p], 
                                                     mu = mu)
          }
        }
      }
      
      if(dim(H_list[[t]])[2]>=P+1&flag_intercept[t]!=1){
        for(p in (P+1):dim(H_list[[t]])[2]){
          psi_coef <- -A_list[[t]]*H_list[[t]][,p]/eta
          psi_intercept <- -A_list[[t]]*(H_list[[t]][,-p, drop = FALSE]%*%beta_new$beta[[t]][-p]+beta_new$beta0[[t]])/eta
          
          g_coef <- H_list_negative[[t]][,p]/eta
          g_intercept <- (H_list_negative[[t]][,-p, drop = FALSE]%*%beta_new$beta[[t]][-p]+beta_new$beta0[[t]])/eta
          
          beta_new$beta[[t]][p] <- solve_single_dc(psi_coef = psi_coef, psi_intercept = psi_intercept, psi_c = psi_c_1, 
                                                   psi_c_2 = psi_c_2, psi_weight = psi_weight, 
                                                   g_coef = g_coef, g_intercept = g_intercept, g_c = g_c, g_weight = g_weight, 
                                                   lambda = 0, 
                                                   beta_init = beta_new$beta[[t]][p], 
                                                   mu = mu)
        }
      }
      
      # update intercept via grid search
      beta0_grid <- seq(-5,5,0.01)
      L_search <- rep(-Inf, length(beta0_grid))
      psi_vec <- rep(Inf, N)
      g_vec <- rep(Inf, N_negative)
      
      for(tt in 1:T){
        if(tt==t){
          next
        }else{
          p_vec_new <- sapply(A_list[[tt]]*(H_list[[tt]]%*%beta_new$beta[[tt]]+beta_new$beta0[[tt]]), FUN = function(x) psi_fun(x, eta = eta))
          g_vec_new <- sapply(abs(H_list_negative[[tt]]%*%beta_new$beta[[tt]]+beta_new$beta0[[tt]]), FUN = function(x) psi_fun(x, eta = eta))
        }
        psi_vec <- pmin(psi_vec, p_vec_new)
        g_vec <- pmin(g_vec, g_vec_new)
      }
      
      p_main <- H_list[[t]]%*%beta_new$beta[[t]]
      g_main <- H_list_negative[[t]]%*%beta_new$beta[[t]]
      for(k in 1:length(L_search)){
        psi_vec_all <- psi_vec
        g_vec_all <- g_vec
        
        p_vec_new <- sapply(A_list[[t]]*(p_main+beta0_grid[k]), FUN = function(x) psi_fun(x, eta = eta))
        g_vec_new <- sapply(abs(g_main+beta0_grid[k]), FUN = function(x) psi_fun(x, eta = eta))
        
        psi_vec_all <- pmin(psi_vec_all, p_vec_new)
        g_vec_all <- pmin(g_vec_all, g_vec_new)
        
        L_search[k] <- sum(O*psi_vec_all) + sum(O_negative*g_vec_all)
      }
      beta0_new <- beta0_grid[which.max(L_search)]
      beta_new$beta0[[t]] <- beta0_new
    }
    
    n_iteration <- n_iteration + 1
    epsilon_now <- 0
    for(t in 1:T){
      epsilon_now <- epsilon_now + sum(abs(beta_new$beta[[t]]-beta_old$beta[[t]])) + abs(beta_new$beta0[[t]]-beta_old$beta0[[t]])
    }
    beta_old <- beta_new
    
    if(n_iteration==iteration_max){
      warnings('DC reached maximum iteration limits!')
    }
  }
  
  for(t in 1:T){
    if(flag_intercept[t]==1){
      beta_new$beta[[t]] <- numeric(0)
    }
  }
  
  return(beta_new)
}

# l1mrl with CV 
l1mrl_cv <- function(H_list, A_list, Y, P_vec, lambda_vec, eta_vec, mu, beta_init_un, adaptive_coef = NULL, P = NULL, cv.folds = 2){
  
  # calculate adaptive coefficients
  T <- length(H_list)
  P <- ifelse(is.null(P), dim(H_list[[1]])[2], P)
  if(is.null(adaptive_coef)){
    adaptive_coef <- rep(1, P)
  }
  
  # skip CV if lambda is of length 1
  if(length(lambda_vec)==1&length(eta_vec)==1){
    lambda_max <- lambda_vec[1]
    eta_max <- eta_vec[1]
    
    # get the initial estimate
    beta_un_max <- l1mrl(H_list = H_list, A_list = A_list, Y = Y/P_vec, 
                       lambda = 0, adaptive_coef = adaptive_coef, mu = mu, 
                       beta_init = beta_init_un, P = P, eta = eta_max)
    
    # get the final estimate
    S_final <- try(l1mrl(H_list = H_list, A_list = A_list, Y = Y/P_vec, 
                       lambda = lambda_max, adaptive_coef = adaptive_coef, mu = mu, 
                       beta_init = beta_un_max, P = P, eta = eta_max), silent = TRUE)
    if(!is.character(S_final)){
      out <- list(coef_list  = S_final, lambda = lambda_max, eta = eta_max)
    }else{
      out <- S_final
    }
    return(out)
  }
  
  # get the initial estimate
  beta_un_list <- list()
  for(k in 1:length(eta_vec)){
    eta_now <- eta_vec[k]
    S_now <- l1mrl(H_list = H_list, A_list = A_list, Y = Y/P_vec, 
                 lambda = 0, adaptive_coef = adaptive_coef, mu = mu, 
                 beta_init = beta_init_un, P = P, eta = eta_now)
    beta_un_list[[k]] <- list(coef_list  = S_now, eta = eta_now)
  }
  
  # sample indices
  N <- length(Y)
  flods.list <- caret::createFolds(1:N, cv.folds)
  dat.list <- list()
  
  for(k.cv in 1:cv.folds){
    temp.list <- list(H_list_training = list(),  A_list_training = list(), Y_training = c(), P_vec_training = c(),
                      H_list_testing  = list(),  A_list_testing  = list(), Y_testing  = c(), P_vec_testing  = c())
    
    index.training <- flods.list[[k.cv]]
    index.testing  <- setdiff(1:N, index.training)
    
    temp.list$Y_training <- Y[index.training]
    temp.list$Y_testing  <- Y[index.testing]
    temp.list$P_vec_training <- P_vec[index.training]
    temp.list$P_vec_testing  <- P_vec[index.testing]
    psi_vec <- rep(Inf, length(index.testing))
    
    for(t in 1:T){
      temp.list$H_list_training[[t]] <- H_list[[t]][index.training, ]
      temp.list$A_list_training[[t]] <- A_list[[t]][index.training]
      
      temp.list$H_list_testing[[t]] <- H_list[[t]][index.testing, ]
      temp.list$A_list_testing[[t]] <- A_list[[t]][index.testing]
    }
    
    dat.list[[k.cv]] <- temp.list
  }
  
  # CV 
  para_list <- list(lambda = lambda_vec, eta = eta_vec)
  dat_para  <- do.call(expand.grid, para_list) 
  
  Y_est_vec <- c()
  res_list <- list()
  for(k in 1:nrow(dat_para)){
    Y_est <- 0
    S_list <- list()
    lambda_now <- dat_para[k, 1]
    eta_now <- dat_para[k, 2]
    
    for(l in 1:length(eta_vec)){
      if(beta_un_list[[l]]$eta==eta_now){
        beta_un_now <- beta_un_list[[l]]$coef_list
        break
      }
    }
    
    for(k.cv in 1:cv.folds){
      dat <- dat.list[[k.cv]]
      
      H_training_list <- dat$H_list_training
      A_training_list <- dat$A_list_training
      Y_training <- dat$Y_training
      P_vec_training <- dat$P_vec_training
      
      H_testing_list <- dat$H_list_testing
      A_testing_list <- dat$A_list_testing
      Y_testing <- dat$Y_testing
      P_vec_testing <- dat$P_vec_testing
      
      N_testing <- length(Y_testing)
      
      S <- try(l1mrl(H_list =  H_training_list, A_list = A_training_list, Y = Y_training/P_vec_training, 
                   lambda = lambda_now, adaptive_coef = adaptive_coef, mu = mu, 
                   beta_init = beta_un_now, P = P, eta = eta_now), silent = TRUE)
      S_list[[k.cv]] <- S
      if(is.character(S)){
        Y_est <- NA
        S_list <- list()
        break
      }
      
      r <- calculate_obj(Y_testing = Y_testing, P_vec_testing = P_vec_testing, A_testing_list = A_testing_list, H_testing_list = H_testing_list,
                         beta_est = S, beta_un = beta_un_now, eta = eta_now)
      
      r_est <- r$Reward_est
      r_un  <- r$Reward_un
      
      N_testing_nonnegative <- 0
      N_testing_all <- 0
      for(t in 1:T){
        N_testing_nonnegative <- N_testing_nonnegative + sum(abs(S$beta[[t]])>10^(-6)) + (abs(S$beta0[[t]])>10^(-6))
        N_testing_all <- N_testing_all + length(S$beta[[t]]) + 1
      }
      AIC <- N_testing_nonnegative
      BIC <- N_testing_nonnegative*log(N_testing)
      Y_est <- Y_est + (N_testing*log(r_est/r_un) - AIC)/cv.folds
    }
    Y_est_vec <- c(Y_est_vec, Y_est)
    res_list[[k]] <- S_list
    cat('Current lambda: ', lambda_now, ' Current eta: ', eta_now , ' Current reward:', Y_est, '\n')
  }
  
  # complete the estimation using the optimal lambda
  index_optimal <- which.max(Y_est_vec)
  lambda_max <- dat_para[index_optimal, 1]
  eta_max <- dat_para[index_optimal, 2]
  cat('Optimal lambda: ', lambda_max, '\n')
  cat('Optimal eta: ', eta_max, '\n')
  
  for(l in 1:length(eta_vec)){
    if(beta_un_list[[l]]$eta==eta_max){
      beta_un_max <- beta_un_list[[l]]$coef_list
      break
    }
  }
  
  S_final <- try(l1mrl(H_list = H_list, A_list = A_list, Y = Y/P_vec, 
                     lambda = lambda_max, adaptive_coef = adaptive_coef, mu = mu, 
                     beta_init = beta_un_max, P = P, eta = eta_max), silent = TRUE)
  if(!is.character(S_final)){
    out <- list(coef_list = S_final, lambda = lambda_max, eta = eta_max, beta_un_list = beta_un_list,
                dat.list = dat.list, res_list = res_list, dat_para = dat_para)
  }else{
    out <- S_final
  }
  return(out)
}

# calculate the objective function
calculate_obj <- function(Y_testing, P_vec_testing, A_testing_list, H_testing_list, beta_est, beta_un, eta){
  Y_testing <- Y_testing/P_vec_testing
  T <- length(A_testing_list)
  index_negative <- which(Y_testing<0)
  Y_negative <- abs(Y_testing[index_negative])
  
  # estimate the reward
  psi_vec <- rep(Inf, length(Y_testing))
  psi_abs_vec <- rep(Inf, length(index_negative))
  
  for(t in 1:T){
    psi_vec <- pmin(psi_vec, sapply(A_testing_list[[t]]*(H_testing_list[[t]]%*%beta_est$beta[[t]] + beta_est$beta0[[t]]), 
                                    FUN = function(x) psi_fun(x, eta = eta)))
    psi_abs_vec <- pmin(psi_abs_vec, sapply(abs(H_testing_list[[t]][index_negative, ]%*%beta_est$beta[[t]] + beta_est$beta0[[t]]), 
                                            FUN = function(x) psi_fun(x, eta = eta)))
  }
  
  Reward_est <- sum(Y_testing*psi_vec) + sum(psi_abs_vec*Y_negative)
  
  # unconstrained reward
  psi_vec <- rep(Inf, length(Y_testing))
  psi_abs_vec <- rep(Inf, length(index_negative))
  
  for(t in 1:T){
    psi_vec <- pmin(psi_vec, sapply(A_testing_list[[t]]*(H_testing_list[[t]]%*%beta_un$beta[[t]] + beta_un$beta0[[t]]), 
                                    FUN = function(x) psi_fun(x, eta = eta)))
    psi_abs_vec <- pmin(psi_abs_vec, sapply(abs(H_testing_list[[t]][index_negative, ]%*%beta_un$beta[[t]] + beta_un$beta0[[t]]), 
                                            FUN = function(x) psi_fun(x, eta = eta)))
  }
  
  Reward_un <- sum(Y_testing*psi_vec) + sum(psi_abs_vec*Y_negative)
  
  return(list(Reward_est = Reward_est, Reward_un = Reward_un))
}

# replace outcome by residuals
subtract_mean <- function(Y, H){
  H <- as.matrix(H)
  if(ncol(H)==0){
    Y_new <- (Y - mean(Y))
  }else if(ncol(H)==1){
    y.model.lm <- lm(Y~., data = data.frame(Y = Y, X = H))
    y.hat <- predict(y.model.lm, newdata =  data.frame(X = H)) |> as.vector()
    Y_new <- (Y - y.hat)
  }else{
    cv <- cv.glmnet(x = H, y = Y, family = "gaussian", lambda = 10^c(-3:3), alpha = 1)
    y.model.lm <- glmnet(x = H, y = Y, family = "gaussian", lambda = cv$lambda.min)
    y.hat <- predict(y.model.lm, newx =  H) |> as.vector()
    Y_new <- (Y - y.hat)
  }
  return(Y_new)
}