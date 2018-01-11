#!/bin/bash

set -e 
function say() {
    echo "[$0] $*" >&2
}

function die() {
    say "ERROR: $*" ; exit 1;
}

# self-provision ssh key
SSHKEY=~/.ssh/id_rsa
if [ ! -e $SSHKEY ]; then
    SSHIDENTITY="jenkins@$(hostname)"
    say "SSH key not found, generating (identity: $SSHIDENTITY)"
    mkdir -p $(dirname $SSHKEY)
    ssh-keygen -t rsa -f $SSHKEY -q -N "" -C "$SSHIDENTITY" 
    chmod 0600 $SSHKEY
    unset SSHIDENTITY
else
    say "Existing SSH key found at $SSHKEY"
fi
unset SSHKEY

# dynamically setup logging
LOGPROP_FILE=/tmp/jenkins_log.properties 
JENKINS_LOGLEVEL=${JENKINS_LOGLEVEL:-INFO}
sed -e s/JENKINS_LOGLEVEL/${JENKINS_LOGLEVEL}/g \
    /usr/share/jenkins_cloudbuilder/jenkins_log.properties.template \
    > $LOGPROP_FILE

export JAVA_OPTS="$JAVA_OPTS -Djava.util.logging.config.file=$LOGPROP_FILE "

# run custom adapter for insecure secrets injection
sudo jenkins_cloudbuilder_secrets_adapter.sh 

if [ ! -z "$JENKINS_PROVISIONING_FILE" ]; then
  say "Found JENKINS_PROVISIONING_FILE=$JENKINS_PROVISIONING_FILE"
  PROVISION_HOOK=/usr/share/jenkins_cloudbuilder/bootstrapper.sh
  say "Invoking bootstrapper $PROVISION_HOOK"
  pushd $(pwd)
  source $PROVISION_HOOK
  popd 
  unset JENKINS_PROVISIONING_FILE
fi
#TODO: prepopulate jobs when needed

# pass execution to upstream entrypoint
exec /bin/tini -- /usr/local/bin/jenkins.sh $*
