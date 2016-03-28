---
layout: post
title: "PHP buildpack for V8Js"
category: V8Js
tags: [ "V8Js", "Dokku", "Heroku" ]
---
{: .info}
**Update Mar 28, 2016**: It is no longer necessary (and hence discouraged) to 
fork the buildpack and rebuild it completely.  The official PHP buildpack
now has support for so-called custom platform repositories, and
[I've built one for V8Js meanwhile](/2016/03/heroku-custom-platform-repo).

The other day I've configured a Dokku instance on my root server and
then tried to install a PHP project requiring the V8Js extension.
This of course failed for obvious reasons: Heroku's buildpack for
PHP doesn't provide the V8Js PHP extension.

Luckily the <a href="https://github.com/heroku/heroku-buildpack-php">
buildpack is available on Github</a>.  So it should be possible to
have a fork that supports V8Js.

So here we go, how hard can it be?  :)

If you're just interested in using the buildpack I've created, feel
free to just use <a href="https://github.com/stesie/heroku-buildpack-php/">
my own fork on Github</a>.  The master branch references my personal
S3 bucket, so Heroku or Dokku just fetch the needed resources from there.

Below you'll find a step by step guide on how to build such a
buildpack on your own:

Step 0: Setting up S3 bucket
----------------------------

The buildpack assumes that the binaries are stored on S3; hence
a new S3 bucket (along an IAM user with access on that bucket)
needs to be created first.

Step 1: Clone Heroku's PHP buildpack
------------------------------------

First step is to fetch Heroku's original build pack to a local workspace:

```console
$ git clone https://github.com/heroku/heroku-buildpack-php
$ cd heroku-buildpack-php
```

Step 2: Create app on Dokku and configure remote
------------------------------------------------

... before any modification, just create an app as a clean base for
building the binaries later on:

```console
$ dokku apps:create buildpack-php
$ dokku config:set buildpack-php BUILDPACK_URL="https://github.com/heroku/heroku-buildpack-python"
$ git remote add dokku ssh://dokku@dokku.brokenpipe.de:20022/buildpack-php
```

Step 3: Configure app
---------------------

S3/IAM access key + secret need to be provided as environment variables,
therefore we simply set them with `dokku config:set`.

```console
$ dokku ps:scale buildpack-php web=0
$ dokku config:set buildpack-php AWS_ACCESS_KEY_ID="XXXXXXXXXXXXXXXXXXXX"
$ dokku config:set buildpack-php AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
$ dokku config:set buildpack-php S3_BUCKET="buildpack-phpv8"
$ dokku config:set buildpack-php S3_PREFIX="dist-cedar-14-master"
$ dokku config:set buildpack-php STACK="cedar-14"
$ dokku config:set buildpack-php WORKSPACE_DIR=/app/support/build
```

Step 4: Upload the buildpack to Dokku
-------------------------------------

If the app is configured as needed, just push the unmodified code to
see of everything works as expected:

```console
$ git push dokku master
```

Step 5: Build used libraries
----------------------------

Evey build should have its own `dokku run` to ensure that nothing else
but the declared dependencies can be used plus the packages are as
clean as possible:

```console
$ dokku run buildpack-php bob deploy libraries/gettext
$ dokku run buildpack-php bob deploy libraries/icu
$ dokku run buildpack-php bob deploy libraries/libmcrypt
$ dokku run buildpack-php bob deploy libraries/pcre
$ dokku run buildpack-php bob deploy libraries/zlib
```

Step 6: Build Apache, Nginx & PHP
---------------------------------

```console
$ dokku run buildpack-php bob deploy apache-2.4.16
$ dokku run buildpack-php bob deploy nginx-1.8.0
$ dokku run buildpack-php bob deploy php-min
$ dokku run buildpack-php bob deploy composer
$ dokku run buildpack-php bob deploy composer-1.0.0alpha11
```

The `php-min` package is always initially installed on every built
slug (container) and used to track dependencies & installation
candidates.  The composer installer needs information on which
PHP versions & extensions are available, which are made available by
means of JSON manifests, which need to be uploaded seperately.

```console
u26678@1b8458e5519f:~$ bob build php-5.5.30

Fetching dependencies... found 4:
  - libraries/zlib
  - libraries/libmcrypt
  - libraries/icu
  - libraries/gettext
Building formula php-5.5.30 in /tmp/bobE7yqsM:
    -----> Building PHP 5.5.30...
...
    -----> Done. Run 's3cmd --ssl --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY --acl-public put /tmp/bobE7yqsM/php-5.5.30.composer.json s3://buildpack-phpv8/dist-cedar-14-master/php-5.5.30.composer.json' to upload manifest.
u26678@1b8458e5519f:~$ s3cmd --ssl --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY --acl-public put /tmp/bobE7yqsM/php-5.5.30.composer.json s3://buildpack-phpv8/dist-cedar-14-master/php-5.5.30.composer.json
'/tmp/bobE7yqsM/php-5.5.30.composer.json' -> 's3://buildpack-phpv8/dist-cedar-14-master/php-5.5.30.composer.json'  [1 of 1]
 2026 of 2026   100% in    0s     3.96 kB/s  done
'/tmp/bobE7yqsM/php-5.5.30.composer.json' -> 's3://buildpack-phpv8/dist-cedar-14-master/php-5.5.30.composer.json'  [1 of 1]
 2026 of 2026   100% in    0s     3.53 kB/s  done
Public URL of the object is: http://buildpack-phpv8.s3.amazonaws.com/dist-cedar-14-master/php-5.5.30.composer.json
```

... the `build deploy` command automatically creates the manifest and
prints the command required to publish it.  Copy & paste FTW :-)

... repeat that for php-5.6.16 and php-7.0.1

Last but not least all of those little manifests files need to be
collected into a single file named `packages.json`:

```console
u4725@983895293e5e:~$ support/mkrepo.sh
-----> Fetching manifests...
WARNING: Empty object name on S3 found, ignoring.
's3://buildpack-phpv8/dist-cedar-14-master/ext-v8js-0.4.0_php-5.5.composer.json' -> './ext-v8js-0.4.0_php-5.5.composer.json'  [1 of 7]
 393 of 393   100% in    0s     2.74 kB/s  done
's3://buildpack-phpv8/dist-cedar-14-master/ext-v8js-0.4.0_php-5.6.composer.json' -> './ext-v8js-0.4.0_php-5.6.composer.json'  [2 of 7]
 393 of 393   100% in    0s     3.31 kB/s  done
...
-----> Generating packages.json...
-----> Done. Run 's3cmd --ssl --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY --acl-public put packages.json s3://buildpack-phpv8/dist-cedar-14-master/packages.json' to upload repository.
u4725@983895293e5e:~$ s3cmd --ssl --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY --acl-public put packages.json s3://buildpack-phpv8/dist-cedar-14-master/packages.json
'packages.json' -> 's3://buildpack-phpv8/dist-cedar-14-master/packages.json'  [1 of 1]
 9913 of 9913   100% in    0s    19.31 kB/s  done
'packages.json' -> 's3://buildpack-phpv8/dist-cedar-14-master/packages.json'  [1 of 1]
 9913 of 9913   100% in    0s    17.36 kB/s  done
Public URL of the object is: http://buildpack-phpv8.s3.amazonaws.com/dist-cedar-14-master/packages.json
```

... again, `mkrepo.sh` tells us how to upload the resulting file.

... now we have a buildpack for PHP that is functionally equivalent
to Heroku's version (apart from not having compiled each and every
PHP version and extension, that might be available on Heroku).

Step 7: Update bin/compile
--------------------------

`bin/compile` is the shell script that is executed during the `git push`
to either Dokku or Heroku; it has a variable named `S3_URL` which needs
to point to the S3 bucket created in Step 0.

Step 8: Adding own recipes
--------------------------

As the buildpack clone is usable, now it's time to add further
recipies.  In case of V8Js this is the V8 library itself (packages as
libraries/v8) and the extension plus a bare version for every
major PHP release.

The bare version is the extension alone, without the PHP version
included, that it was built against as well as any further
dependencies (V8 in that case).
The non-bare variant ships all dependencies except for PHP itself.

The recipes themselves are simple shell scripts.

The V8 library as well as the bare package versions don't need a
manifest file, as they are just needed during build time.  The
extension package itself needs one however, otherwise composer won't
find it ... and hence cannot install it.  This is in case of the v8js
package the manifest file must be uploaded manually + the
packages.json file needs to be regenerated.
