setwd('your_data_directory/output')

N <- 'your_own_N'  # set to 200 or 400 for simulation N=200 or N=400 respectively
sim <- 'setting'   # set to 'SettingI' or 'SettingII' for simulation I or II respectively

# cell function 
cell_string <- function(l){
  
  l <- l[!is.na(l)]
  
  med <- mean(l) |> round(3)
  dev <- sd(l) |> round(3)
  
  return(sprintf('%0.3f(%0.3f)', med, dev))
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
  d <- dat |> filter(method == type)
  d$method <- c()
  l <- list()
  l['Method'] <- type
  for(k in 1:dim(d)[2]){
    s <- cell_string(d[, k])
    l[colnames(d)[k]] <- s
  }
  dat_table <- rbind(dat_table, l |> unlist())
}
dat_table <- as.data.frame(dat_table)

# output the simulation summary
write.csv(dat_table, file = 'your_own_output_path', row.names = FALSE)



