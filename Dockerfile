FROM continuumio/miniconda3:latest

COPY environment.yml /tmp/environment.yml
RUN conda env create -f /tmp/environment.yml && conda clean -a -y

ENV PATH=/opt/conda/envs/hw3-pipeline/bin:$PATH
WORKDIR /data
