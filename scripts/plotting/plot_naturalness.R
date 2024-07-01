source("scripts/analysis/load_naturalness.R")
source("scripts/analysis/compute_naturalness_scores.R")
source("scripts/analysis/compute_typicality_scores.R")

library(tidyverse)

theme_set(theme_bw())

ggplot(
  naturalness.item.means.zscored, 
  aes(x=naturalness_score)) +
  geom_histogram(fill="#4092A8", color="black", bins=10) +
  geom_hline(yintercept=0) +
  xlab("Naturalness Score") +
  ylab("# of Manually Generated Items") +
  theme(
    axis.text.y=element_text(size=15, color="black"),
    axis.text.x=element_text(size=15, color="black"),
    axis.title=element_text(size=20, color="black", face="bold"),
    legend.title=element_text(size=20, color="black", face="bold"),
    legend.text=element_text(size=12, color="black"),
    legend.position="none"
  )

ggsave("results/hist_naturalness_zscore.pdf", width=12, height=6)
ggsave("results/hist_naturalness_zscore.png", width=12, height=6)

naturalness.item.means <- naturalness %>% 
  group_by(`Generation Method`, sentence, freq, surprisal) %>% 
  summarise(`Mean Rating`=mean(rating))

naturalness.item.means$`Generation Method` <- ordered(
  naturalness.item.means$`Generation Method`,
  levels=rev(c(
    "Manual (natural & typical)",
    "Manual (natural & atypical)",
    "Manual (unnatural & typical)",
    "Manual (unnatural & atypical)",
    "Corpus",
    "LM with PropBank senses",
    "LM with LM-generated senses"
  ))
)

ggplot(
  naturalness.item.means, 
  aes(x=`Generation Method`, y=`Mean Rating`, 
      fill=`Generation Method`)) +
  geom_jitter(alpha=0.3, width=0.15, size=0.5) +
  stat_summary(
    geom = "point",
    fun.y = "mean",
    col = "black",
    size = 6,
    shape=23
  ) +
  ylab("Mean Rating by Sentence") +
  scale_fill_manual(values=c(
    "#E43307","#E2C321", "#8EB37F", "#4092A8","#DF6607",'#a65628', '#984ea3', "#E2B616"
  )) +
  coord_flip() +
  theme(
    axis.text.y=element_text(size=15, color="black"),
    axis.text.x=element_text(size=15, color="black"),
    axis.title.y=element_blank(),
    axis.title.x=element_text(size=20, color="black", face="bold"),
    legend.title=element_text(size=20, color="black", face="bold"),
    legend.text=element_text(size=12, color="black"),
    legend.position="none"
  )

ggsave("results/point_naturalness.pdf", width=12, height=6)
ggsave("results/point_naturalness.png", width=12, height=6)

naturalness.item.means$`Generation Method` <- ordered(
  naturalness.item.means$`Generation Method`,
  levels=c(
    "Manual (natural & typical)",
    "Manual (natural & atypical)",
    "Manual (unnatural & typical)",
    "Manual (unnatural & atypical)",
    "Corpus",
    "LM with PropBank senses",
    "LM with LM-generated senses"
  )
)

ggplot(
  naturalness.item.means,
  # filter(
  #   naturalness.item.means,
  #   `Generation Method` %in% c(
  #     "Corpus",
  #     "LM with PropBank senses",
  #     "LM with LM-generated senses",
  #     "Manual (natural & typical)"
  #    )
  # ),
  aes(x=surprisal, y=`Mean Rating`, color=`Generation Method`)) +
  geom_jitter(alpha=0.5, width=0.15, size=0.5, color="black") +
  geom_smooth(method="lm") +
  xlab("Surprisal") +
  ylab("Mean Rating by Sentence") +
  scale_color_manual(values=c(
    "#E43307","#E2C321", "#8EB37F", "#4092A8","#DF6607",'#a65628', '#984ea3', "#E2B616"
  )) +
  facet_wrap(~ `Generation Method`, scales="free_x",nrow=2) +
  theme(
    axis.text.y=element_text(size=15, color="black"),
    axis.text.x=element_text(size=15, color="black"),
    axis.title.y=element_text(size=20, color="black", face="bold"),
    axis.title.x=element_text(size=20, color="black", face="bold"),
    legend.title=element_text(size=20, color="black", face="bold"),
    legend.text=element_text(size=12, color="black"),
    legend.position="none"
  )

ggsave("results/point_naturalness_surprisal.pdf", width=12, height=8)
ggsave("results/point_naturalness_surprisal.png", width=12, height=8)

naturalness.verb.means <- naturalness %>% 
  group_by(`Generation Method`, verb, freq) %>% 
  summarise(`Mean Rating`=mean(rating))

naturalness.verb.means$`Generation Method` <- ordered(
  naturalness.verb.means$`Generation Method`,
  levels=c(
    "Manual (natural & typical)",
    "Manual (natural & atypical)",
    "Manual (unnatural & typical)",
    "Manual (unnatural & atypical)",
    "Corpus",
    "LM with PropBank senses",
    "LM with LM-generated senses"
  )
)

ggplot(
  naturalness.verb.means,
  # filter(
  #   naturalness.verb.means,
  #   `Generation Method` %in% c(
  #     "Corpus",
  #     "LM with PropBank senses",
  #     "LM with LM-generated senses",
  #     "Manual (natural & typical)"
  #    )
  # ),
  aes(x=freq, y=`Mean Rating`, color=`Generation Method`)) +
  geom_jitter(alpha=0.5, width=0.15, size=0.5, color="black") +
  geom_smooth(method="lm",fullrange=TRUE) + #, formula="y ~ log(x)") +
  xlab("Verb Frequency in Transitive") +
  ylab("Mean Rating by Verb") +
  scale_color_manual(values=c(
    "#E43307","#E2C321", "#8EB37F", "#4092A8","#DF6607",'#a65628', '#984ea3', "#E2B616"
  )) +
  #scale_x_log10() +
  facet_wrap(~ `Generation Method`, nrow=2) +
  theme(
    axis.text.y=element_text(size=15, color="black"),
    axis.text.x=element_text(size=15, color="black"),
    axis.title.y=element_text(size=20, color="black", face="bold"),
    axis.title.x=element_text(size=20, color="black", face="bold"),
    legend.title=element_text(size=20, color="black", face="bold"),
    legend.text=element_text(size=12, color="black"),
    legend.position="none"
  )

ggsave("results/point_naturalness_freq.pdf", width=12, height=8)
ggsave("results/point_naturalness_freq.png", width=12, height=8)

naturalness.item.means <- merge(
  naturalness.item.means,typicality.item.means
)

ggplot(
  naturalness.item.means,
  # filter(
  #   naturalness.verb.means,
  #   `Generation Method` %in% c(
  #     "Corpus",
  #     "LM with PropBank senses",
  #     "LM with LM-generated senses",
  #     "Manual (natural & typical)"
  #    )
  # ),
  aes(x=typicality_score, y=`Mean Rating`)) +
  geom_jitter(alpha=0.5, width=0.15, size=0.5, color="black") +
  geom_smooth(fullrange=TRUE, color="#4092A8") + #, formula="y ~ log(x)") +
  xlab("Mean Typicality Rating") +
  ylab("Mean Naturalness Rating") +
  theme(
    axis.text.y=element_text(size=15, color="black"),
    axis.text.x=element_text(size=15, color="black"),
    axis.title.y=element_text(size=20, color="black", face="bold"),
    axis.title.x=element_text(size=20, color="black", face="bold"),
    legend.title=element_text(size=20, color="black", face="bold"),
    legend.text=element_text(size=12, color="black"),
    legend.position="none"
  )

ggsave("results/point_naturalness_typicality.pdf", width=8, height=4)
ggsave("results/point_naturalness_typicality.png", width=8, height=4)

