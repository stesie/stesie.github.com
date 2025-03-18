---
status: seedling
tags:
- IntelliJ
- Wayland
- TIL
date: 2025-03-18
category: TIL
title: Wayland Support in IntelliJ
categories: TIL
lastMod: 2025-03-18
---
Today I learned, that IntelliJ has support for [Wayland Compositor since version 2024.2](https://blog.jetbrains.com/platform/2024/07/wayland-support-preview-in-2024-2/), so seems like im rather late to the game.

Simply go to Help > Edit custom VM options and add `-Dawt.toolkit.name=WLToolkit`.

For me it so far works nicely. And the issue of some overlay windows (like object inspector) not being resizable in Sway ... are just gone. Yay 🥳
