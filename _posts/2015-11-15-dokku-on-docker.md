---
layout: post
title: "Dokku on Docker"
category: Docker
tags: [ "Dokku", "Docker", "Heroku" ]
---
I've used [Heroku](https://www.heroku.com/) once back in 2013
and actually liked it a lot as it lets you concentrate on the development
part and just pulling in services as needed (and without further work needed).

Contrary I have had a root server at Hetzner for more then a decade now
and I don't want to pay for pet projects hosted on Heroku then (and I'm
interested in hosting to some degree at least).

Enter [Dokku](http://progrium.viewdocs.io/dokku/).  Dokku is a
very small "platform as a service" thingy, written in around 200 lines of
Bash.  After all a mini-Heroku based on Docker.  Their installation guide
assumes that you have a VPS and their bootstrap script converts the VPS into
a mini-Heroku, running Dokku on the box itself alongside Nginx as a reverse
proxy.

So far so good, but that's not what I wanted to have as I already have the
root server in place which is dockerized heavily (ldap instance, mailgate,
web mailer, several blogs, gitlab, reverse proxy, etc.) ... hence Dokku
itself should go into another Docker container (and the Dokku apps should
run Docker-in-Docker -- like I'm already doing with the V8Js Jenkins
instance).

Googling around I've found a promising project over at Github:
[dokku-in-docker](https://github.com/eugeneware/dokku-in-docker).
It is a bit dated (last commit back in Nov 2014) and Dokku itself has gathered
quite some pace recently, hence the container didn't build -- and afterall
I wanted a recent Dokku version.

Hence I have [my own fork](https://github.com/stesie/dokku-in-docker) now.
Simply build it as usual:

```
docker build -t dokku-in-docker .
```

then run it like

```
/usr/bin/docker run --name="dokku.brokenpipe.de" --privileged -d
  -e VHOSTNAME="dokku.brokenpipe.de"
  -e PUBKEY="ssh-rsa AAAA...vkr stesie@hahnschaaf"
  -e VIRTUAL_HOST="*.dokku.brokenpipe.de"
  -v "/opt/docker/dokku.brokenpipe.de/home":"/home/dokku"
  -v "/opt/docker/dokku.brokenpipe.de/docker":"/var/lib/docker"
  -v "/opt/docker/dokku.brokenpipe.de/dokku-services":"/var/lib/dokku/services"
  -p 20022:22
  "dokku-in-docker"
```

* the VIRTUAL_HOST environment variable is for the reverse proxy container
  (jwilder/nginx-proxy) and not dokku itself
* replace PUBKEY with your pubkey (~/.ssh/id_rsa.pub), dokku doesn't support
  multiple users (but you can run several dokku-in-docker containers easily)
* the first & second volume simply persist apps over container rebuild
* the third volume persists databases created by *dokku postgres:create* et
  al

This way Dokku integrates nicely with the other Docker containers and my
approach to have no persistence-needing data in the container itself.
