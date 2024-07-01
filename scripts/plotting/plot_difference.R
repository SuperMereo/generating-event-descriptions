source("scripts/analysis/compute_typicality_scores.R")
source("scripts/analysis/load_difference.R")

library(tidyverse)

theme_set(theme_bw())

difference.item.means <- difference %>% 
  group_by(`Generation Method`, comparison, sentence1, sentence2, surprisal1, surprisal2, freq) %>% 
  summarise(`Mean Rating`=mean(rating))

difference.item.means$`Generation Method` <- ordered(
  difference.item.means$`Generation Method`,
  levels=rev(c(
    "Manual",
    "Corpus",
    "LM with PropBank senses",
    "LM with LM-generated senses"
  ))
)

ggplot(
  difference.item.means, 
  aes(x=`Generation Method`, y=`Mean Rating`, 
      fill=comparison, color=comparison)) +
  geom_jitter(width=0.15, size=0.5) +
  stat_summary(
    geom = "point",
    fun.y = "mean",
    col = "black",
    size = 6,
    shape=23
  ) +
  scale_shape_manual(values=c(24, 25)) +
  ylab("Mean Rating by Sentence Pair") +
  scale_fill_manual(
    name="Comparison Type",
    values=c(
      "#DF6607","#4092A8"
    ),
    labels=c("Different Sense", "Same Sense")
  ) +
  scale_color_manual(
    name="Comparison Type",
    values=c(
      "#DF6607","#4092A8"
    ),
    labels=c("Different Sense", "Same Sense")
  ) +
  coord_flip() +
  theme(
    axis.text.y=element_text(size=15, color="black"),
    axis.text.x=element_text(size=15, color="black"),
    axis.title.y=element_blank(),
    axis.title.x=element_text(size=20, color="black", face="bold"),
    legend.title=element_text(size=20, color="black", face="bold"),
    legend.text=element_text(size=12, color="black"),
    legend.position = "bottom"
  )

ggsave("results/point_difference.pdf", width=12, height=6)
ggsave("results/point_difference.png", width=12, height=6)

difference.item.means$`Generation Method` <- ordered(
  difference.item.means$`Generation Method`,
  levels=c(
    "Manual",
    "Corpus",
    "LM with PropBank senses",
    "LM with LM-generated senses"
  )
)

difference.item.means$min_surprisal <- pmin(
  difference.item.means$surprisal1, 
  difference.item.means$surprisal2
)
difference.item.means$max_surprisal <- pmax(
  difference.item.means$surprisal1, 
  difference.item.means$surprisal2
)
difference.item.means$mean_surprisal <- (difference.item.means$surprisal1 + difference.item.means$surprisal2) / 2

ggplot(
  filter(difference.item.means, !is.na(surprisal2)),
  # filter(
  #   difference.item.means, 
  #   `Generation Method` %in% c(
  #     "Corpus", 
  #     "LM with PropBank senses", 
  #     "LM with LM-generated senses", 
  #     "Manual (natural & typical)"
  #    )
  # ), 
  aes(
    x=mean_surprisal, 
    y=`Mean Rating`, 
    color=comparison, 
    #shape=comparison, 
    #color=`Generation Method`
  )
) +
  geom_jitter(alpha=0.5, width=0.15, size=0.5) +
  geom_smooth(method="lm", fullrange=T) +
  xlab("Mean Surprisal in Pair") +
  ylab("Mean Rating by Pair") +
  scale_color_manual(name="Comparison Type",
                     values=c(
    "#DF6607", "#4092A8", "#E43307","#E2C321", "#8EB37F", '#a65628', '#984ea3', "#E2B616"
  )) +
  #facet_wrap(~ `Generation Method`, scales="free_x",nrow=1) +
  #facet_wrap( ~ cut(min_surprisal, breaks=3), scales="free_x", nrow=1) +
  theme(
    axis.text.y=element_text(size=15, color="black"),
    axis.text.x=element_text(size=15, color="black"),
    axis.title.y=element_text(size=20, color="black", face="bold"),
    axis.title.x=element_text(size=20, color="black", face="bold"),
    legend.title=element_text(size=20, color="black", face="bold"),
    legend.text=element_text(size=12, color="black"),
    legend.position="bottom"
  )

ggsave("results/point_difference_surprisal.pdf", width=6, height=6)
ggsave("results/point_difference_surprisal.png", width=6, height=6)

difference.verb.means <- difference %>% 
  group_by(`Generation Method`, comparison, verb, freq) %>% 
  summarise(`Mean Rating`=mean(rating))

difference.verb.means$`Generation Method` <- ordered(
  difference.verb.means$`Generation Method`,
  levels=c(
    "Manual",
    "Corpus",
    "LM with PropBank senses",
    "LM with LM-generated senses"
  )
)

ggplot(
  #difference.verb.means,
  filter(
    difference.verb.means,
    `Generation Method` %in% c(
      "Corpus",
      "LM with PropBank senses",
      "LM with LM-generated senses",
      "Manual"
    )
  ),
  aes(
    x=freq, 
    y=`Mean Rating`, 
    color=comparison, 
    #shape=comparison, 
    #color=`Generation Method`
  )) +
  geom_jitter(alpha=0.5, width=0.15, size=0.5) +
  geom_smooth(method="lm",fullrange=TRUE) +
  xlab("Verb Frequency in Transitive") +
  ylab("Mean Rating by Verb") +
  scale_color_manual(
    name="Comparison Type",
    values=c(
    "#DF6607", "#4092A8", "#E43307","#E2C321", "#8EB37F", '#a65628', '#984ea3', "#E2B616"
  )) +
  #scale_x_log10() +
  #facet_wrap(~ `Generation Method`, nrow=1) +
  theme(
    axis.text.y=element_text(size=15, color="black"),
    axis.text.x=element_text(size=15, color="black"),
    axis.title.y=element_text(size=20, color="black", face="bold"),
    axis.title.x=element_text(size=20, color="black", face="bold"),
    legend.title=element_text(size=20, color="black", face="bold"),
    legend.text=element_text(size=12, color="black"),
    legend.position="bottom"
  )

ggsave("results/point_difference_frequency.pdf", width=6, height=6)
ggsave("results/point_difference_frequency.png", width=6, height=6)


difference.item.means <- merge(
  merge(
    difference.item.means, 
    typicality.item.means, 
    by.x = "sentence1", by.y="sentence"
  ),
  typicality.item.means, 
  by.x = "sentence2", by.y="sentence"
)

difference.item.means$mean_typicality <- (difference.item.means$typicality.x + difference.item.means$typicality.y) / 2

ggplot(
  #difference.verb.means,
  filter(
    difference.item.means,
    `Generation Method` %in% c(
      "Corpus",
      "LM with PropBank senses",
      "LM with LM-generated senses",
      "Manual"
    )
  ),
  aes(
    x=mean_typicality, 
    y=`Mean Rating`, 
    color=comparison, 
    #shape=comparison, 
    #color=`Generation Method`
  )) +
  geom_jitter(alpha=0.5, width=0.15, size=0.5) +
  geom_smooth(method="lm",fullrange=TRUE) +
  xlab("Mean Typicality in Pair") +
  ylab("Mean Rating by Pair") +
  scale_color_manual(
    name="Comparison Type",
    values=c(
      "#DF6607", "#4092A8", "#E43307","#E2C321", "#8EB37F", '#a65628', '#984ea3', "#E2B616"
    )) +
  #scale_x_log10() +
  #facet_wrap(~ `Generation Method`, nrow=1) +
  theme(
    axis.text.y=element_text(size=15, color="black"),
    axis.text.x=element_text(size=15, color="black"),
    axis.title.y=element_text(size=20, color="black", face="bold"),
    axis.title.x=element_text(size=20, color="black", face="bold"),
    legend.title=element_text(size=20, color="black", face="bold"),
    legend.text=element_text(size=12, color="black"),
    legend.position="bottom"
  )

ggsave("results/point_difference_typicality.pdf", width=6, height=6)
ggsave("results/point_difference_typicality.png", width=6, height=6)