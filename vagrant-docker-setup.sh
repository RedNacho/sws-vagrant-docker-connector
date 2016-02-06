#!/bin/bash

#Parameters:
# - The name to give the docker-machine (will be destroyed if it already exists)
# - The location of the Vagrantfile for the vagrant box
# - (Optional) The network adapter on the vagrant box from which we can acquire
#   an IP address visible to the host (the vagrant box must be configured so
#   that this is possible, e.g. with a private network). If omitted, eth1.
#   Set this to --vagrant-ssh to rely on the vagrant ssh config for the IP
#   address and SSH port instead (this may require docker ports to be forwarded
#   to the host IP).

#Change to the vagrant directory
cd "$2"

#Bring the vagrant box up
vagrant up

#Load the vagrant SSH config
sshconfig=$(vagrant ssh-config)

#Pull out the vagrant SSH key from the config
vagrant_ssh_key=$(echo "${sshconfig}" | grep "^\s*IdentityFile\s" | sed -e "s/^\s*IdentityFile //")

#Pull out the vagrant user from the config
vagrant_user=$(echo "${sshconfig}" | grep "^\s*User\s" | sed -e "s/^\s*User //")

#Strip out quote marks from SSH key path (otherwise it doesn't work...)
vagrant_ssh_key=$(echo "${vagrant_ssh_key}" | sed -e "s/\"//g")

if [ "$3" == "--vagrant-ssh" ]
then

#Get the IP and SSH port of the vagrant box from the vagrant ssh-config. This
#may be the host IP and a forwarded port, in which case docker ports must
#also be forwarded.

vagrant_ip=$(echo "${sshconfig}" | grep "^\s*HostName\s" | sed -e "s/^\s*HostName //")
vagrant_ssh_port=$(echo "${sshconfig}" | grep "^\s*Port\s" | sed -e "s/^\s*Port //")

else

#Pull out the direct IP and SSH port of the vagrant box. (We can't use the
#host port mapping, because docker-machine will try to communicate with
#the docker host on port 2376. We don't want to require that this port is
#forwarded from the vagrant box, as we can only do this for one docker host
#at a time.)

vagrant_direct_ssh=$(vagrant ssh -c "ip address show ${3:-eth1} | grep 'inet ' | sed -e 's/^.*inet /ip=/' -e 's/\/.*$//' && grep Port /etc/ssh/sshd_config | sed -e 's/Port /port=/'")

#Get rid of spurious carriage returns...
vagrant_direct_ssh=$(echo "${vagrant_direct_ssh}" | sed -e "s/\r//")

vagrant_ip=$(echo "${vagrant_direct_ssh}" | grep "^ip=" | sed -e "s/^ip=//")
vagrant_ssh_port=$(echo "${vagrant_direct_ssh}" | grep "^port=" | sed -e "s/^port=//")

fi

#Remove existing docker-machine
docker-machine rm -f "$1"

#Add the vagrant box to docker-machine
docker-machine create -d generic --generic-ip-address "${vagrant_ip}" --generic-ssh-key "${vagrant_ssh_key}" --generic-ssh-user ${vagrant_user} --generic-ssh-port ${vagrant_ssh_port} "$1"

#Print the environment
docker-machine env "$1"
