---
status: seedling
tags:
- Java
- IntelliJ
- sway
- NixOS
date: 2026-10-09
title: Vanishing Intellij popups with Sway
categories:
lastMod: 2026-10-09
---
After my last NixOS update IntelliJ started behaving weirdly. Not always, just *sometimes*. The autocomplete popup opens, maybe remains open for a keystroke or two. Then suddenly disappears.

Same with the "Copy Path/Reference…" popup from the context menu, the one where you pick absolute path, relative path, package name and so on. Pretty annoying, especially when you're in the middle of typing.

And every time the popup vanished, the whole window seemed to flicker once, as if IntelliJ was reacting to a resize event.

My setup: NixOS, Sway, and IntelliJ already running natively on Wayland via the new WLToolkit (`-Dawt.toolkit.name=WLToolkit` in the custom VM options).

## Wtf closes that popup !?

Under the WLToolkit, popups like autocomplete aren't separate windows. They're `xdg_popup` surfaces attached to the main window, and they hold a so-called *grab*. As soon as the compositor decides that grab is broken, it tells the client via `popup_done` and the popup has to go.

So the first question was: does Sway kill the popup, or does IntelliJ close it on its own? Wayland makes this easy to check, since every client prints its protocol traffic when started with `WAYLAND_DEBUG=1`:

```
WAYLAND_DEBUG=1 idea 2>&1 | grep -e 'popup_done' -e 'xdg_popup.*destroy'
```

```
[2162552.562] {Default Queue} xdg_popup#44.popup_done()
[2162552.738] {Default Queue}  -> xdg_popup#44.destroy()
```

Popup `#44` got a `popup_done` from Sway first ... it's not IntelliJ that's actively destroying it.

## A tiny window ...

So why does Sway think the grab is broken? To find out, I dumped the full log into a file and looked at what happened right before the `popup_done`. Shortened a bit:

```
-> xdg_wm_base#10.get_xdg_surface(new id xdg_surface#54, wl_surface#50)
-> xdg_surface#54.get_toplevel(new id xdg_toplevel#52)
-> xdg_toplevel#52.set_app_id("jetbrains-idea")
...
-> xdg_activation_v1#16.activate("4aff…", wl_surface#50)
...
-> xdg_surface#54.set_window_geometry(0, 0, 35, 26)
...
wl_keyboard#3.leave(7452, wl_surface#23)
xdg_popup#40.popup_done()
```

That is IntelliJ creates a brand-new **toplevel window**. Not a popup, a real window ... yet very small with just 35x26 pixels. Afterwards  asks Sway via `xdg_activation` to activate that window. Keyboard focus moves to the new window ... the actual popup receives `wl_keyboard.leave`, looses focus and gets cleaned away.

That explains the flicker as well. The mini windows ia treated like a regular window and triggers tiling. IDE window shrinks etc.pp

like wtf, what is this windows ?!

Catching that window with `swaymsg -t get_tree` didn't work, it only lives for a fraction of a second. Subscribing to window events did:

```
swaymsg -t subscribe -m '["window"]' | jq -c 'select(.change=="new") | .container | {app_id, name}'
```

```
{"app_id":"jetbrains-idea","name":null}
```

## Detour: window rules

No title, `app_id` same as the main window. Ok, let's just not auto-focus it and forcefully make it floating:

```
swaymsg 'no_focus [app_id="^jetbrains-" title="^$"]'
swaymsg 'for_window [app_id="^jetbrains-" title="^$"] floating enable'
```

Well … turns out the main window is also mapped without a title and only gets one a moment later. So now the IDE itself was floating 🙈

Next attempt: a second rule that undoes the floating once a title shows up (`title="."`). Fixes the main window, but then settings dialog is floating as well. Grrr....

## wtf expansion hints

But with the window rules in play and simply watching more closely *when* it happens. It's perfectly reproducible with autocomplete: select an entry that's longer than the popup is wide. IntelliJ then wants to show the full text, and for that it opens … exactly, **an extra little window next to the popup**.

**These are the so-called expansion hints.**

Open the Action panel, search for **Registry…**, search for `ide.expansion.hints.enabled` and turn them _off_.

No more mini window, no more stolen focus, no more vanishing popups 🥳
