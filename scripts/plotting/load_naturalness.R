library(readr)

naturalness.manual <- read_csv("data/preprocessed/naturalness_manual.csv")
naturalness.llama.propbanksenses <- read_csv("data/preprocessed/naturalness_llama-propbanksenses.csv")
naturalness.llama.llamasenses <- read_csv("data/preprocessed/naturalness_llama-llamasenses.csv")
naturalness.reddit <- read_csv("data/preprocessed/naturalness_reddit.csv")

naturalness.manual <- naturalness.manual %>% filter(sentence_type == "target")

naturalness.manual$`Generation Method` <- paste0(
  "Manual (", 
  naturalness.manual$naturalness, 
  " & ", 
  naturalness.manual$typicality, 
  ")"
)
naturalness.llama.propbanksenses$`Generation Method` <- ifelse(
  naturalness.llama.propbanksenses$sentence_type == "calibration",
  paste0("Manual (", naturalness.llama.propbanksenses$naturalness, " & ", naturalness.llama.propbanksenses$typicality, ")"),
  "LM with PropBank senses")
naturalness.llama.llamasenses$`Generation Method` <- ifelse(
  naturalness.llama.llamasenses$sentence_type == "calibration",
  paste0("Manual (", naturalness.llama.llamasenses$naturalness, " & ", naturalness.llama.llamasenses$typicality, ")"),
  "LM with LM-generated senses"
)
naturalness.reddit$`Generation Method` <- ifelse(
  naturalness.reddit$sentence_type == "calibration",
  paste0("Manual (", naturalness.reddit$naturalness, " & ", naturalness.reddit$typicality, ")"),
  "Corpus"
)

naturalness <- do.call(
  "rbind",
  list(
    naturalness.manual,
    naturalness.llama.propbanksenses,
    naturalness.llama.llamasenses,
    naturalness.reddit
  )
)
