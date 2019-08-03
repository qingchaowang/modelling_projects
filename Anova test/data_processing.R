# setwd('qingchaowan/modeling_project/Anova test/')
setwd('Data/')
fileNames <- list.files()

# Please install this package for the first time using it
# install.packages('readr')
require(readr)
# df <- read_csv('bjCH.csv')
require(dplyr)
require(stringr)
# df %>% names()
# df %>% select(IA_DWELL_TIME, `IA_DWELL_TIME_%`, IA_FIXATION_COUNT, `IA_FIXATION_%`)
# # strsplit('bjCH', split='[[:upper:]]')
# all_name = 'bjCH.csv'
# str_split(all_name, '.')
# all_name <- all_name %>% str_split('\\.') %>% .[[1]] %>% .[1]
# 
# filmName <- str_replace_all(all_name, '[[:upper:]]', '')
# subtitle <- str_replace_all(all_name, '[[:upper:]]', '')

final_df <- c()
for (fileName in fileNames) {
  
  fileName_without_ext <- fileName %>% str_split('\\.') %>% .[[1]] %>% .[1]
  filmName <- str_replace_all(fileName_without_ext, '[[:upper:]]', '')
  subtitle <- str_replace_all(fileName_without_ext, '[[:lower:]]', '')
  df <- read_csv(fileName) %>% 
    select(RECORDING_SESSION_LABEL, IA_DWELL_TIME, `IA_DWELL_TIME_%`,
           IA_FIXATION_COUNT, `IA_FIXATION_%`) %>%
    mutate(film=filmName, subType=subtitle)
  final_df <- rbind(final_df, df)
}

ID <- sapply(tmp, function(x) str_replace_all(x, '\\d+', ''))
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
  # tmp = substitute(i ~  film + subType, list(i = as.name(x)))
  aov(eval(substitute(i ~  film + subType, list(i = as.name(x)))), data = final_df)
})

sink('model_summary.txt')
model_summary <- sapply(models, summary)
names(model_summary) <- names(final_df)[1:4]
print(model_summary)
sink()

tmp = substitute(i ~  film + subType, list(i = as.name('IA_DWELL_TIME')))
IA_DWELL_TIME.aov2 <- aov(eval(tmp), data=final_df)
summary(IA_DWELL_TIME.aov2)

summary_statistics <- final_df[, 1:6] %>% group_by(film, subType) %>%
                        summarise_all(
                          funs('mean'=mean, 'std'=sd)
                          )


write_csv(summary_statistics, 'descriptive_stats.csv')



