FROM debian:bookworm
RUN apt-get update -y && apt-get install wget tar -y
RUN mkdir /opt/portainer
RUN wget https://github.com/portainer/portainer/releases/download/2.19.4/portainer-2.19.4-linux-amd64.tar.gz \
    && tar -xzvf portainer-2.19.4-linux-amd64.tar.gz -C /opt/ \
    && rm portainer-2.19.4-linux-amd64.tar.gz
