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


Here is the general format for the parameters (they currently need to be in the correct positions - apologies, I will work on this when I have time):


```
#!bash

./vagrant-docker-setup.sh ${DOCKER_MACHINE_NAME} ${VAGRANT_PATH} [${SSH_CONFIG_SOURCE} [${DOCKER_PORT} [${OTHER_DOCKER_MACHINE_ARGS}]]]

```


**DOCKER_MACHINE_NAME**: The name to give the vagrant box in docker-machine

**VAGRANT_PATH**: The path to the vagrant box

**SSH_CONFIG_SOURCE** (optional): Either (a) the network adapter on the vagrant box to use to extract an IP which is accessible from the host, or (b) "--vagrant-ssh". If omitted, this will default to "eth1" (which is the default adapter that vagrant sets up for private networking). The special "--vagrant-ssh" setting does not try to access the box directly, and instead uses the vagrant SSH config, which is usually a forwarded port on the host machine. **To use the default value for this parameter and enter more arguments, enter "--direct-ssh".**

**DOCKER_PORT** (optional): The port on which to try to connect to Docker. There are several unfortunate complexities here. Firstly, if "--vagrant-ssh" was specified, and the vagrant SSH config uses port forwarding from the host, this must be a port on the host which is forwarded to Docker on the vagrant. If a direct SSH connection is used, the port does not need to be forwarded. The second thing to be aware of is that this uses the new (at the time of writing) "--generic-engine-port" parameter in docker-machine to change the port from the default value of 2376, and will not work with outdated versions of docker-machine. The final thing is that this new docker-machine parameter does not only tell docker-machine how to communicate with docker, but also how to start docker on the box. This means that if you are relying on port forwarding, the port on the host (which is used to connect to Docker) must be forwarded to the same port on the vagrant box (which is where the Docker daemon will be listening). **To use the default value for this parameter and enter more arguments, enter "--default-docker-port".**

**OTHER_DOCKER_MACHINE_ARGS** (optional): All other arguments are passed to docker-machine.

Normally, you will do one of two things:

1. Set the vagrant box up on a private network, and use the direct SSH method. In this case, you should not need to specify any of the optional arguments. You may have problems if the network adapter for the private network is something other than eth1. If that happens, go on to the vagrant box, find the network adapter you should be using, and specify that as the SSH_CONFIG_SOURCE parameter. **This is the best option unless you have some reason not to expose your vagrant box to your host on a private network.**

2. Set the vagrant box up to forward the Docker daemon port to the host, and use the vagrant SSH method by passing "--vagrant-ssh" as the SSH_CONFIG_SOURCE. By default, the Docker port will be 2376, although you can override it with the DOCKER_PORT parameter if your version of docker-machine supports this (see above for details). The port must be forwarded unchanged, e.g. 2376:2376. If your version of docker-machine does not support the --generic-engine-port parameter, you must always use port 2376, which means that you can only run one docker-machine at a time this way on the host. **This is the best option if you do not want to expose your vagrant box to your host on a private network, and instead want to provide access through port forwarding.**

```
#!bash

#Option 1, with direct SSH
./vagrant-docker-setup.sh ${DOCKER_MACHINE_NAME} ${VAGRANT_PATH} [${NETWORK_ADAPTER}]

#Option 2, with vagrant SSH
./vagrant-docker-setup.sh ${DOCKER_MACHINE_NAME} ${VAGRANT_PATH} --vagrant-ssh [${DOCKER_PORT}]

```

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