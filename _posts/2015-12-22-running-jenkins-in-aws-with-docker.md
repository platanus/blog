---
layout: post
title: Running Jenkins in AWS with Docker
author: nicolasmery
tags:
  - aws
  - docker
  - jenkins
  - continuous integration

---

Continuous Integration its a must when building a resilient delivery pipeline. I have always thought that is like the Inmune System of the Code. Were bugs are the virus and diseases. Today we can have a strong base for our inmune system easily using Jenkins and Docker. We will be using AWS.

## Two machines.

We will use 2 machines

#### Jenkins Master

This machine has the responsibility of managing Jenkins nodes. It doesn’t need to have high resources allocated. We will use a micro instance for this.

Once created we proceed to the configuration:

```bash
adduser jenkins
su - jenkins
ssh-keygen -t rsa -b 4096 -C “jenkins@mail.com"
```

Copy the public key to a deploy key with read/write access on your github repo. For more info on how create a ssh key with access to your repository go to this link [Generating SSH Keys](https://help.github.com/articles/generating-ssh-keys/).

#### Jenkins Slave

This machine is the one doing most of the work. Here we will be running all our jobs/tests.

- Ensure that java jdk is installed the Jenkins Slave require this.
- Docker should be installed in the Slave and Jenkins should be able to run docker.

```bash
sudo yum install java
```

In the Jenkins Slave we create the jenkins user

```bash
adduser jenkins
su - jenkins
mkdir .ssh
cat pub.key > .ssh/authenticated_keys
chmod 600 .ssh
chmod 600 .ssh/authenticated_keys
```

We need to add `jenkins` to the `docker` group. Like this:

`sudo gpasswd -a jenkins docker`

## Jenkins in the Master

Start jenkins with docker

```bash
docker run --name jenkins_data -v /var/jenkins_home jenkins echo "Data OK"
docker run -d --name jenkins -p 50000:50000 -p 8080:8080 --volumes-from jenkins_data jenkins
```

jenkins_data is a data container, its a good practice so we can update jenkins later without worries of loosing the configuration.

## Jenkins Configuration

#### Plugins

Go to `http://YOUR_MASTER_IP:8080/pluginManager/`

Install these plugins

- Github: "This plugin integrates Jenkins with Github projects." 
- Ansi Color: "This plugin adds support for ANSI escape sequences, including color, to Console Output."
- Git: "This plugin allows use of Git as a build SCM"
- SSH Agent: "This plugin allows you to provide SSH credentials to builds via a ssh-agent in Jenkins."

#### Adding the Slave

Go to `http://YOUR_MASTER_IP:8080/computer/` and click on *New Node*

Leave the default configuration except that we should set *Labels* to `docker` and *Host* to the ip or domain name of the slave. This is important so our docker jobs know where tu run.

Now set the jenkins credentials with the private key we created before.

You should get something like this:

![](/images/jenkins_and_docker_in_aws/slave-conf.png)

#### Running a Job

Go to `http://YOUR_MASTER_IP:8080/` and click on *New Item*

Type a nice name, select *Free Style* and continue.

In the job configuration. Click on the checkbox *Restrict where this project can be run* and type `docker` as Label expression. Doing this will restrict this job to run only on slaves with label `docker`.

We will be using Git. Setup your project repository.

There are many ways to setup the trigger of the build. There is even a *Pull Request Builder* plugin that works pretty good.

If you installed the *Ansi Color* plugin you can select its checkbox. Be sure to start your Execute Shell script like this:

```bash
#!/bin/bash +x
set -e
```

Without this, Ansi Colors won't work.

Our sample job looks like this:

```
#!/bin/bash +x
set -e

DOCKER_REGISTRY=localhost:5000
DOCKER_IMAGE=myimage

docker build -t myimage .

#RUN OTHER TESTS HERE

docker tag -f $DOCKER_IMAGE $DOCKER_REGISTRY/$DOCKER_IMAGE:$GIT_COMMIT
docker push $DOCKER_REGISTRY/$DOCKER_IMAGE:$GIT_COMMIT

```

This will build the image and if successful will push it to our Private Registry. Be sure that your  [private registry](/creating-a-simple-aws-s3-private-docker-registry) is running on port 5000 of the Jenkins Slave.

At the end you will have a configuration similar to this screenshot:

![](/images/jenkins_and_docker_in_aws/jenkins-item-conf.png)

#### Click Build

Enjoy.

