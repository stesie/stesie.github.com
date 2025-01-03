---
slug: php-account-approved
date: 2015-03-13
tags:
- PHP
- V8Js
category: V8Js
title: php.net account approved
categories: V8Js
lastMod: 2025-01-03
---
After waiting for a really long time (half a year) I finally have an approved php.net + PECL account granted with lead-rights on V8Js :-)

... therefore I finally published V8Js version 0.2.0, succeeding 0.1.5 which was published 1.5 years ago.

Changes include

  + adapt to latest v8 API (v8 versions from 3.24.6 up to latest 4.3 branch supported now)

  + v8 debugging support

  + apply time & memory limits to V8Function calls

  + support mapping of PHP objects implementing ArrayAccess to native arrays

  + new API to set limits: setTimeLimit & setMemoryLimit methods on V8Js object

  + typesafe JavaScript function wrappers

  + improved back-and-forth object passing (rewrapping, correcty isolate unlocking)

  + fix property and method visibility issues

  + fix memory leaks

Download the release from [PECL repository](https://pecl.php.net/package/v8js/0.2.0).
