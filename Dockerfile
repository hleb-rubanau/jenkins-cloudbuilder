FROM jenkins/jenkins:lts-alpine
MAINTAINER Hleb Rubanau <g.rubanau@gmail.com>

# install docker cli
USER root

ARG DOCKER_CLI_VERSION=17.03.2
RUN wget -q -O /tmp/docker.tgz \
        https://download.docker.com/linux/static/stable/$(uname -m)/docker-${DOCKER_CLI_VERSION}-ce.tgz \
    && cd /tmp              \
    && tar -xzf docker.tgz  \
    && cp docker/docker /usr/local/bin \
    && rm -rf /tmp/docker*

USER jenkins
