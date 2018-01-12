#!/bin/bash

set -e

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

BITBUCKET_FINGERPRINTS_URL="https://confluence.atlassian.com/bitbucket/troubleshoot-ssh-issues-271943403.html"
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

rm -f github_fingerprints.html
rm -f bitbucket_fingerprints.html
rm -f bitbucket.com.keys
rm -f github.com.keys

