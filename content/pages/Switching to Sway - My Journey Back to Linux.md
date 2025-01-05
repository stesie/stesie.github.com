---
slug: switching-to-sway
tags:
- sway
- wayland
date: 2025-01-02
title: Switching to Sway - My Journey Back to Linux
categories:
lastMod: 2025-01-03
---
A few days ago, I switched to the [Sway](https://swaywm.org/) window manager after returning to GNU/Linux a few months ago. Before spending a few years in the macOS ecosystem, I was a long-time user of i3. For those unfamiliar, i3 and Sway perform the same function, but i3 is built for X.org while Sway is designed for Wayland. In this post, I’ll share my impressions, lessons learned, and the challenges I faced during this transition.

## The Starting Point

Currently, I’m using Ubuntu Linux version 24.04 (*noble*). Installing Sway was straightforward since it’s packaged for Ubuntu. A simple `apt install sway`, logging out of GNOME, and selecting Sway at the login screen were enough to get started. Having used i3 before, I wasn’t entirely lost.

## Global Keybindings (Media Keys, Power Button, etc.)

As expected, some features didn’t work out-of-the-box as they do in GNOME. However, Sway’s configurability allowed me to tailor things to my liking. For instance:

  + Locking the screen with a hotkey.

  + Putting the laptop to standby when the power button is pressed.

  + Configuring volume and brightness keys.

I dug up my seven-year-old i3 configuration for inspiration and adapted it to Sway. The resulting keybindings look like this:

```
bindsym --locked XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym --locked XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym --locked XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%

bindsym --locked XF86MonBrightnessUp exec sudo brightnessctl s '10%+'
bindsym --locked XF86MonBrightnessDown exec sudo brightnessctl s '10%-'

bindsym --locked XF86PowerOff exec systemctl suspend

bindsym $mod+l exec swaylock -f -c 200020 --clock --indicator-idle-visible
```

## swayidle: Automatic Screen Locking

To ensure the screen locks automatically after five minutes of inactivity, I installed swayidle, which is conveniently available on Ubuntu. However, I quickly missed having an indication of when the lock would occur. This was particularly annoying when I didn’t want the session to lock while still sitting at my desk. The solution? [swaylock-effects](https://github.com/mortie/swaylock-effects). This tool offers additional features, such as `--fade-in` and `--grace` parameters, providing a visual cue and a grace period before locking.

Here’s how it’s configured in my Sway setup:

```
exec swayidle -w \
  timeout 300 'swaylock -f -c 200020 --clock --indicator-idle-visible --fade-in 3 --grace 3' \
  timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
  before-sleep 'swaylock -f -c 200020 --clock --indicator-idle-visible'
```

## Preventing Screen Lock During Video Playback

By default, swayidle doesn’t detect when audio or video is playing. This meant my screen would lock during YouTube videos. The solution was [SwayAudioIdleInhibit](https://github.com/ErikReider/SwayAudioIdleInhibit), a tool that’s not available in Ubuntu’s repositories. After cloning the repository and building it, I added the following line to my configuration:

```
exec sway-audio-idle-inhibit
```

## Automatic Monitor Configuration

Previously, I used autorandr with i3 for automatic monitor configuration. The Wayland equivalent is kanshi, which is also packaged for Ubuntu. After installation (apt install kanshi), I created a `.config/kanshi/config` file:

```
profile home {
  output "Samsung Electric Company U28E850 HTPK300903" mode 3840x2160 position 0,0 scale 2
  output eDP-1 mode 1920x1080 position 1920,0
}

profile laptop-only {
  output eDP-1 mode 1920x1080 position 0,0
}
```


My external monitor runs at 4K with a scale of 2, while the laptop display doesn’t use scaling. To ensure everything starts automatically and to manage workspaces between monitors, I added these lines to my Sway config:

```
bindsym $mod+w focus output HDMI-A-1
bindsym $mod+v focus output eDP-1

bindsym $mod+shift+w move workspace to output HDMI-A-1
bindsym $mod+shift+v move workspace to output eDP-1

exec kanshi
```

## Desktop Notifications

Sway doesn’t include a built-in notification daemon. I chose [mako](https://github.com/emersion/mako), which also required building from source. Adding the following line to my configuration ensures it runs on startup:

```
exec mako
```

## Final Thoughts

Switching to Sway has been an exciting journey filled with challenges and opportunities to learn. While it lacks the "plug-and-play" experience of GNOME or macOS, its flexibility allows for a truly personalized setup. If you enjoy tinkering and configuring your environment to suit your needs, Sway is a fantastic choice.
