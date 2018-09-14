---
layout: post
title: "Customizing my Keyboard Layout on NixOS"
tags: [ "NixOS", "Keyboard Layout", "Dvorak" ]
---
{: .info}
*UPDATE*: The exact methodology shown here does *not work anymore*.
See [here](/2018/09/nixos-custom-keyboard-layout-revisited) for an updated version.

Here's one missing write-up on a problem I immediately faced after reinstalling
my Laptop with NixOS: my customized keyboard layout was missing.
I'm using [Programmer Dvorak](http://www.kaufmann.no/roland/dvorak/) for a
prettly long time now.  But I usually apply two modifications:

* rearrange the numbers 0..9 from left to right (as on a "normal" keyboard,
  just using shift as modifier key)
* add German umlauts to A, O and U keys (on modifier level 3)

... and use AltGr as modifier key to access level 3.

On Ubuntu I had a Puppet module around that used some augeas rules to
patch `/usr/share/X11/xkb/symbols/us` as well as `evdev.xml` along it.
There are several problems with this on NixOS after all: I don't have
puppet modifying system state, but the system is immutable. And after
all there's simply no such file :)

So pretty obviously modifying the keyboard layout is more involved on
NixOS.  I pretty quickly came to the conclusion that I would have to
patch `xkeyboard-config` sources and use some form of package override.

Yet I had to tackle some learning curve first ...

* you cannot directly override `xorg.xkeyboardconfig = ...` as that
  would "remove" all the other stuff from below `xorg`.  The trick is to override
  xorg with itself and merge in a (possibly recursive) hash with a changed
  version of `xkeyboardconfig`.
* overriding `xorg.xkeyboardconfig` completely also turned out to be a bad idea
  as its indirectly included in almost every X.org derivation (so `nixos-rebuild`
  wanted to recompile LibreOffice et al -- which I clearly didn't want it to do)
* almost close to frustration I found [this configuration.nix Gist](https://gist.github.com/binarin/380eda7b08a1c230abbc186887fc5823) where someone obviously tries to do just the same -- but the Gist doesn't have many searchable terms (actually it's just code), so it was really hard to find :)   ... his trick is to use overrideDerivation based on `xorg.xkeyboardconfig` but store it in a different variable.  Then derive `xorgserver`, `setxkbmap` and `xkbcomp` and just use the modified xkeyboard configuration there

So here's my change to `/etc/nixos/configuration.nix`:

```nix
  nixpkgs.config.packageOverrides = super: {
    xorg = super.xorg // rec {
      xkeyboard_config_dvp = super.pkgs.lib.overrideDerivation super.xorg.xkeyboardconfig (old: {
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
                           '')   # }
        ];
      });

      xorgserver = super.pkgs.lib.overrideDerivation super.xorg.xorgserver (old: {
        postInstall = ''
          rm -fr $out/share/X11/xkb/compiled
          ln -s /var/tmp $out/share/X11/xkb/compiled
          wrapProgram $out/bin/Xephyr \
            --set XKB_BINDIR "${xkbcomp}/bin" \
            --add-flags "-xkbdir ${xkeyboard_config_dvp}/share/X11/xkb"
          wrapProgram $out/bin/Xvfb \
            --set XKB_BINDIR "${xkbcomp}/bin" \
            --set XORG_DRI_DRIVER_PATH ${super.mesa}/lib/dri \
            --add-flags "-xkbdir ${xkeyboard_config_dvp}/share/X11/xkb"
          ( # assert() keeps runtime reference xorgserver-dev in xf86-video-intel and others
            cd "$dev"
            for f in include/xorg/*.h; do # */
              sed "1i#line 1 \"${old.name}/$f\"" -i "$f"
            done
          )
        '';
      }); 
  
      setxkbmap = super.pkgs.lib.overrideDerivation super.xorg.setxkbmap (old: {
        postInstall =
          ''
          mkdir -p $out/share
          ln -sfn ${xkeyboard_config_dvp}/etc/X11 $out/share/X11
          '';
      });
  
      xkbcomp = super.pkgs.lib.overrideDerivation super.xorg.xkbcomp (old: {
        configureFlags = "--with-xkb-config-root=${xkeyboard_config_dvp}/share/X11/xkb";
      });
    };
  };
```

After a `nixos-rebuild switch` I was able to `setxkbmap us stesie` to have
my modified layout loaded.  Last but not least I switched the default
keyborad layout in `configuration.nix` like so:

```nix
  services.xserver.layout = "us";
  services.xserver.xkbVariant = "stesie";
  services.xserver.xkbOptions = "lv3:ralt_switch";
```
