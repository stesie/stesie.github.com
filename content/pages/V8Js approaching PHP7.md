---
slug: v8js-on-php7
date: 2015-10-05
tags:
- PHP7
- V8Js
category: V8Js
title: V8Js approaching PHP7
categories: V8Js
lastMod: 2025-01-03
---
For some weeks now I had the idea that V8Js must be running on PHP7 the day it is officially published. So when I started out porting soon after they published he first release candidate (aka 7.0.0RC1) I felt some pressure, especially after noticing that it really will be a lot of work to do.

The more glad I am to announce today, that V8Js finally compiles fine and passes the whole test suite from the master branch (apart from tiny modifications that became necessary due to PHP 5.6 to PHP 7 incompatibilities).

Since it works now, I've moved the "php7" branch from my personal repository to [the official V8Js Github repository](https://github.com/phpv8/v8js/tree/php7) meanwhile. Jenkins already is prepared as well, among others it now has a [PHP7 V8Js matrix job](https://jenkins.brokenpipe.de/job/docker-v8+php7+v8js/), that currently checks all release candidates in combination with some V8 versions, regularly, on every commit.
