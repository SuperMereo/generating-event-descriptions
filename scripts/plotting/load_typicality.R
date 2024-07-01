library(readr)

typicality.manual <- read_csv("data/preprocessed/typicality_manual.csv")
typicality.llama.propbanksenses <- read_csv("data/preprocessed/typicality_llama-propbanksenses.csv")
typicality.llama.llamasenses <- read_csv("data/preprocessed/typicality_llama-llamasenses.csv")
typicality.reddit <- read_csv("data/preprocessed/typicality_reddit.csv")

typicality.manual <- typicality.manual %>% filter(sentence_type == "target")

typicality.manual$`Generation Method` <- paste0(
  "Manual (", 
  typicality.manual$naturalness, 
  " & ", 
  typicality.manual$typicality, 
  ")"
)
typicality.llama.propbanksenses$`Generation Method` <- ifelse(
  typicality.llama.propbanksenses$sentence_type == "calibration",
  paste0("Manual (", typicality.llama.propbanksenses$naturalness, " & ", typicality.llama.propbanksenses$typicality, ")"),
  "LM with PropBank senses")
typicality.llama.llamasenses$`Generation Method` <- ifelse(
  typicality.llama.llamasenses$sentence_type == "calibration",
  paste0("Manual (", typicality.llama.llamasenses$naturalness, " & ", typicality.llama.llamasenses$typicality, ")"),
  "LM with LM-generated senses"
)
typicality.reddit$`Generation Method` <- ifelse(
  typicality.reddit$sentence_type == "calibration",
  paste0("Manual (", typicality.reddit$naturalness, " & ", typicality.reddit$typicality, ")"),
  "Corpus"
)

typicality <- do.call(
  "rbind",
  list(
    typicality.manual,
    typicality.llama.propbanksenses,
    typicality.llama.llamasenses,
    typicality.reddit
  )
)