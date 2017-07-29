---
layout: post
title: "Using KeePassHttp plugin on NixOS"
tags: [ "KeePass", "plugin", "KeePassHttp", "NixOS" ]
---
I'm a long time user of KeePass 2 password manager, even so it
is actually a Windows .NET application, that runs on Mono.  It has
two feature that are important to me, that the KeePass for Linux lacks:

* synchronize the underlying file on save (I share the .kdbx file using ownCloud),
  instead of just overwriting it (eliminating changes to the database from other hosts)
* reference credentials from other entries

... and as I'm back on NixOS, I of course wanted to have KeePass with the
KeePassHttp for Chromium integration.  On Ubuntu installation is trivial,
KeePass itself is packaged, you take the plugin's .plgx file and put it (as
root) next to the KeePass.exe file somewhere under `/usr/share`.

Oh well, `/nix/store` is read-only, hence different approach needed.

Turns out that `keepass2` NixOS package already has a `plugin` field, which
just is set to an empty list.  Therefore once you got the syntax it's pretty
straight forward...

That's what my `/etc/nixos/configuration.nix` file looks like (relevant parts):

```nix
{ config, pkgs, ... }:

let

  keepassWithPlugins = pkgs.keepass.override {
    plugins = [
      pkgs.keepass-keepasshttp
    ];
  };

in

{
  # ... primary part of configuration.nix goes here ...

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [

    # ... other packages ...
    keepassWithPlugins
  ];
}
```

