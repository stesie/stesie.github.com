---
layout: post
title: "Custom Keyboard Layout on NixOS, revisited"
tags: [ "NixOS", "Keyboard Layout", "Dvorak" ]
---
Roughly two years ago I already [wrote an article](/2016/08/nixos-custom-keyboard-layout)
on how I configured my customized keyboard layout on NixOS.  Unfortunately this broke
some months ago and so far I never really had the time to track down what's going wrong.
Instead I had a little xmodmap file around, that tweaks the layout after applying the
base layout with `setxkbmap us dvp`.

Of course this was annoying, after each and every `home-manager switch` or
`nixos-rebuild switch` I had to re-apply the changed layout.  Also after (re-)attaching
the USB keyboard, etc.

So I finally sat down, ... at first trying to just override `xorg.xkeyboardconfig`.  Turns
out that still is a bad idea, at least if you don't want to compile large parts of your
system locally.  So there must be a better way, and just touching `setxkbmap` and `xkbcomp`
still feels right.  Yet the xserver itself keeps complaining the layout doesn't exist, even
though `setxkbmap` accepts it.  (and also `nixos-rebuild` itself now complains)

Turns out the `xorgserver` package now provides two extra options
`--with-xkb-bin-directory` and `--with-xkb-path`, ... and that setting both of them is
necessary.  If you just set `--with-xkb-path` then X.org accepts the layout, yet `xkbcomp`
fails since it fetches the correct rules (from the overridden package), yet the wrong symbols
file.  So just override both :)

And to keep `nixos-rebuild` happy also override `xkbvalidate` utility, or specifically:
the `libxkbcommon` dependency of it, so it also has access to the modified rules & symbols.

So my `/etc/nixos/configuration.nix` now looks like this:

```nix
  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "stesie";
    xkbOptions = "lv3:ralt_switch";
  };

  nixpkgs.config = {
    packageOverrides = super: rec {

      xorg = super.xorg // rec {
        xkeyboardconfig_rolf = super.xorg.xkeyboardconfig.overrideAttrs (old: {
          patches = [
            (builtins.toFile "stesie-dvp.patch" ''
                          Index: xkeyboard-config-2.17/symbols/us
                          ===================================================================
                          --- xkeyboard-config-2.17.orig/symbols/us
                          +++ xkeyboard-config-2.17/symbols/us
                          @@ -1557,6 +1557,34 @@ xkb_symbols "crd" {
                             include "compose(rctrl)"
                           };
                           
                          +partial alphanumeric_keys
                          +xkb_symbols "stesie" {
                          +
                          +    include "us(dvp)"
                          +    name[Group1] = "English (Modified Programmer Dvorak)";
                          +
                          +    //             Unmodified       Shift           AltGr            Shift+AltGr
                          +    // symbols row, left side
                          +    key <AE01> { [ ampersand,       1                                           ] };
                          +    key <AE02> { [ bracketleft,     2,              currency                    ], type[Group1] = "FOUR_LEVEL_ALPHABETIC" };
                          +    key <AE03> { [ braceleft,       3,              cent                        ], type[Group1] = "FOUR_LEVEL_ALPHABETIC" };
                          +    key <AE04> { [ braceright,      4,              yen                         ], type[Group1] = "FOUR_LEVEL_ALPHABETIC" };
                          +    key <AE05> { [ parenleft,       5,              EuroSign                    ], type[Group1] = "FOUR_LEVEL_ALPHABETIC" };
                          +    key <AE06> { [ equal,           6,              sterling                    ], type[Group1] = "FOUR_LEVEL_ALPHABETIC" };
                          +
                          +    // symbols row, right side
                          +    key <AE07> { [ asterisk,        7                                           ], type[Group1] = "FOUR_LEVEL_ALPHABETIC" };
                          +    key <AE08> { [ parenright,      8,              onehalf                     ], type[Group1] = "FOUR_LEVEL_ALPHABETIC" };
                          +    key <AE09> { [ plus,            9                                           ], type[Group1] = "FOUR_LEVEL_ALPHABETIC" };
                          +    key <AE10> { [ bracketright,    0                                           ], type[Group1] = "FOUR_LEVEL_ALPHABETIC" };
                          +    key <AE11> { [ exclam,          percent,        exclamdown                  ], type[Group1] = "FOUR_LEVEL_ALPHABETIC" };
                          +    key <AE12> { [ numbersign,      grave,          dead_grave                  ] };
                          +
                          +    // home row, left side
                          +    key <AC01> { [ a,               A,              adiaeresis,      Adiaeresis ] };
                          +    key <AC02> { [ o,               O,              odiaeresis,      Odiaeresis ] };
                          +    key <AC04> { [ u,               U,              udiaeresis,      Udiaeresis ] };
                          +};
                           
                           partial alphanumeric_keys
                                  xkb_symbols "sun_type6" {
                          Index: xkeyboard-config-2.17/rules/evdev.xml.in
                          ===================================================================
                          --- xkeyboard-config-2.17.orig/rules/evdev.xml.in
                          +++ xkeyboard-config-2.17/rules/evdev.xml.in
                          @@ -1401,6 +1401,12 @@
                                   </variant>
                                   <variant>
                                     <configItem>
                          +            <name>stesie</name>
                          +            <description>English (Modified Programmer Dvorak)</description>
                          +          </configItem>
                          +        </variant>
                          +        <variant>
                          +          <configItem>
                                       <name>rus</name>
                                       <!-- Keyboard indicator for Russian layouts -->
                                       <_shortDescription>ru</_shortDescription>
            '')
          ];
        });     # xorg.xkeyboardconfig_rolf

        xorgserver = super.xorg.xorgserver.overrideAttrs (old: {
          configureFlags = old.configureFlags ++ [
            "--with-xkb-bin-directory=${xkbcomp}/bin"
            "--with-xkb-path=${xkeyboardconfig_rolf}/share/X11/xkb"
          ];
        }); 

        setxkbmap = super.xorg.setxkbmap.overrideAttrs (old: {
          postInstall =
            ''
              mkdir -p $out/share
              ln -sfn ${xkeyboardconfig_rolf}/etc/X11 $out/share/X11
            '';
        });

        xkbcomp = super.xorg.xkbcomp.overrideAttrs (old: {
          configureFlags = "--with-xkb-config-root=${xkeyboardconfig_rolf}/share/X11/xkb";
        });

      };        # xorg

      xkbvalidate = super.xkbvalidate.override {
        libxkbcommon = super.libxkbcommon.override {
          xkeyboard_config = xorg.xkeyboardconfig_rolf;
        };
      };
    };
  };
```
