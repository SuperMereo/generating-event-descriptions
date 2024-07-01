source("scripts/analysis/load_typicality.R")

zscore <- function(x) {
  (x - mean(x)) / sd(x)
}

typicality.item.means <- typicality %>%
  group_by(rater_id) %>%
  transform(typicality_zscore=zscore(rating)) %>%
  group_by(sentence) %>% 
  summarise(
    typicality_score=mean(rating), 
    typicality_zscore=mean(typicality_zscore)
  )
