---
tags:
- Aider
- systemd
status: seedling
date: 2026-02-02
title: Sandboxing with systemd-run
categories:
lastMod: 2026-02-06
---
So this applies to all coding agents, but I'm just exercising it with *aider* here. TBH I even trust aider pretty much and have more concerns with other beasts like Codename Goose, Claude Code, PI and others ...

... so in order to constrain those tools I first went with Docker ... which felt like a natural choice. Especially since I'm pretty fluent with it ... which I unfortunately still cannot say is true regarding systemd. The problem with the Docker approach is that I would have to install pretty much a full system in that docker container. E.g. to let the agent run a linter, a maven goal, etc.pp ... I'd need to install all that stuff into the docker image

... or just leave away the docker layer, and obviously some more sandboxing it brings to the table, ... but rely on my primary system.

It was new to me that you can use `systemd-run --user` to run "one off" commands like so:

```bash
#!/usr/bin/env bash

# Find the git repository root
git_root=$(git rev-parse --show-toplevel 2>/dev/null)

if [[ -z "$git_root" ]]; then
  echo "Warning: Not in a git repository; assuming current directory"
  git_root="$(pwd)"
fi

if [[ "$git_root" = "$HOME" ]]; then
  echo "Fatal: refusing to launch from HOME, since this would expose everything."
  exit 2
fi

systemd-run --user -t \
  -p PrivateTmp=yes \
  -p ProtectHome=tmpfs \
  -p NoNewPrivileges=yes \
  -p ProtectSystem=strict \
  -p ProtectKernelTunables=yes \
  -p ProtectControlGroups=yes \
  -p BindPaths="$git_root $HOME/.aider.conf.yml $HOME/.aider" \
  -p BindReadOnlyPaths="/nix $HOME/.gitconfig" \
  -p WorkingDirectory="$(pwd)" \
  -E SHELL=${pkgs.bash}/bin/bash \
  -E PATH="$PATH" \
  -- \
  aider "$@"
```

... which mainly does the following

  + mostly hide my whole /home directory (with the exceptions of aider's config and .gitconfig, so it can infer my name/email), using `-p ProtectHome=tmpfs`

  + it also makes sure that e.g. `/run/user` isn't accessible, so the sandboxed process has no access to my SSH/GnuPG agent

  + it searches for the current top-level git directory, and exposes that as a whole **for writing** (falling back to current directory), using `-p BindPaths`

  + it forwards the current directory via `-p workingDirectory` ... otherwise the unit would spawn at the (mostly empty) home directory

  + the `-t` means allocate a pty (like with Docker)

  + last but not least I set SHELL to bash (instead of the fish I regularly use) and I expose the full PATH I have in my user environment ... otherwise systemd would just provide the "bare minimum", which isn't that much on my NixOS installation

## next step

... Nix-ify it :-)

The idea was to let the home-manage module of my NixOS manage wrapper scripts around aider & pi that actually "hide" the real aider binary and just expose me to the wrapper.

For re-usability I first declared a function I import from a `mkSandboxWrapper.nix` file (resembling pretty much the code from above):

```nix
{ pkgs }:

name: bin: additionalPaths:
pkgs.writeShellScriptBin name ''
  cmd_path="${bin}"
  additional_paths="${additionalPaths}"

  # Find the git repository root
  git_root=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null)

  if [[ -z "$git_root" ]]; then
    echo "Warning: Not in a git repository; assuming current directory"
    git_root="$(pwd)"
  fi

  if [[ "$git_root" = "$HOME" ]]; then
    echo "Fatal: refusing to launch from HOME, since this would expose everything."
    exit 2
  fi

  # Build the BindPaths string
  bind_paths="$git_root $HOME/.cache $HOME/.m2"
  if [[ -n "$additional_paths" ]]; then
    bind_paths="$bind_paths $additional_paths"
  fi

  ${pkgs.systemd}/bin/systemd-run --user -t \
    -p PrivateTmp=yes \
    -p ProtectHome=tmpfs \
    -p NoNewPrivileges=yes \
    -p ProtectSystem=strict \
    -p ProtectKernelTunables=yes \
    -p ProtectControlGroups=yes \
    -p BindPaths="$bind_paths" \
    -p BindReadOnlyPaths="/nix $HOME/.gitconfig" \
    -p WorkingDirectory="$(pwd)" \
    -E EDITOR=${pkgs.vim}/bin/vim \
    -E SHELL=${pkgs.bash}/bin/bash \
    -E PATH="$PATH" \
    -- \
    "$cmd_path" "$@"
''
```

then instantiating it like this:

```nix
{ lib, pkgs, ... }:
{

  home.packages = with pkgs; let
    mkSandboxWrapper = import ./mkSandboxWrapper.nix { inherit pkgs; };

    aider-wrapped = mkSandboxWrapper "aider" "${aider-chat}/bin/aider" "$HOME/.aider.conf.yml $HOME/.aider";

    pi-wrapped = mkSandboxWrapper "pi" "${(pkgs.callPackage ./pi-coding-agent {})}/bin/pi" "$HOME/.pi";
  in [
# ...
    aider-wrapped
    pi-wrapped
  ];
}
```
