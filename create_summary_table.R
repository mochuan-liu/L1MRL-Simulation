setwd('your_data_directory/output')

N <- 'your_own_N'  # set to 200 or 400 for simulation N=200 or N=400, respectively
sim <- 'Setting'   # set to 'SettingI' or 'SettingII' for simulation I or II, respectively

# cell function 
cell_string <- function(l){
  
  l <- l[!is.na(l)]
  
  med <- mean(l) |> round(3)
  dev <- sd(l) |> round(3)
  
  return(sprintf('%0.3f (%0.3f)', med, dev))
}

# 
dat <- c()
for(file in list.files()){
  if(!grepl('rds', file)) next
  if(!grepl('L1MRL', file)) next
  
  para_list <- strsplit(file, '_')[[1]]
  file_N <- para_list[3] |> as.numeric()
  file_sim <- para_list[2]
  if(file_N!=N) next
  if(file_sim!=sim) next
  O <- readRDS(file)
  
  dat <- rbind(dat, O$dat_summary)
}

# summary
dat_table <- c()
for(type in unique(dat$method)){
  d <- dat[dat$method == type,]
  d$method <- c()
  l <- list()
  l['method'] <- type
  for(k in 1:dim(d)[2]){
    s <- cell_string(d[, k])
    l[colnames(d)[k]] <- s
  }
  dat_table <- rbind(dat_table, l |> unlist())
}
dat_table <- as.data.frame(dat_table)

# Jaccard Index 
jaccard <- function(a, b) {
  intersection = length(intersect(a, b))
  union = length(a) + length(b) - intersection
  if(union==0){
    return(1)
  }else{
    return (intersection/union)
  }
}

jaccard_mean <- function(l){
  s1 <- c()
  s2 <- c()
  K <- length(l)
  
  for(i in 1:K){
    for(j in (i+1):K){
      if(i>K|j>K) next
      if(i==j) next
      if(is.null(l[[i]])|is.null(l[[j]])) next
      
      l11 <- which(abs(l[[i]]$beta[[1]][1:15])>=10^(-6))
      l12 <- which(abs(l[[j]]$beta[[1]][1:15])>=10^(-6))
      
      l21 <- which(abs(l[[i]]$beta[[2]][1:15])>=10^(-6))
      l22 <- which(abs(l[[j]]$beta[[2]][1:15])>=10^(-6))
      
      s1 <- c(s1, jaccard(l11, l12))
      s2 <- c(s2, jaccard(l21, l22))
    }
  }
  
  return(list(s1 = s1, s2 = s2))
}

MRL_list <- list()
A_list <- list()
Q_list <- list()
OWL_list <- list()
dWOLS_list <- list()

ii <- 0
for(file in list.files()){
  ii <- ii + 1
  O <- readRDS(file)
  
  beta_O <- O$beta_O
  beta_Q <- O$beta_Q
  beta_L1MRL <- O$beta_L1MRL
  beta_A <- O$beta_A
  beta_dWOLS <- O$beta_dWOLS
  
  Q_list[[ii]] <- beta_Q
  A_list[[ii]] <- beta_A
  dWOLS_list[[ii]] <- beta_dWOLS
  MRL_list[[ii]] <- beta_L1MRL
  OWL_list[[ii]] <- beta_O
}

dat_ji <- data.frame()

MRL_jaccard <- jaccard_mean(l = MRL_list)
MRL_jaccard_1 <- (mean(MRL_jaccard$s1) |> round(3))
MRL_jaccard_2 <- (mean(MRL_jaccard$s2) |> round(3))

dat_ji <- rbind(dat_ji, data.frame(method = 'L1-MRL', 'JI1' = MRL_jaccard_1, 'JI2' =  MRL_jaccard_2))

A_jaccard <- jaccard_mean(l = A_list)
A_jaccard_1 <- (mean(A_jaccard$s1) |> round(3))
A_jaccard_2 <- (mean(A_jaccard$s2) |> round(3))

dat_ji <- rbind(dat_ji, data.frame(method = 'A-learning', 'JI1' = A_jaccard_1, 'JI2' =  A_jaccard_2))

Q_jaccard <- jaccard_mean(l = Q_list)
Q_jaccard_1 <- (mean(Q_jaccard$s1) |> round(3))
Q_jaccard_2 <- (mean(Q_jaccard$s2) |> round(3))

dat_ji <- rbind(dat_ji, data.frame(method = 'Q-learning', 'JI1' = Q_jaccard_1, 'JI2' =  Q_jaccard_2))

OWL_jaccard <- jaccard_mean(l = OWL_list)
OWL_jaccard_1 <- (mean(OWL_jaccard$s1) |> round(3))
OWL_jaccard_2 <- (mean(OWL_jaccard$s2) |> round(3))

dat_ji <- rbind(dat_ji, data.frame(method = 'O-learning', 'JI1' = OWL_jaccard_1, 'JI2' =  OWL_jaccard_2))

dWOLS_jaccard <- jaccard_mean(l = dWOLS_list)
dWOLS_jaccard_1 <- (mean(dWOLS_jaccard$s1) |> round(3))
dWOLS_jaccard_2 <- (mean(dWOLS_jaccard$s2) |> round(3))

dat_ji <- rbind(dat_ji, data.frame(method = 'dWOLS', 'JI1' = dWOLS_jaccard_1, 'JI2' =  dWOLS_jaccard_2))

dat_table <- merge(dat_table, dat_ji, by = 'method', all.x = TRUE, all.y = FALSE)

# output the simulation summary
write.csv(dat_table, file = 'your_own_output_path', row.names = FALSE)



