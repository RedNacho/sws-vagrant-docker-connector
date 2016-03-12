# sws-vagrant-docker-connector #

Shell scripts to bring up a vagrant box and connect docker-machine to it.

* vagrant-docker-setup.sh: Brings up a vagrant box and registers it with docker-machine.
* vagrant-docker-destroy.sh: Removes a vagrant box from docker-machine and then destroys it. Do not use this if that isn't what you want to happen!

## Rationale ##

Recently I encountered a situation where the default docker-machine environment was not quite correct for me (some kernel bug, I can't remember). So I brought up my own VM with Vagrant and connected it to the docker-machine with the generic driver. This allowed me to run docker commands as if they were local, but with docker actually running inside an arbitrary vagrant box which I'd just created. Then I realised that it was possible to script everything that I'd just done, so I did.

It's more or less the approach [here](http://blog.scottlowe.org/2015/08/04/using-vagrant-docker-machine-together/) and [here](http://blog.wescale.fr/2015/11/24/docker-machine-et-vagrant/), except that I've scripted it. It would make sense to implement this logic as a driver for docker-machine, but I don't know enough about this subject to make the attempt myself.

## Disclaimer ##

I thought somebody else might find this useful, so I made it public. However, I haven't polished it, and make no guarantees about whether or not it will work out of the box in every case. It makes heavy use of grep and sed, which are not identical on every system, and there may be hidden text encoding issues (e.g. line endings) which I haven't encountered yet.

I originally wrote it for git bash on Windows 10, and have tweaked it to work on my Ubuntu 14.04 laptop and my work Macbook (can't remember what OSX version).

## Requirements ##

* Vagrant
* Docker
* Docker-machine (pre-installed with Docker unless you're on Linux)
* A vagrant box capable of running Docker (ie Linux) which is either visible to the host by IP address (not the case with default vagrant networking options), or alternatively forwards docker ports (2375 or 2376) unchanged to the host machine. See vagrant-example for a working example.

## Examples ##

### Setup ###


```
#!bash

#Brings up the vagrant box in the folder vagrant-example and registers it with docker-machine under the name "vagrant"
./vagrant-docker-setup.sh vagrant vagrant-example

#Brings up the vagrant box in the folder vagrant-example and registers it with docker-machine under the name "vagrant", extracting the IP address on the vagrant box's eth1 network adapter to communicate with the box.
./vagrant-docker-setup.sh vagrant vagrant-example eth1

#Brings up the vagrant box in the folder vagrant-example and registers it with docker-machine under the name "vagrant", using the IP specified in vagrant ssh-config to communicate with the box.
./vagrant-docker-setup.sh vagrant vagrant-example --vagrant-ssh
```


vagrant-docker-setup.sh takes an optional third argument, which is used to configure how we get the IP address and port to use for communication with the box. There are two options here:

1. Specify the name of a network adapter on the VM. The host will attempt to communicate directly with the VM on the IP for this adapter, and the SSH port for the machine. This requires that the VM is visible to the host machine, e.g. on a private network.

2. Specify "--vagrant-ssh". The host will attempt to communicate with the VM via the IP and the port specified in vagrant's SSH config. With a default vagrant setup this is the host machine, so the vagrant box must forward appropriate docker ports (e.g. 2376) to the host, because docker-machine will not be able to communicate directly with the VM. I do not recommend this approach unless there is a good reason not to expose the vagrant box to the host on a private network, because it ties up the docker ports for the entire machine (so you can't expose a docker instance on the host, or run a second vagrant box with the same network config).

If unspecified, the default is "eth1", which is the adapter that vagrant sets up by default for private networking. So if you have set the private network option in the Vagrantfile without making any advanced configuration, you should not need to specify a third argument, as shown in the first example above.

As far as I'm aware, you should not normally need to manually specify any other configuration yourself, although feel free to hack the script to suit your needs.

### Teardown ###


```
#!bash

#Removes the vagrant box named "vagrant" from docker-machine and then destroys the vagrant box in the folder vagrant-example.
./vagrant-docker-destroy.sh vagrant vagrant-example
```


vagrant-docker-destroy.sh takes an optional third argument, -f, which is passed through to docker-machine rm and vagrant destroy so that the script can be used without prompts.

### Step-by-step

```
#!bash

#Bring up the vagrant box in vagrant-example and register it with docker-machine under the name vagrant.
./vagrant-docker-setup.sh vagrant vagrant-example

#Load the environment into the current shell
eval $(docker-machine env vagrant)

#Do something with docker, which is now connected to the vagrant-example box...
#docker build...
#docker run...

#To ensure the configuration is up-to-date (e.g. if you've restarted and the box IP might be different), just rerun the setup script and reload the docker-machine environment.
./vagrant-docker-setup.sh vagrant vagrant-example
eval $(docker-machine env vagrant)

#Deregister the vagrant box and destroy it if you don't need it anymore.
./vagrant-docker-destroy.sh vagrant vagrant-example

```