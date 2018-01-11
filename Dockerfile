FROM jenkins/jenkins:lts-alpine
MAINTAINER Hleb Rubanau <g.rubanau@gmail.com>

USER root

RUN apk add --update \
    sudo pwgen ansible py-pip terraform \
    && rm -rf /var/cache/apk/*

RUN pip install awscli --upgrade

# not sure what is in the alpine package -- we only need docker cli
ARG DOCKER_CLI_VERSION=17.03.2
RUN wget -q -O /tmp/docker.tgz \
        https://download.docker.com/linux/static/stable/$(uname -m)/docker-${DOCKER_CLI_VERSION}-ce.tgz \
    && cd /tmp              \
    && tar -xzf docker.tgz  \
    && cp docker/docker /usr/local/bin/docker-cli \
    && rm -rf /tmp/docker*

# hack to bypass issue with .dockercfg location, as we tend to run wrapped docker client via sudo
RUN touch /var/jenkins_home/.dockercfg \
    && chown jenkins:jenkins /var/jenkins_home/.dockercfg \
    && ln -sf /var/jenkins_home/.dockercfg /root/.dockercfg

# preconfigure admin user from secrets -- thanks https://technologyconversations.com/2017/06/16/automating-jenkins-docker-setup/
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
COPY security.groovy /usr/share/jenkins/ref/init.groovy.d/security.groovy 

# Viktor Farcic, thanks again! (see link above)
ADD plugins.txt /usr/share/jenkins_cloudbuilder/default_plugins_list.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins_cloudbuilder/default_plugins_list.txt

# install logging template, used in custom entrypoint
ADD jenkins_log.properties.template /usr/share/jenkins_cloudbuilder/jenkins_log.properties.template 

# now let's make it more friendly to local docker with proxied socked and possible uids mismatch
ADD sudoers /etc/sudoers
ADD docker_wrapper /usr/local/bin/docker 

# install custom entrypoint and make everything executable
ADD secrets_adapter.sh /usr/local/bin/jenkins_cloudbuilder_secrets_adapter.sh
RUN chmod 0544 /usr/local/bin/jenkins_cloudbuilder_secrets_adapter.sh 

COPY bootstrapper.sh /usr/share/jenkins_cloudbuilder/bootstrapper.sh

ADD entrypoint.sh /usr/local/bin/jenkins_cloudbuilder_entrypoint.sh
RUN bash -c 'for util in docker jenkins_cloudbuilder_entrypoint.sh ; do chown jenkins:jenkins /usr/local/bin/$util && chmod 0554 /usr/local/bin/$util ; done'

ENTRYPOINT [ "/usr/local/bin/jenkins_cloudbuilder_entrypoint.sh" ]

USER jenkins
ENV PRIVATE_REGISTRY_PORT=443
