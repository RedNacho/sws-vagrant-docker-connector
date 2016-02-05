#!/bin/bash

#Parameters:
# - The name to give the docker-machine (will be destroyed if it already exists)
# - The location of the Vagrantfile for the vagrant box
# - (Optional) "-f" to force destruction

#Remove the docker machine
docker-machine rm $3 "$1"

#Destroy the vagrant box
cd "$2"
vagrant destroy $3
