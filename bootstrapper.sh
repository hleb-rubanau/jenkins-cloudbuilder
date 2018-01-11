#!/bin/bash

set -e

if [ -z "$JENKINS_PROVISIONING_FILE" ]; then
    die "File provisioning script invoked without JENKINS_PROVISIONING_FILE being set!"
fi


PROVISION_DIR=${PROVISION_DIR:-/var/jenkins_home/system/provisioning}
CURDIR=$(pwd)
mkdir -pv $PROVISION_DIR/files
pushd $PROVISION_DIR

target_file="files/$(basename $JENKINS_PROVISIONING_FILE )"

if [[ "$JENKINS_PROVISIONING_FILE" = s3://* ]]; then
    say "DOWNLOADING $JENKINS_PROVISIONING_FILE -> ./$target_file " 
    aws s3 cp $JENKINS_PROVISIONING_FILE ./$target_file
elif [[ "$JENKINS_PROVISIONING_FILE" = http*://* ]]; then
    say "DOWNLOADING $JENKINS_PROVISIONING_FILE -> ./$target_file " 
    wget -q -O ./$target_file $JENKINS_PROVISIONING_FILE 
else
    if [ -e "$JENKINS_PROVISIONING_FILE" ]; then
        if [ ! "$(dirname $JENKINS_PROVISIONING_FILE )" = $(pwd) ]; then
            say "COPYING $JENKINS_PROVISIONING_FILE ./$target_file"
            cp -v $JENKINS_PROVISIONING_FILE ./$target_file
        fi
    fi
fi

if [[ "$target_file" = *.tgz ]]; then

    newfile_md5sum=$(md5sum $PWD/$target_file | cut -f1 -d' ')
    if [ -s md5sums.txt ] ; then
        oldfile_md5sum=$(tail -n1 md5sums.txt | cut -f3 -d' ')
    else 
        oldfile_md5sum=""
    fi

    if [ "${oldfile_md5sum}" = "${newfile_md5sum}" ]; then
        say "SAME FILE ALREADY DEPLOYED: $oldfile_md5sum"
    else
        echo "$(date +'%F %T') $newfile_md5sum $JENKINS_PROVISIONING_FILE $target_file" >> md5sums.txt
        say "UNPACKING $target_file"

        ### TODO: for some reason it does not exclude files from archive! fix later   
        exclusion_pattern=./${PWD#/var/jenkins_home/}/ # without leading slash
        ( tar -xzvf $target_file -C /var/jenkins_home --exclude=$exclusion_pattern  || die "Extraction failure" ) 2>&1 | tee last_provision.log
        say "PROVISIONING FINISHED"
    
        POSTPROVISION_DIR=/var/jenkins_home/system/postprovision_hooks
        if [ -e $POSTPROVISION_DIR ]; then
            pushd $POSTPROVISION_DIR
            for script in $( find -type f -perm /u+x ); do
                pushd $POSTPROVISION_DIR
                say "POSTPROVISION: $(pwd)/$script"
                $script
                popd
            done

            popd
        fi
    fi
else
    die "Unkown format of provisioning file: $JENKINS_PROVISIONING_FILE "
fi

popd
