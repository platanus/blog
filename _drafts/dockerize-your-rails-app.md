---
layout: post
title: Dockerize your Rails App
author: nicolasmery
tags:
    - rails
    - docker
---

This post its an introduction to containerizing your Ruby on Rails application with Docker. You will find out how to build an image of your app and how to run it.
 
## First step: install Docker. 

In Ubuntu: 

```wget -qO- https://get.docker.com/ | sh```

If that doesn't work, you could go to the [Docker official site](https://docs.docker.com/installation/ubuntulinux/#installing-docker-on-ubuntu)

In case of OSX go to [Docker Installation for Mac](https://docs.docker.com/installation/mac/)

## Build your Docker image

Now lets build a Dockerfile for your application.

```
# Available vers here https://registry.hub.docker.com/_/ruby
FROM ruby:2.1

MAINTAINER "Your Name <your@email.com>"

ADD . /app
WORKDIR /app
RUN bundle install

CMD ["rails","s"]
```

This is the minimal expression of a Dockerfile. Dockerfiles are recipes for building Docker images that can run in a Docker container.

This image is based on the ruby:2.1 image.
Then we ADD the code of our app to the /app folder.
We run bundle install to install the gems needed for our app.
Finally, we tell the image that our default command to run is "rails s".

Now build your image:

`docker build -t myimage .`

If you run it again you will find that it takes less time to build. Thats because docker caches the building process.

The problem with our Dockerfile is that the "ADD" line will be ran everytime that any file in our current folder changes (this includes the `RUN bundle install` line). That would be very annoying.

So to avoid that copy your Gemfile to a Gemfile.base file and lets change our Dockerfile like this:

```
FROM ruby:2.1

MAINTAINER "Your Name <your@email.com>"

ADD Gemfile.base /tmp/Gemfile
RUN cd /app && bundle install

ADD . /app
WORKDIR /app
RUN bundle install

CMD ["rails","s"]
```

With those 2 lines we will be caching most of our gems so when bundle install runs for second time in the Dockerfile it will run much faster. In the future you might want to update the Gemfile.base from time to time.

Build again your image:

``` docker build -t myimage . ```

## Running your Docker image

Run it like this:

``` docker run -ti myimage ```

You will probably get errors if your app depends on other services, i.e a database.

Identify the services that your app uses. Mysql? Redis? MongoDB?

You will find docker images for many of them here https://registry.hub.docker.com

For example we can run MySQL from a docker image like this:

``` docker run -d -v /var/lib/mysql -e MYSQL_ROOT_PASSWORD=mysecurepass mysql ```

This will run mysql as a daemon (-d) persisting the data (-v /var/lib/mysql) and setting the root pass (mysecurepass)

Now, we would like to connect to this database and there are many ways to do this but I prefer linking my app container to the db like this:

``` docker run -ti --link db:db myimage ```

When we do this, Docker creates a bunch of nice-to-have configuration so we can easily access to the service that the linked container exposes. We will be using the "db" hostname that docker creates in the /etc/hosts file of our app container.

Now this is a example database.yml for your Ruby on Rails app.

```
development:
  adapter: mysql2
  encoding: utf8
  database: app_development
  username: root
  password: mysecurepass
  host: db
  port: 3306
```

Notice that we are using "db" as the host name of the database.

You can use this strategy with all the services you need for your app. Linking to other containers adds a lot of environmental variables some are useful. You can find out more about linking here: [Docker Linking](https://docs.docker.com/userguide/dockerlinks/)

Once you have all running, start your app and enjoy!

``` docker run -ti --link db:db myimage ``

## Troubleshooting and tips

#### Logs and Tails

You can look at the logs of the container with `docker logs`

``` docker logs CONTAINER_ID```

And you can do something similar to tail -f on the logs like this

``` docker logs -f CONTAINER_ID```

And also you can tell the logs to only include the last 100 lines like this

``` docker logs -f --tail=100 CONTAINER_ID```

#### Mount the folder app in the container

In development you might want to change the code while is running.

You can "mount" your folder in the container running it like this:

``` docker run -ti -v ${PWD}:/app --link db:db myimage ```

#### Enter the container

You can also run bash to "enter" to the container:

``` docker run -ti -v ${PWD}:/app --link db:db myimage bash```

#### Docker Compose

docker-compose is a Docker tool that helps you manage a group of docker containers and their dependencies. 
You might want to use docker-compose to facilitate the start and stop process of your app stack. You can find more information about docker-compose [here](https://docs.docker.com/compose/)

