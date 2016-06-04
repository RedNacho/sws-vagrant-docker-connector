#!/bin/bash

#Parameters:
# - The name to give the docker-machine (will be destroyed if it already exists)
# - The location of the Vagrantfile for the vagrant box
# - (Optional) The network adapter on the vagrant box from which we can acquire
#   an IP address visible to the host (the vagrant box must be configured so
#   that this is possible, e.g. with a private network). If omitted, eth1.
#   Set this to --vagrant-ssh to rely on the vagrant ssh config for the IP
#   address and SSH port instead (this may require docker ports to be forwarded
#   to the host IP). Set this to --direct-ssh to use the default and move on to
#   more arguments.
# - (Optional) The port to use to connect to the Docker daemon. This may depend
#   on the way that SSH communication is established with the vagrant box. By
#   default, this will be the port directly on the box, with no forwarding to
#   the host required. If --vagrant-ssh has been specified, this may require the
#   port to be forwarded to the host, depending on the vagrant SSH config. NB
#   This parameter requires docker-machine's --generic-engine-port arg, which
#   may not exist on older versions. It also appears that this arg has the dual
#   effect of both specifying the communication port with docker, AND the port
#   that docker is exposed on when it is configured on the VM. So you can cannot
#   currently start docker on port 2376, forward this port to port XXXX, and
#   then tell docker-machine to use port XXXX - the port number on the VM and
#   the host must match. Set this to --default-docker-port to use the default
#   and move on to more arguments.
# - (Optional) Any further arguments will be passed to docker-machine.

#Change to the vagrant directory
cd "$2"

#Bring the vagrant box up
vagrant up

#Load the vagrant SSH config
sshconfig=$(vagrant ssh-config)

#Pull out the vagrant SSH key from the config
vagrant_ssh_key=$(echo "${sshconfig}" | grep "^\s*IdentityFile\s" | sed -e "s/^[[:blank:]]*IdentityFile //")

#Pull out the vagrant user from the config
vagrant_user=$(echo "${sshconfig}" | grep "^\s*User\s" | sed -e "s/^[[:blank:]]*User //")

#Strip out quote marks from SSH key path (otherwise it doesn't work...)
vagrant_ssh_key=$(echo "${vagrant_ssh_key}" | sed -e "s/$(printf '"')//g")

vagrant_docker_port=${4:-"--default-docker-port"}

if [ $vagrant_docker_port == "--default-docker-port" ]
then
  unset vagrant_docker_port
fi

if [ "$3" == "--vagrant-ssh" ]
then

#Get the IP and SSH port of the vagrant box from the vagrant ssh-config. This
#may be the host IP and a forwarded port, in which case docker ports must
#also be forwarded.

vagrant_ip=$(echo "${sshconfig}" | grep "^\s*HostName\s" | sed -e "s/^[[:blank:]]*HostName //")
vagrant_ssh_port=$(echo "${sshconfig}" | grep "^\s*Port\s" | sed -e "s/^[[:blank:]]*Port //")

else

#Pull out the direct IP and SSH port of the vagrant box. (We can't use the
#host port mapping, because docker-machine will try to communicate with
#the docker host on port 2376. We don't want to require that this port is
#forwarded from the vagrant box, as we can only do this for one docker host
#at a time.)

vagrant_network_adapter=${3:-"--direct-ssh"}

if [ $vagrant_network_adapter == "--direct-ssh" ]
then
  unset vagrant_network_adapter
fi

vagrant_direct_ssh=$(vagrant ssh -c "sudo ip address show ${vagrant_network_adapter:-eth1} | grep 'inet ' | sed -e 's/^.*inet /ip=/' -e 's/\/.*$//' && sudo grep Port /etc/ssh/sshd_config | sed -e 's/Port /port=/'")

#Get rid of spurious carriage returns...
vagrant_direct_ssh=$(echo "${vagrant_direct_ssh}" | sed -e "s/$(printf '\r')//")

vagrant_ip=$(echo "${vagrant_direct_ssh}" | grep "^ip=" | sed -e "s/^ip=//")
vagrant_ssh_port=$(echo "${vagrant_direct_ssh}" | grep "^port=" | sed -e "s/^port=//")

fi

if [ "$#" -gt 4 ]
then
  docker_machine_additional_parameters="${@:5}"
fi

echo vagrant-docker-setup will use the following settings to create the docker-machine:
echo IP: ${vagrant_ip}
echo SSH key: ${vagrant_ssh_key}
echo SSH user: ${vagrant_user}
echo SSH port: ${vagrant_ssh_port}
echo Docker port: ${vagrant_docker_port}
echo Additional arguments: ${docker_machine_additional_parameters}

#Remove existing docker-machine
docker-machine rm -f "$1"

docker_machine_optional_parameters=${vagrant_docker_port+"--generic-engine-port "}${vagrant_docker_port}${vagrant_docker_port+" "}${docker_machine_additional_parameters}${docker_machine_additional_parameters+" "}

#Add the vagrant box to docker-machine
docker-machine create -d generic --generic-ip-address "${vagrant_ip}" --generic-ssh-key "${vagrant_ssh_key}" --generic-ssh-user ${vagrant_user} --generic-ssh-port ${vagrant_ssh_port} ${docker_machine_optional_parameters}"${1}"

#Print the environment
docker-machine env "$1"
