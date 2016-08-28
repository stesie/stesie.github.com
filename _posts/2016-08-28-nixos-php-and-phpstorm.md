---
layout: post
title: "NixOS, PHP, PHPUnit & PhpStorm"
tags: [ "NixOS", "PHP", "PHPUnit", "PhpStorm" ]
---
Since one of my goals with NixOS was to conveniently install multiple PHP
versions side by side (and without the hassle to compile manually with
`--prefix=/opt/php-something/` flags) I've finally tried to get a feasible
setup.

For the moment I decided to go with "central" (i.e. not-per-project)
installations within my `$HOME` as I don't want to set up a whole
environment just to do a Kata every once in a while.

Installing PHP 7.0
-----------------------

This should actually be pretty straight forward since PHP 7.0 as well as
xdebug are both part of official nixpkgs ... and once you know what to do
it actually is :)

Obviously we need to create our own derivation and then can simply use
`buildEnv` to symlink our `buildInputs` to the output directory.  However
the PHP binary has the extension path baked in (the one to its own nix store),
so we have to overwrite that one.  This can be done using `makeWrapper` script
and simply provide `-d extension_dir=...` flag before anything else.
In order to be able to do that we first need to fiddle with the `/bin` directory
though, as only the `php70` build input has a `/bin` directory and `buildEnv`
hence simply links the whole `$php70/bin` directory to `$out/bin`.

I decided to put the PHP 7.0 environment to `$HOME/bin/php70`, which I
`mkdir`'ed first and then created a `default.nix` like this:

```nix
with import <nixpkgs> { };

stdenv.mkDerivation rec {
  name = "php70-env";

  env = buildEnv { 
    inherit buildInputs name;
    paths = buildInputs;
    postBuild = ''
      mkdir $out/bin.writable && cp --symbolic-link `readlink $out/bin`/* $out/bin.writable/ && rm $out/bin && mv $out/bin.writable $out/bin
      wrapProgram $out/bin/php --add-flags "-d extension_dir=$out/lib/php/extensions -d zend_extension=xdebug.so"
    '';
  };
  builder = builtins.toFile "builder.sh" ''
    source $stdenv/setup; ln -s $env $out
  '';

  buildInputs = [
    php70
    php70Packages.xdebug
    makeWrapper
  ];
}
```

(maybe there's a more elegant solution to replace this link with a directory
of symlinks, ... but I haven't found out yet.  Please tell me in case you
know how to do it properly)

... then after running `nix-build` you should have a `./result/bin/php`
which is a shell script wrapping the actual php binary to automatically
load `xdebug.so`.

Installing PHP 7.1 (beta 3)
---------------------------------

This is of course a little bit more involved as PHP 7.1 isn't yet part
of nixpkgs, since it's not really released yet.

The installation (including compilation) of PHP 7.1 can be achieved by
simply creating an `overrideDerivation` of `pkgs.php70` with `name`, `version`
and `src` adapted as needed.

... the xdebug PECL package from nixpkgs cannot simply be re-used as
the latest release doesn't support PHP 7.1 as of yet.  But creating
a derivation for an PECL package from scratch isn't complicated, so
let's just do that manually :)

So here's the `php71/default.nix` file:

```nix
with import <nixpkgs> { };

let
  php71 = pkgs.lib.overrideDerivation pkgs.php70 (old: rec { 
    version = "7.1.0beta3";
    name = "php-${version}";
    src = fetchurl {
      url = "https://downloads.php.net/~davey/php-${version}.tar.bz2";
      sha256 = "02gv98xaal8pdr1yj57k2ns4v8g53iixrz4dynb5nlr81vfg4gwi";
    };
  });

  php71_xdebug = stdenv.mkDerivation rec {
    name = "php-xdebug-55fccbb";
    src = fetchgit {
      url = "https://github.com/xdebug/xdebug";
      rev = "55fccbbcb8da0195bb9a7c332ea5364f58b9316b";
      sha256 = "15wgvzf7l050x94q0a62ifxi5j7p9wn2f603qzxwcxb7ximd9ffb";
    };
    buildInputs = [ php71 autoreconfHook ];

    makeFlags = [ "EXTENSION_DIR=$(out)/lib/php/extensions" ];
    autoreconfPhase = "phpize";
    preConfigure = "touch unix.h";
  };

in
  stdenv.mkDerivation rec {
    name = "php71-env";

    env = buildEnv { 
      inherit buildInputs name;
      paths = buildInputs;
      postBuild = ''
        mkdir $out/bin.writable && cp --symbolic-link `readlink $out/bin`/* $out/bin.writable/ && rm $out/bin && mv $out/bin.writable $out/bin
        wrapProgram $out/bin/php --add-flags "-d extension_dir=$out/lib/php/extensions -d zend_extension=xdebug.so"
      '';
    };
    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup; ln -s $env $out
    '';

    buildInputs = [
      php71
      php71_xdebug
      makeWrapper
    ];
  }
```

{: .info}
The `touch unix.h` thing is actually a hack needed to compile the extension
properly as php's `config.h` has the `HAVE_UNIX_H` flag defined, which should
actually tell whether the system has a `unix.h` file (which old Unix
systems obviously once had, Linux systems don't).  However the imap
client library has a `unix.h` file which tricks php's `configure` script
to note having one :)  ... and as we (obviously) don't have imap library
as build input `php.h`'s `#include` would fail without that `touch`...

PHPUnit & PhpStorm
-----------------------

PHPUnit isn't packaged in nixpkgs, but after all it's just a phar archive file
and we'd like to run it with different PHP versions anyways, therefore I've
just downloaded it and stored it in `$HOME/bin` also.

Configuring PhpStorm is pretty straight forward, just go to *File* > 
*Default Settings* > *Languages & Frameworks* > *PHP* and click the
three-dots-button next to *Interpreter*.  Then simply add both PHP executables
at `$HOME/bin/php70/result/bin/php` and `$HOME/bin/php71/result/bin/php`.
PhpStorm should automatically find out about the `php.ini` file as well
as the Xdebug extension.

... last but not least go to *PHPUnit* config folder, choose
*Path to phpunit.phar* and point it to the downloaded phar archive.

... and now you're set :)  Just select one of the interpreters and run your
tests (and then switch interpreters to your liking).
