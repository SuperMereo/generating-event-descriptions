source("scripts/analysis/load_typicality.R")

library(tidyverse)

theme_set(theme_bw())

typicality.item.means <- typicality %>% 
  group_by(`Generation Method`, sentence, freq, surprisal) %>% 
  summarise(`Mean Rating`=mean(rating))

typicality.item.means$`Generation Method` <- ordered(
  typicality.item.means$`Generation Method`,
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
  typicality.item.means, 
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
  ylab("Mean Typicality Rating") +
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


ggsave("results/point_typicality.pdf", width=12, height=6)
ggsave("results/point_typicality.png", width=12, height=6)

typicality.item.means$`Generation Method` <- ordered(
  typicality.item.means$`Generation Method`,
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
  typicality.item.means,
  aes(x=surprisal, y=`Mean Rating`)
) +
  geom_jitter(alpha=0.5, width=0.15, size=0.5, color="black") +
  geom_smooth(method="lm") +
  xlab("Surprisal") +
  ylab("Mean Typicality Rating") +
  scale_color_manual(values=c(
    "#E43307","#E2C321", "#8EB37F", "#4092A8","#DF6607",'#a65628', '#984ea3', "#E2B616"
  )) +
  theme(
    axis.text.y=element_text(size=15, color="black"),
    axis.text.x=element_text(size=15, color="black"),
    axis.title.y=element_text(size=20, color="black", face="bold"),
    axis.title.x=element_text(size=20, color="black", face="bold"),
    legend.title=element_text(size=20, color="black", face="bold"),
    legend.text=element_text(size=12, color="black"),
    legend.position="none"
  )

ggplot(
  typicality.item.means,
  # filter(
  #   typicality.item.means,
  #   `Generation Method` %in% c(
  #     "Corpus",
  #     "LM with PropBank senses",
  #     "LM with LM-generated senses",
  #     "Manual (natural & typical)",
  #     "Manual (natural & atypical)"
  #    )
  # ),
  aes(x=surprisal, y=`Mean Rating`, color=`Generation Method`)
) +
  geom_jitter(alpha=0.5, width=0.15, size=0.5, color="black") +
  geom_smooth(method="lm") +
  xlab("Surprisal") +
  ylab("Mean Typicality Rating") +
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

ggsave("results/point_typicality_surprisal.pdf", width=12, height=7)
ggsave("results/point_typicality_surprisal.png", width=12, height=7)


ggplot(
  #typicality.item.means,
  filter(
    typicality.item.means,
    `Generation Method` %in% c(
      "Corpus",
      "LM with PropBank senses",
      "LM with LM-generated senses",
      "Manual (natural & typical)",
      "Manual (natural & atypical)"
     )
  ),
  aes(x=surprisal, y=`Mean Rating`, color=`Generation Method`)
) +
  geom_jitter(alpha=0.5, width=0.15, size=0.5, color="black") +
  geom_smooth(method="lm") +
  xlab("Surprisal") +
  ylab("Mean Typicality Rating") +
  scale_color_manual(values=c(
    "#E43307","#E2C321", "#8EB37F", "#4092A8","#DF6607",'#a65628', '#984ea3', "#E2B616"
  )) +
  facet_wrap(~ `Generation Method`, scales="free_x",nrow=1) +
  theme(
    axis.text.y=element_text(size=15, color="black"),
    axis.text.x=element_text(size=15, color="black", angle=45, hjust=1),
    axis.title.y=element_text(size=20, color="black", face="bold"),
    axis.title.x=element_text(size=20, color="black", face="bold"),
    legend.title=element_text(size=20, color="black", face="bold"),
    legend.text=element_text(size=12, color="black"),
    legend.position="none"
  )

ggsave("results/point_typicality_surprisal_subset.pdf", width=14, height=4)
ggsave("results/point_typicality_surprisal_subset.png", width=14, height=4)


typicality.verb.means <- typicality %>% 
  group_by(`Generation Method`, verb, freq) %>% 
  summarise(`Mean Rating`=mean(rating))

typicality.verb.means$`Generation Method` <- ordered(
  typicality.verb.means$`Generation Method`,
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
  #typicality.verb.means,
  filter(
    typicality.verb.means,
    `Generation Method` %in% c(
      "Corpus",
      "LM with PropBank senses",
      "LM with LM-generated senses"
    )
  ),
  aes(x=freq, y=`Mean Rating`)) +
  geom_jitter(alpha=0.5, width=0.15, size=0.5, color="black") +
  geom_smooth(method="lm",fullrange=TRUE, color="#4092A8") +
  xlab("Verb Frequency in Transitive") +
  ylab("Mean Rating by Verb") +
  #scale_x_log10() +
  theme(
    axis.text.y=element_text(size=15, color="black"),
    axis.text.x=element_text(size=15, color="black"),
    axis.title.y=element_text(size=20, color="black", face="bold"),
    axis.title.x=element_text(size=20, color="black", face="bold"),
    legend.title=element_text(size=20, color="black", face="bold"),
    legend.text=element_text(size=12, color="black"),
    legend.position="none"
  )

ggsave("results/point_typicality_freq.png", width=4, height=4)

ggplot(
  typicality.verb.means,
  # filter(
  #   typicality.verb.means,
  #   `Generation Method` %in% c(
  #     "Corpus",
  #     "LM with PropBank senses",
  #     "LM with LM-generated senses",
  #     "Manual (natural & typical)"
  #   )
  # ),
  aes(x=freq, y=`Mean Rating`, color=`Generation Method`)) +
  geom_jitter(alpha=0.5, width=0.15, size=0.5, color="black") +
  geom_smooth(method="lm",fullrange=TRUE) +
  xlab("Verb Frequency in Transitive") +
  ylab("Mean Typicality Rating") +
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

ggsave("results/point_typicality_freq_by_method.pdf", width=12, height=7)
ggsave("results/point_typicality_freq_by_method.png", width=12, height=7)
