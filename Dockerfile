FROM jenkins/jenkins:lts-alpine
MAINTAINER Hleb Rubanau <g.rubanau@gmail.com>

# install docker cli
USER root

RUN apk add --update sudo


ARG DOCKER_CLI_VERSION=17.03.2
RUN wget -q -O /tmp/docker.tgz \
        https://download.docker.com/linux/static/stable/$(uname -m)/docker-${DOCKER_CLI_VERSION}-ce.tgz \
    && cd /tmp              \
    && tar -xzf docker.tgz  \
    && cp docker/docker /usr/local/bin/docker-cli \
    && rm -rf /tmp/docker*

ARG TERRAFORM_VERSION=0.11.1
RUN wget -q -O /tmp/terraform.zip \
        https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && cd /tmp             \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/terraform \
    && rm -rf terraform*

# hack to bypass issue with .dockercfg location, as we tend to run wrapped docker client via sudo
RUN touch /var/jenkins/home/.dockercfg \
    && chown jenkins:jenkins /var/jenkins/home/.dockercfg \
    && ln -sf /root/.dockercfg /var/jenkins/home/.dockercfg

ADD sudoers /etc/sudoers
ADD docker_wrapper /usr/local/bin/docker
RUN bash -c 'for util in docker terraform ; do chown jenkins:jenkins /usr/local/bin/$util && chmod 0554 /usr/local/bin/$util ; done'

USER jenkins
