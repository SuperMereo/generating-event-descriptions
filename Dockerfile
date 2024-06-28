FROM jupyter/datascience-notebook:notebook-6.5.4

RUN pip install --upgrade pip cmdstanpy==1.1.0 arviz==0.15.1 torch==2.0.1 'transformers[torch]' &&\
    python -c "from cmdstanpy import install_cmdstan; install_cmdstan(version='2.35')"
