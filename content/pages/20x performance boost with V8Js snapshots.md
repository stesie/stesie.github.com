---
slug: snapshot-performance
date: 2016-02-29
tags:
- V8Js
- V8 Heap Snapshots
- performance
category: V8Js
title: 20x performance boost with V8Js snapshots
categories: V8Js
lastMod: 2025-01-03
---
Recently @virgofx [filed an issue](https://github.com/phpv8/v8js/issues/205) on V8Js whether (startup) performance of V8Js could be increased. He wants to do server-side React rendering and noticed that V8 itself needs roughly 50ms to initialize and then further 60ms to process React & ReactServer javascript code. Way too much for server side rendering (on more or less every request).

Up to V8 4.4 you simply could compile it with snapshots and V8Js made use of them. With 4.4 that stopped (V8Js just kept crashing), and I never really cared what they could do nor what the performance hit of this is, I just disabled them.

... turns out there even are three modes:

  + no snapshots at all (what I did then)

  + snapshots support enabled, with *external* snapshot data (the default)

  + snapshots support enabled, with *internal* snapshot data (the snapshots are then linked into the library itself)

Those snapshots are created once at compile time and store the state of V8's heap after it has fully initialized itself. Hence their benefit is that the engine doesn't fully bootstrap over and over, ... it simply restores the snapshot and is (almost) ready to start.

Only the second of those three modes wasn't supported by V8Js, since it simply didn't provide the external startup data -- and hence V8 failed to start.

Digging deeper into snapshots I found out about [custom startup snapshots](http://v8project.blogspot.de/2015/09/custom-startup-snapshots.html). V8 since version 4.3 allows extra JavaScript code to be embedded into the snapshot itself. This is you can bake React & ReactServer right into the snapshot so it doesn't have to re-evaluate the source over and over again.

The performance impact of this is enormous:

![performance comparison](/assets/snapshot-speed.png)

The Y-axis shows milliseconds, the blue bar the amount of time needed by V8 to bootstrap, the red bar time needed to evaluate React & ReactServer source code. Timings are averages over 100 samples taken on my Core i5 laptop.

I compiled V8 5.0.104 with snapshot support, hence the blue bar immediately drops from about 60 ms down to about 4 ms. Since the base snapshots doesn't have React included, the red bare remains at ~90 ms at first.

... including React into the snapshot, the red bar of course is gone, bootstrapping takes a little longer then -- but it is many times faster than without snapshots.
