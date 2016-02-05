# vagrant-docker-connector #

Shell scripts to bring up a vagrant box and connect docker-machine to it.

* vagrant-docker-setup.sh: Brings up a vagrant box and registers it with docker-machine.
* vagrant-docker-destroy.sh: Removes (without forcing) a vagrant box from docker-machine and then destroys it. (Do not use this if that isn't what you want!)

## Rationale ##

Recently I encountered a situation where the default docker-machine environment was not quite correct for me (some kernel bug, I can't remember). So I brought up my own VM with Vagrant and connected it to the docker-machine with the generic driver. Then I realised that it was possible to script everything that I'd just done, so I did.

## Disclaimer ##

I thought somebody else might find this useful, so I made it public. However, I haven't polished it.

## Example ##


```
#!bash

#Brings up the vagrant box in the folder vagrant-example and registers it with docker-machine under the name "vagrant"
./vagrant-docker-setup.sh vagrant vagrant-example
#Removes the vagrant box named "vagrant" from docker-machine and then destroys the vagrant box in the folder vagrant-example.
./vagrant-docker-destroy.sh vagrant vagrant-example
```


vagrant-docker-setup.sh also takes an optional third argument, which is the network adapter used to establish the machine's IP address (default eth1). See the .sh for more details.