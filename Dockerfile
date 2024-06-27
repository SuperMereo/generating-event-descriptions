FROM jupyter/datascience-notebook:ubuntu-20.04

RUN pip install allennlp==2.9.3 &&\
    R -e "install.packages(c('tidyverse', 'lme4', 'ggrepel', 'glmmTMB'), repos='http://cran.us.r-project.org')"
