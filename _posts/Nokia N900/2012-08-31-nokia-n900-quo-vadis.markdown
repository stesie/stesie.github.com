--- 
layout: post
title: "Quo Vadis Nokia N900?"
tags: [ "Nokia N900", "Android", "Maemo" ]
category: Nokia N900
---
My day-to-day mobile phone still is the [Nokia N900](http://en.wikipedia.org/wiki/Nokia_N900).
Unfortunately the platform is dead for quite some time now and as a matter of fact
there are next to no cool apps like there are for Google's Android.

Hence the fundamental question: stick to Maemo 5 or leave for Android?  I very much appreciate
the openness of the N900 - admittedly there are some proprietary components).
Want to jailbreak?  Just use sudo.  Besides I'm very much into Debian and since Maemo is kindof
derived from it, you can just open up a xterm window and `sudo apt-get dist-upgrade` to do
a full system upgrade.  Want to overclock the phone?  Well, just `kernel-config lock 850` on
the shell.  And last but not least it has got a hardware keyboard which is very useful if
you're typing lots of stuff over the day ...

At least there are Android phones with hardware keyboard like the [HTC's Desire Z](http://www.amazon.de/HTC-Smartphone-Touchscreen-QWERTZ-Tastatur-Branding/dp/B0043232Q0)
or [Sony's Xperia mini pro](http://www.amazon.de/Ericsson-Smartphone-Display-QWERTZ-Tastatur-Touchscreen/dp/B0051XZINU).
Compared to the 805 MHz of my overclocked N900 they both don't have much more processing power.
The Desire Z is clocked at 800 MHz (by default though).  The Xperia runs at 1 GHz.  However
both have twice as much RAM -- a detail of the N900 that really bugs me.  It almost always
uses more than 300 megs of swap space.

After all I decided for the openness.  Having sudo, apt-get, openvpn, iptables etc.pp at
hand is just plain cool and awesome.  In order to have an even cooler phone I'll tackle
the [missing 3pcc call support](https://bugs.freedesktop.org/show_bug.cgi?id=32808) of the
SIP stack soon.  Hopefully with more luck than last time on it...
