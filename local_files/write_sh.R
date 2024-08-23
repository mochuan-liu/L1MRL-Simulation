path <- '/Users/mochuanliu/Documents/Zeng/br_3/Rcode/test_4_trial(git)/sh'
seed_list <- readRDS(file.path('/Users/mochuanliu/Documents/Zeng/br_3/Rcode/test_4_trial(git)/', 'seed_list.rds'))

for(seed in seed_list){
  for(N in c(200, 400)){
    file_name <- paste('SettingI', N, seed, sep = '_')
    file_path <- file.path(path, paste(file_name, '.sh', sep = ''))
    fileConn <- file(file_path)
    writeLines(c('#!/bin/bash',
                 '',
                 '#SBATCH -p general',
                 '#SBATCH -N 1',
                 sprintf('#SBATCH --mem=%dg', 2),
                 sprintf('#SBATCH -n %d', 1),
                 '#SBATCH -t 2-',
                 sprintf('#SBATCH --job-name=%s',  file_name),
                 '',
                 'module add r/4.1.3',
                 '',
                 sprintf('Rscript main_settingI.R --seed %s --N %s > %s', 
                         seed,
                         N,
                         paste(file_name, '.out', sep = ''))), 
               fileConn, sep = '\n')
    close(fileConn)
  }
}


for(seed in seed_list){
  for(N in c(200, 400)){
    file_name <- paste('SettingII', N, seed, sep = '_')
    file_path <- file.path(path, paste(file_name, '.sh', sep = ''))
    fileConn <- file(file_path)
    writeLines(c('#!/bin/bash',
                 '',
                 '#SBATCH -p general',
                 '#SBATCH -N 1',
                 sprintf('#SBATCH --mem=%dg', 2),
                 sprintf('#SBATCH -n %d', 1),
                 '#SBATCH -t 2-',
                 sprintf('#SBATCH --job-name=%s',  file_name),
                 '',
                 'module add r/4.1.3',
                 '',
                 sprintf('Rscript main_settingII.R --seed %s --N %s > %s', 
                         seed,
                         N,
                         paste(file_name, '.out', sep = ''))), 
               fileConn, sep = '\n')
    close(fileConn)
  }
}
