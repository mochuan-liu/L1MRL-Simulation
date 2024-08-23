# solve single stage OWL with L1 norm using lpSolve 
# https://cran.r-project.org/web/packages/lpSolve/index.html
wsvm_lp <- function(Y, H, A, P, lambda){
  
  # suppressMessages(require(lpSolve))
  
  # replace outcome Y by residuals
  cv.res <- cv.glmnet(x = H, y = Y, family = 'gaussian')
  cv.lambda <- cv.res$lambda.min
  m.model <- glmnet(x = H, y = Y, lambda = cv.lambda, family = 'gaussian')
  m.hat <- predict(m.model, newx = H)
  
  Y <- Y - m.hat
  A <- A*sign(Y) 
  Y <- abs(Y)/P
  
  # start estimation
  N <- nrow(H)
  p <- ncol(H)
  lambda_use <- lambda
  
  A_mat <- diag(as.vector(A))
  
  f.obj <- c(Y, rep(0, p), rep(lambda_use, p), 0)
  
  f.con.1 <- cbind(diag(1, N), matrix(0, nrow = N, ncol = 2*p + 1))
  f.con.2 <- cbind(diag(1, N), A_mat%*%H, matrix(0, nrow = N, ncol = p), matrix(A, ncol = 1))
  f.con.3 <- cbind(matrix(0, nrow = p, ncol = N), diag(-1, p), diag(1, p), 0)
  f.con.4 <- cbind(matrix(0, nrow = p, ncol = N), diag(1, p), diag(1, p), 0)
  f.con <- rbind(f.con.1, f.con.2, f.con.3, f.con.4)
  
  f.dir <- rep('>=', nrow(f.con))
  f.rhs <- c(rep(0, nrow(f.con.1)), rep(1, nrow(f.con.2)), rep(0, nrow(f.con.3)), rep(0, nrow(f.con.4)))
  
  o <- lp('min', f.obj, f.con, f.dir, f.rhs)
  
  beta <- o$solution[(N+1):(N+p)]
  beta0 <- o$solution[N+2*p+1]
  
  return(list(beta = beta, beta0 = beta0))
}

# cv wsvm_lp 
cv.wsvm_lp <- function(Y, H, A, P, lambda_vec, cv.folds = 2){
  
  N <- length(Y)
  
  # cv training/testing data
  flods.list <- caret::createFolds(1:N, cv.folds)
  dat.list <- list()
  
  for(k.cv in 1:cv.folds){
    temp.list <- list(H_training = list(),  A_training = list(), P_training = c(), Y_training = c(),
                      H_testing  = list(),  A_testing  = list(), P_testing  = c(), Y_testing = c())
    
    index_training <- flods.list[[k.cv]]
    index_testing  <- setdiff(1:N, index_training)
    
    temp.list$H_training <- H[index_training, ]
    temp.list$A_training <- A[index_training]
    temp.list$P_training <- P[index_training]
    temp.list$Y_training <- Y[index_training]
    
    temp.list$H_testing <- H[index_testing, ]
    temp.list$A_testing <- A[index_testing]
    temp.list$P_testing <- P[index_testing]
    temp.list$Y_testing <- Y[index_testing]
    
    dat.list[[k.cv]] <- temp.list
  }
  
  # conduct cv 
  reward_vec <- c()
  for(lambda_now in lambda_vec){
    reward_now <- 0
    for(k.cv in cv.folds){
      dat <- dat.list[[k.cv]]
      
      H_training <- dat$H_training
      A_training <- dat$A_training
      P_training <- dat$P_training
      Y_training <- dat$Y_training
      
      H_testing <- dat$H_testing
      A_testing <- dat$A_testing
      P_testing <- dat$P_testing
      Y_testing <- dat$Y_testing
      
      o <- try(wsvm_lp(Y_training, H_training, A_training, P_training, lambda = lambda_now), silent = TRUE)
      if(!is.character(o)){
        beta_now <- o$beta
        beta0_now <- o$beta0
        reward_now <- reward_now + mean(Y_testing*((A_testing*(H_testing%*%beta_now+beta0_now))>0)/P_testing)/cv.folds
      }else{
        reward_now <- NA 
        break
      }
    }
    reward_vec <- c(reward_vec, reward_now)
  }
  
  # get the maximum reward
  reward_vec[is.na(reward_vec)] <- -Inf
  index_max <- which.max(reward_vec)
  lambda_max <- lambda_vec[index_max]
  o <- try(wsvm_lp(Y, H, A, P, lambda = lambda_max), silent = TRUE)
  
  return(list(beta = o$beta, beta0 = o$beta0, lambda = lambda_max))
}

# two stages owl 
owl2_l1 <- function(H_list, A_list, P_list, Y, lambda_vec, cv.folds = 2){
  
  # get sample size and number of stages 
  T <- length(H_list)
  if(T!=2){
    stop('T>2 not support yet!')
  }
  
  # backward stage 2
  o2 <- cv.wsvm_lp(Y = Y, H = H_list[[2]], A = A_list[[2]], P = P_list[[2]], lambda_vec = lambda_vec, cv.folds = cv.folds)
  beta2 <- o2$beta
  beta02 <- o2$beta0
  lambda2 <- o2$lambda
  A2_est <- sign(H_list[[2]]%*%beta2 + beta02)
  
  if(all(c(beta2, beta02)==0)){
    r1 <- mean(Y*(A_list[[2]]== 1)/P_list[[2]])
    r0 <- mean(Y*(A_list[[2]]==-1)/P_list[[2]])
    beta02 <- ifelse(r1>=r0, 1, -1)
    A2_est <- sign(H_list[[2]]%*%beta2 + beta02)
  }
  
  # backward stage 1
  weight <- ((A_list[[2]]==A2_est)/P_list[[2]])*(1-P_list[[2]])/P_list[[2]]
  
  cv.res <- cv.glmnet(x = H_list[[2]], y = Y, weights = weight, family = 'gaussian')
  cv.lambda <- cv.res$lambda.min
  m.model <- glmnet(x = H_list[[2]], y = Y, weights = weight, lambda = cv.lambda, family = 'gaussian') 
  m.hat <- predict(m.model, newx = H_list[[2]])
  
  Y1 <- Y*(A_list[[2]]==A2_est)/P_list[[2]] - ((A_list[[2]]==A2_est)/P_list[[2]]-1)*m.hat
  
  o1 <- cv.wsvm_lp(Y = Y1, H = H_list[[1]], A = A_list[[1]], P = P_list[[1]], lambda_vec = lambda_vec, cv.folds = cv.folds)
  beta1 <- o1$beta
  beta01 <- o1$beta0
  lambda1 <- o1$lambda
  
  return(list(beta = list(beta1 |> matrix(ncol = 1), beta2 |> matrix(ncol = 1)), beta0 = list(beta01, beta02), lambda = list(lambda1, lambda2)))
}






