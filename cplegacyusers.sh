#!/bin/bash

set -ex

rtmptdir="/home/$USER/tmptdir"
ltmptdir="/home/$USER/authkey_tmpdir"

host1="implusb2c-dev1-nfs"
host2="implusb2c-dev2-nfs"

mkdir -p "$ltmptdir"
rm -f $ltmptdir/*

# Fetch usernames from host1
usernames_host1=$(ssh $host1 ls -l /home | awk '{print $3}' | tail -n +2 | grep -Ev 'root|ubuntu|azureuser|lg_admin|www-upload|$USER|webscalebuilder' )

# Fetch usernames from host2
usernames_host2=$(ssh $host2 ls -l /home | awk '{print $3}' | tail -n +2| grep -Ev 'root|ubuntu|azureuser|lg_admin|www-upload|$USER|webscalebuilder' )

# Create usernames on host2
for username in $usernames_host1; do
    if [[ ! $usernames_host2 =~ $username ]]; then
        echo $username
        ssh $host2 sudo useradd -m -s /bin/bash -g www-data $username
        ssh $host2 sudo mkdir -p /home/$username/.ssh/
        ssh $host2 sudo chmod 0700 /home/$username/.ssh/
        ssh $host1 mkdir -p $rtmptdir && rm -rf $rtmptdir/*
        ssh $host2 mkdir -p $rtmptdir && rm -rf $rtmptdir/*
        ssh $host1 sudo cp /home/$username/.ssh/authorized_keys $rtmptdir/ && sudo chown $user:$user $rtmptdir/authorized_keys
        scp $host1:$rtmptdir/authorized_keys $ltmptdir/
        scp $ltmptdir/authorized_keys $host2:$rtmptdir/
        ssh $host2 sudo cp $rtmptdir/authorized_keys /home/$username/.ssh/authorized_keys && sudo chown $user:www-data $rtmptdir/authorized_keys && sudo chmod 0600 /home/$username/.ssh/authorized_keys && sudo chown -R $username:www-data /home/$username/.ssh/
    fi
done
