#!/bin/bash

set -e
function say() { echo "$*" >&2 ; }

ssh-keyscan github.com > github.com.keys
github_fingerprint=$(ssh-keygen -l -f github.com.keys | cut -f2 -d' ')

echo "Obtaining declared fingerprints from https://github.com"
wget -q -O github_fingerprints.html https://help.github.com/articles/github-s-ssh-key-fingerprints/ 

github_sha_lines=$( grep -A20 "These are GitHub's public key fingerprints" github_fingerprints.html \
		   | grep -A10 "These are the SHA256 hashes shown"  | grep SHA )
if [ !  -z "$github_fingerprint" ] && echo "$github_sha_lines" | grep -q "$github_fingerprint" ; then
    echo "Github fingerprint validated"
    cat github.com.keys >> /etc/ssh/ssh_known_hosts
else
    echo "Validation failed for github keys!"
    exit 1
fi

ssh-keyscan bitbucket.org bitbucket.com > bitbucket.com.keys
bitbucket_fingerprint=$( ssh-keygen -l -f bitbucket.com.keys | grep bitbucket.org | head -n1 )

BITBUCKET_FINGERPRINTS_URL="https://confluence.atlassian.com/bitbucket/ssh-keys-935365775.html"
wget -O bitbucket_fingerprints.html $BITBUCKET_FINGERPRINTS_URL
bitbucket_sha_lines=$( cat bitbucket_fingerprints.html | \
                        grep -A10 "The public key fingerprints for the Bitbucket server are" \
                        | grep code | grep SHA )

if [ ! -z "$bitbucket_fingerprint" ] && echo "$bitbucket_sha_lines" | grep -q "$bitbucket_fingerprint" ; then
   echo "Bitbucket fingerprint validated"
   cat bitbucket.com.keys >> /etc/ssh/ssh_known_hosts
else
   echo "Validation failed for bitbucket keys!"
   exit
fi  

#########################################
### GITLAB

say "Scanning gitlab.com" 
ssh-keyscan gitlab.com > gitlab.com.keys 2>/dev/null
gitlab_fingerprint=$( ssh-keygen -l -f gitlab.com.keys | head -n1 | cut -f2 -d' ' | cut -f2 -d: )


say "Obtaining announced fingerprints from gitlab.com"
GITLAB_FINGERPRINTS_URL="https://docs.gitlab.com/ee/user/gitlab_com/"
curl -s -o gitlab_fingerprints.html $GITLAB_FINGERPRINTS_URL

say "Comparing gitlab fingerprints"
gitlab_sha_lines=$( grep -A30 SHA256 gitlab_fingerprints.html | grep code | grep '<td>' | grep -v ':' | cut -f3 -d '>' | cut -f1 -d '<' | tee gitlab.sha.lines )


if [ ! -z "$gitlab_fingerprint" ] && echo "$gitlab_sha_lines" | grep -q "$gitlab_fingerprint" ; then
   say "Gitlab fingerprint validated"
   cat gitlab.com.keys >> /etc/ssh/ssh_known_hosts
else
   say "ERROR: Validation failed for gitlab keys!"
fi  

rm -f github_fingerprints.html
rm -f gitab_fingerprints.html
rm -f bitbucket_fingerprints.html
rm -f bitbucket.com.keys
rm -f github.com.keys
rm -f gitlab.com.keys

