#!/bin/bash

#set -ex

rtmptdir="/home/$USER/tmptdir"
ltmptdir="/home/$USER/authkey_tmpdir"

#Replace host with original hostname
host1="host"
host2="host"

#Create local temporary directories
mkdir -p "$ltmptdir"
rm -f $ltmptdir/*

#Create remote temp directories on remote hosts
ssh $host1 "mkdir -p $rtmptdir && rm -rf $rtmptdir/*"
ssh $host2 "mkdir -p $rtmptdir && rm -rf $rtmptdir/*"

# Fetch usernames from host1
usernames_host1=$(ssh $host1 ls -l /home | awk '{print $3}' | tail -n +2 | grep -Ev 'root|ubuntu|azureuser|lg_admin|www-upload|$USER|webscalebuilder')

# Fetch usernames from host2
usernames_host2=$(ssh $host2 ls -l /home | awk '{print $3}' | tail -n +2| grep -Ev 'root|ubuntu|azureuser|lg_admin|www-upload|$USER|webscalebuilder')

# Create usernames on host2 that exist on host1 but not on host2
for username in $usernames_host1; do
    if [[ ! $usernames_host2 =~ $username ]]; then
    echo "Adding user $username on $host2"
    ssh $host2 "sudo useradd -m -s /bin/bash -g www-data $username && sudo mkdir -p /home/$username/.ssh/ && sudo chmod 0700 /home/$username/.ssh/"
    echo "Taking copy of auth key file on host1"
    ssh $host1 "sudo cp /home/$username/.ssh/authorized_keys $rtmptdir/ && sudo chown $USER:$USER $rtmptdir/authorized_keys"
    echo "pulling auth key to local"
    scp $host1:$rtmptdir/authorized_keys $ltmptdir/
    echo "pushing auth key to remote host2"
    scp $ltmptdir/authorized_keys $host2:$rtmptdir/
    echo "replacing authkey on host2"
    ssh $host2 "sudo mv $rtmptdir/authorized_keys /home/$username/.ssh/authorized_keys && sudo chmod 0600 /home/$username/.ssh/authorized_keys && sudo chown -R $username:www-data /home/$username/.ssh"
    fi
done

#Remove temp directories
rm -rf $ltmptdir
ssh $host1 rm -rf $rtmptdir
ssh $host2 rm -rf $rtmptdir