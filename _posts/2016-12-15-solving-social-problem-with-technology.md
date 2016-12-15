---
layout: post
title: "solving social problems with technology"
tags: [ "lightbar", "ws2812", "pomodoro" ]
---
So I'm living together with my girlfriend for quite a while now, but there's
that one thing why we regularly get mad at each other: I'm sitting at my desk
in the living room *coding* and she keeps talking to me every now and then,
interupting my thoughts over and over ... and me slowly getting more and more
annoyed ... and then she complains why I once more didn't tell here that I'm
trying to concentrate and if I just had told her ...

As I'm practicing [pomodoro technique](https://en.wikipedia.org/wiki/Pomodoro_Technique)
(primarily to regularly take breaks and not sitting at my desk for hours
straight) I already have the information.  Starting work I hit `S-p` hotkey and
the pomodoro clock ticks down from 25 minutes to zero.

Wouldn't it be great if only that information was available to my girlfriend?
So I took one meter of WS2812 LED strip at 30 LEDs per meter, attached it to
a bar made of cardboard and soldered a [D1 mini](https://www.wemos.cc/product/d1-mini.html) to it ...

problem solved, here's what it looks like:

![photo of the lightbar in pomodoro mode](/assets/images/pomodorobar.jpg)

At the beginning it shows 25 red LEDs followed by five green ones; clearly
showing that I would not want to be interrupted.

The software part of the D1 mini is pretty simple, it just connects to my
local [MQTT broker](https://mosquitto.org/); ... and the shell script which 
is triggered by the aforementioned keyboard shortcut now just also publishes to
the lightbar control topic.

... and being at it I kept improving the software, adding various modes
of ambient and attraction light modes :)

PS: and as I'm now already publishing the pomodoro information to MQTT
the next step is to automatically switch my cell phone & tablet into
DND mode during the work-phase of every pomodoro.  Unfortunately turns
out that that isn't as easy going as expected as there's no Tasker plugin
that's able to subscribe to a MQTT topic.
[Just some discussion on Reddit](https://www.reddit.com/r/tasker/comments/53qubt/mqtt_subscriber_plugin/).
