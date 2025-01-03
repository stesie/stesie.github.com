---
slug: heroku-custom-platform-repo
date: 2016-03-28
tags:
- V8Js
- Dokku
- Heroku
category: V8Js
title: Heroku custom platform repo for V8Js
categories: V8Js
lastMod: 2025-01-03
---
Yesterday @dzuelke [poked me](https://github.com/heroku/heroku-buildpack-php/issues/80#issuecomment-202133119) to migrate the old PHP buildpack adjusted for V8Js to the new custom platform repo infrastructure. The advantage is that the custom platform repo only contains the v8js extension packages now, the rest (i.e. Apache and PHP itself) are pulled from the lang-php bucket, aka normal php buildpack.

As I already had that on my TODO list, I just immediately did that :-)

... so here's the new [heroku-v8js Github repository](https://github.com/phpv8/heroku-v8js) that has all the build formulas. Besides that there now is a S3 bucket *heroku-v8js* that stores the pre-compiled V8Js extensions for PHP 5.5, 5.6 and 7.0. [packages.json file here](https://heroku-v8js.s3.amazonaws.com/dist-cedar-14-stable/packages.json).

To use with Heroku, just run

```
$ heroku config:set HEROKU_PHP_PLATFORM_REPOSITORIES="https://heroku-v8js.s3.amazonaws.com/dist-cedar-14-stable/packages.json"
```

with Dokku:

```
$ dokku config:set YOUR_APPNAME HEROKU_PHP_PLATFORM_REPOSITORIES="https://heroku-v8js.s3.amazonaws.com/dist-cedar-14-stable/packages.json"
```
