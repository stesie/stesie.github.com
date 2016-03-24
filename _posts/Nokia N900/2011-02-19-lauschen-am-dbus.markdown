--- 
layout: post
title: Lauschen am DBus
date: 2011-02-19 03:54:35 +01:00
category: Nokia N900
---
... nachdem man schon mit den folgenden, wenigen Zeichen Notifications auf dem geliebten Nerdphone N900 einblenden kann:
<pre>#!/usr/bin/env python
import dbus
if __name__ == '__main__':
    bus = dbus.SessionBus()
    remote_object = bus.get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications")
    iface = dbus.Interface(remote_object, "org.freedesktop.Notifications")
    iface.Notify('', 0, '', 'Hallo', 'ruf mich an!', [], [], -1)</pre>
kam auf dem zerties.org-Treff <span style="text-decoration: line-through;">heut</span>gestern die Frage auf, wie schwer es wohl sei, eine Nachricht, die an den Desktop Notification Daemon geht (org.freedesktop.Notifications.Notify) abzufangen und zusätzlich selbst weiter zu verarbeiten.  Die Idee ist hier, dass man die Nachricht vorlesen lassen könnte, wenn man bspw. im Auto sitzt.  Ist dann doch eher unpraktisch, wenn man nur mitbekommt, dass das Handy in der Tasche vibriert.

Wie man das mit Python implementieren könnte habe ich bis jetzt noch nicht herausgefunden, daher habe ich mir den Code von <em>dbus-monitor</em> geschnappt und das Gewünschte noch dazugefrickelt, das Kind heißt jetzt <a href="http://brokenpipe.de/misc/notify-listen.c">notify-listen</a> als Pendant zu <em>notify-send</em> aus dem Paket <em>libnotify-bin</em>.

Damit sind die ersten Hürden im Umgang mit DBus genommen.  Ich habe ja noch das Ziel den von mir selbst reporteten Bug in telepathy-sofia-sip zu fixen ... aber das ist ja ein komplexes Monster aus DBus und GStreamer...
