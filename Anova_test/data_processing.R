# setwd('qingchaowan/modeling_project/Anova test/')
getwd()
setwd('/home/qc/Documents/my_github/modelling_projects/Anova_test/DATADATA1/')
# The following system command should be run in linux OS
# system("rename 's/.xls$/.txt/' *.xls")
fileNames <- list.files()

# Please install this package for the first time using it
# install.packages('readr')
require(readr)
# df <- read_csv('bjCH.csv')
require(dplyr)
require(stringr)

final_df <- c()
for (fileName in fileNames) {
  
  fileName_without_ext <- fileName %>% str_split('\\.') %>% .[[1]] %>% .[1]
  filmName <- str_replace_all(fileName_without_ext, '[[:upper:]]', '')
  subtitle <- str_replace_all(fileName_without_ext, '[[:lower:]]', '')
  df <- read.delim(fileName) %>% as.data.frame() %>%
    select(RECORDING_SESSION_LABEL, IA_DWELL_TIME, IA_FIXATION_COUNT, `IA_DWELL_TIME_.`, `IA_FIXATION_.`, IA_LABEL) %>%
    filter(IA_LABEL == 1) %>%
    select(-c(IA_LABEL)) %>%
    mutate(film=filmName, subType=subtitle)
  final_df <- rbind(final_df, df)
}

ID <- sapply(final_df[, 1], function(x) str_replace_all(x, '\\d+', ''))
index <- c()
for (i in 1:(length(ID)-3)) {
  if (all(ID[i]==ID[i+1], ID[i+1]==ID[i+2], ID[i+2]==ID[i+3])) {
    index <- append(index, i)
  }
}

for (i in index) {
  index <- append(index, i+1)
}

final_df <- final_df[!(rownames(final_df) %in% index), 2:7]

models <- lapply(names(final_df)[1:4], function(x) {
  aov(eval(substitute(i ~  film + subType, list(i = as.name(x)))), data = final_df)
})
model_summary <- sapply(models, summary)
names(model_summary) <- names(final_df)[1:4]
sink('../model_summary.txt')

summary_statistics <- final_df[, 1:6] %>% group_by(film, subType) %>%
                        summarise_all(
                          funs('mean'=mean, 'std'=sd)
                          )
  

write_csv(summary_statistics, '../descriptive_stats.csv')

data_df <- c()
for (fileName in fileNames) {
  
  fileName_without_ext <- fileName %>% str_split('\\.') %>% .[[1]] %>% .[1]
  filmName <- str_replace_all(fileName_without_ext, '[[:upper:]]', '')
  subtitle <- str_replace_all(fileName_without_ext, '[[:lower:]]', '')
  df <- read.delim(fileName) %>% as.data.frame() %>%
    select(RECORDING_SESSION_LABEL, IA_DWELL_TIME, IA_FIXATION_COUNT, `IA_DWELL_TIME_.`, `IA_FIXATION_.`, IA_LABEL) %>%
    mutate(film=filmName, subType=subtitle)
  data_df <- rbind(data_df, df) 
}

descriptive_data <- data_df[, 2:8] %>% group_by(IA_LABEL, film, subType) %>% summarise_all(funs('mean'=mean, 'std'=sd))

ratio_result <- data_df %>% select(-film) %>% select(IA_DWELL_TIME:subType) %>% group_by(IA_LABEL, subType) %>% summarise(IA_FIXATION_COUNT = sum(IA_FIXATION_COUNT))

proportion 
 
ratio_result %>% filter(IA_LABEL == 1) %>% select(IA_FIXATION_COUNT) / ratio_result %>% filter(IA_LABEL ==2) %>% select(IA_FIXATION_COUNT)
write.csv((ratio_result %>% filter(IA_LABEL == 1) %>% select(IA_FIXATION_COUNT) / ratio_result %>% filter(IA_LABEL ==2) %>% select(IA_FIXATION_COUNT) ) %>% select(IA_FIXATION_COUNT), '../test.csv')