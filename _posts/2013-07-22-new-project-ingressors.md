---
layout: post
title: "New Project: Ingressors"
tags: [ "Ingress", "Web of Trust", "Heroku", "Neo4j", "Node.js", "Locomotive MVC", "Express" ]
---
After my colleage [Tino Dietel](https://github.com/StilgarBF) and I came up
with the idea of a web application providing a web of trust among local
[Ingress](http://www.ingress.com/) Resistance agents, I actually started
to get my hands dirty somewhen last week.  I labeled my newest pet project
*ingressors*.
The source code [is already available from GitHub](https://github.com/stesie/ingressors)

Ingressors is a web application based on the [Locomotive.js MVC framework](locomotivejs.org)
by Jared Hanson.  This is the application sits on a Node.js+Express.js stack and
uses [Neo4j](http://www.neo4j.org/) as its backing service.  The frontend itself
is page-load driven and makes use of [Bootstrap by Twitter](http://twitter.github.io/bootstrap/).

So far the application allows to

* authenticate via OAuth against Google+ (uses Passport middleware)
* store ingress nickname and Google+ reference to Neo4j store
* poke other agents
* reject or accept pokes (where accept means you trust another agent)
* list incoming and outgoing trust
* display a web of trust in list form, i.e. a list of agents you trust, agents trusted by
  agents you trust, agents trusted by agents trusted you trust, etc.pp.
  The table also shows the number of incoming trusts for each agent.

![Screenshot of Ingressors](/assets/images/ingressors.png)

I decided to not host the application by myself, but try out hosting on
[Heroku](http://www.heroku.com/) instead.  Heroku is a cloud platform as a
service, that allows hosting of apps written in Node.js, Python Django and others.
Hosting there is free of charge as long as the app uses only a single
Dyno (frontend server instance).  Neo4j is available as an add-on, however
without a Gremlin stack -- but Cypher queries are more than enough for
this new app :-)

*Update:* I never really published nor completed the application. After all I
even lost interest in Ingress some time ago.

