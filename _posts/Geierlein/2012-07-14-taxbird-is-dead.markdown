--- 
layout: post
title: "Taxbird is finally dead"
tags: [ "Homepage", "Taxbird", "libgeier", "Geierlein" ]
category: Geierlein
---
Since _libgeier_ and _Taxbird_ both have found a successor in _Geierlein_
and the latter is rather usable already, I had a hard time the last days
contemplating whether to drop those old projects or not.

After all especially Taxbird would require a lot of work sooner than
later.  It's currently based on Gtk2 and Guile 1.8 which both are quite
dated right now.  This is porting to newer versions and much testing is
due.

Furthermore I'd like to omit the annual stress of building packages
for various distros, telling people how to compile the code, etc.pp
Geierlein is by far easier to install.  It's written in JavaScript and
hence does not require to do compiling.  Just unzip the archive provided
on the homepage and point Mozilla Firefox to it.  The application should
just be up and running.

To put it short, libgeier & Taxbird are now dead.  I'm not going to
update it any further.  Besides I've removed the [old homepage of the
project](http://www.taxbird.de) and replaced with a pointer towards
the Geierlein project.
