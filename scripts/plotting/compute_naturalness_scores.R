source("scripts/analysis/load_naturalness.R")

zscore <- function(x) {
  (x - mean(x)) / sd(x)
}

naturalness.item.means.zscored <- naturalness %>%
  filter(`Generation Method` %in% c(
    "Manual (natural & typical)", "Manual (natural & atypical)",
    "Manual (unnatural & typical)", "Manual (unnatural & atypical)"
  )) %>%
  group_by(rater_id) %>%
  transform(naturalness_zscore=zscore(rating)) %>%
  group_by(sentence) %>%
  summarise(
    naturalness_score=mean(naturalness_zscore)
  )
