---
layout: post
title: "V8Js on Heroku"
category: V8Js
tags: [ "V8Js", "Dokku", "Heroku" ]
---
After I've built my own PHP buildpack with V8Js included it's now easily
possible to push PHP applications onto Heroku that require the extension.

When creating the app on Heroku simply specify the custom buildpack like

```
heroku create laughinghipster -b https://github.com/stesie/heroku-buildpack-php.git
```

... where *laughinghipster* is an arbitrary application name and the last argument
the URL to my buildpack on Github.

The pushed repo must include a file named `composer.json` that requires `ext-v8js`;
either with a particular version or just wildcard:

```json
{
    "require": {
        "slim/slim": "2.*",
        "slim/views": "0.1.*",
        "twig/twig": "1.*",
        "ext-v8js": "*" 
    }
}
```

Then simply push the application to Heroku, it should detect the dependency on
`ext-v8js` and simply download & install it:

```console
stesie@hahnschaaf:~/Projekte/laughinghipster$ git push heroku master
Zähle Objekte: 1878, Fertig.
Delta compression using up to 4 threads.
Komprimiere Objekte: 100% (1738/1738), Fertig.
Schreibe Objekte: 100% (1878/1878), 4.11 MiB | 108.00 KiB/s, Fertig.
Total 1878 (delta 938), reused 207 (delta 89)
remote: Compressing source files... done.
remote: Building source:
remote: 
remote: -----> Fetching set buildpack https://github.com/stesie/heroku-buildpack-php.git... done
remote: -----> PHP app detected
remote: -----> No runtime required in 'composer.json', defaulting to PHP 5.6.15.
remote: -----> Installing system packages...
remote:        - PHP 5.6.15
remote:        - Apache 2.4.16
remote:        - Nginx 1.8.0
remote: -----> Installing PHP extensions...
remote:        - v8js (composer.lock; downloaded)
remote:        - zend-opcache (automatic; bundled)
remote: -----> Installing dependencies...
remote:        Composer version 1.0.0-alpha10 2015-04-14 21:18:51
remote:        Loading composer repositories with package information
remote:        Installing dependencies from lock file
remote:          - Installing slim/slim (2.6.2)
remote:            Downloading: 100%
remote:        
remote:          - Installing slim/views (0.1.3)
remote:            Downloading: 100%
remote:        
remote:          - Installing twig/twig (v1.23.1)
remote:            Downloading: 100%
remote:        
remote:        Generating optimized autoload files
remote: -----> Preparing runtime environment...
remote:        NOTICE: No Procfile, using 'web: vendor/bin/heroku-php-apache2'.
remote: 
remote: -----> Discovering process types
remote:        Procfile declares types -> web
remote: 
remote: -----> Compressing... done, 90.7MB
remote: -----> Launching... done, v3
remote:        https://laughinghipster.herokuapp.com/ deployed to Heroku
remote: 
remote: Verifying deploy.... done.
To https://git.heroku.com/laughinghipster.git
 * [new branch]      master -> master
```

... and you're set.


