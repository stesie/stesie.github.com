---
layout: post
title: "Building a Jekyll Environment with NixOS"
tags: [ "NixOS", "Github Pages", "Jekyll" ]
---
So there is this idea with NixOS to install only the very base system in the global environment
and augment these using [Development Environments](https://nixos.org/wiki/Development_Environments).
And as I'm creating this blog using Github Pages aka Jekyll, writing in Markdown, and would like
to be able to preview any changes locally, I of course need Jekyll running locally.  Jekyll is even
on nixpkgs, ... but there are Jekyll plugins which aren't bundled with this package and
essential for correct rendering of e.g. @-mentions and source code blocks.

... so the obvious step was to create such a NixOS Development Environment, which has Ruby 2.2,
Jekyll and all the required plugins installed.  Turns out there even is a
[github-pages](https://help.github.com/articles/setting-up-your-github-pages-site-locally-with-jekyll/)
Gem, so we just need to "package" that.  [Packaging Ruby gems](https://nixos.org/wiki/Ruby) is pretty
straight forward actually, ...

so first let's create a minimal `Gemfile` first:

```ruby
source 'https://rubygems.org'
gem 'github-pages'
```

{: .info}
The Github page has this `, group: :jekyll_plugins` thing in it, ... I had to remove it, otherwise
nix-shell complains that it cannot find the Jekyll gem file, once you try to run it (later).

Then we need to create `Gemfile.lock` by running bundler (from within a nix-shell that has bundler):

```console
$ nix-shell -p bundler
$ bundler package --no-install --path vendor
$ rm -rf .bundler vendor
$ exit  # leave nix-shell
```

... and derive a Nix expression from `Gemfile.lock` like so (be sure to not
accidentally run this command from within the other nix-shell, which would fail
with strange SSL errors otherwise):

```console
$ $(nix-build '<nixpkgs>' -A bundix)/bin/bundix
$ rm result   # nix-build created this (linking to bundix build)
```

... and last but not least we need a `default.nix` file which actually triggers the environment
creation and also automatically starts `jekyll serve` after build:

```nix
with import <nixpkgs> { };

let jekyll_env = bundlerEnv rec {
    name = "jekyll_env";
    ruby = ruby_2_2;
    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;
  };
in
  stdenv.mkDerivation rec {
    name = "jekyll_env";
    buildInputs = [ jekyll_env ];

    shellHook = ''
      exec ${jekyll_env}/bin/jekyll serve --watch
    '';
  }
```

Take note of the `exec` in `shellHook` which actually replaces the shell which `nix-shell` is about
to start by Jekyll itself, so once you stop it by pressing `C-c` the environment is immediately
closed as well.

So we're now ready to just start it all:

```console
[stesie@faulobst:~/Projekte/stesie.github.io]$ nix-shell 
Configuration file: /home/stesie/Projekte/stesie.github.io/_config.yml
            Source: /home/stesie/Projekte/stesie.github.io
       Destination: /home/stesie/Projekte/stesie.github.io/_site
 Incremental build: enabled
      Generating... 
                    done in 0.147 seconds.
 Auto-regeneration: enabled for '/home/stesie/Projekte/stesie.github.io'
Configuration file: /home/stesie/Projekte/stesie.github.io/_config.yml
    Server address: http://127.0.0.1:4000/
  Server running... press ctrl-c to stop.
```
