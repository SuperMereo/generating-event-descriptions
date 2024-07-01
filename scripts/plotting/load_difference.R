library(readr)

difference.manual <- read_csv("data/preprocessed/difference_manual.csv")
difference.llama.propbanksenses <- read_csv("data/preprocessed/difference_llama-propbanksenses.csv")
difference.llama.llamasenses <- read_csv("data/preprocessed/difference_llama-llamasenses.csv")
difference.reddit <- read_csv("data/preprocessed/difference_reddit.csv")

difference.manual$`Generation Method` <- "Manual"

difference.llama.propbanksenses$`Generation Method` <- ifelse(
  difference.llama.propbanksenses$pair_type %in% c("calibration", "filler"),
  "Manual",
  "LM with PropBank senses")
difference.llama.llamasenses$`Generation Method` <- ifelse(
  difference.llama.llamasenses$pair_type %in% c("calibration", "filler"),
  "Manual",
  "LM with LM-generated senses"
)
difference.reddit$`Generation Method` <- ifelse(
  difference.reddit$pair_type %in% c("calibration", "filler"),
  "Manual",
  "Corpus"
)

difference <- do.call(
  "rbind",
  list(
    difference.manual,
    filter(difference.llama.propbanksenses, `Generation Method` != "Manual"),
    filter(difference.llama.llamasenses, `Generation Method` != "Manual"),
    filter(difference.reddit, `Generation Method` != "Manual")
  )
)