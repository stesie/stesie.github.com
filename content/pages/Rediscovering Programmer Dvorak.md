---
date: 2024-12-28
tags:
- sway
- Dvorak
description: About 15 years ago, I stumbled upon the Programmer Dvorak keyboard layout, which completely changed how I thought about typing. This Christmas, I decided to see if my fingers still remembered the layout, and to my surprise, they did—better than my mind could! The experience reignited my love for customizing tools, and I even set up my current system to bring back the layout, blending nostalgia with practicality.
status: seedling
title: Rediscovering Programmer Dvorak
categories:
lastMod: 2025-01-12
---
About 15 years ago, I stumbled upon the Dvorak keyboard layout, an alternative to the ubiquitous QWERTY layout designed for ergonomic and efficient typing. During my exploration, I discovered Roland Kaufmann’s blog post on the [Programmer Dvorak Keyboard Layout](https://www.kaufmann.no/roland/dvorak/), which resonated deeply with me. Kaufmann thoughtfully considered the symbols developers frequently use and how they align with the Dvorak philosophy of optimizing for typing efficiency.

Back then, I was using the standard US layout, employing creative methods to access German umlauts—either through AltGr combinations (e.g., AltGr + A for "ä") or dead keys ("ae" for "ä"). However, Kaufmann's insights inspired me to retrain my brain and fingers for Dvorak.

Initially, the transition was frustrating. On QWERTY, I was a decently fast typist, but switching to Dvorak felt like starting from scratch. Over time, my fingers adapted, and Dvorak became my everyday keyboard layout for several years.

In essence, this is what the layout looked like (numbers in natural order, yet still with Shift modifier):
![my "own" keyboard layout](/assets/image_1736084824205_0.png)

## A Pause in the Journey

This phase ended abruptly about six years ago when I joined a client project that required me to use a locked-down Windows laptop. While I could configure the keyboard layout, Programmer Dvorak wasn’t an option—custom layouts were off the table. Reluctantly, I returned to the standard German (DE) layout. The switch felt like letting go of a quirky yet cherished habit, but practicality won.

## A Christmas Experiment

Fast forward to this Christmas break. I found myself wondering: after all these years, could my muscle memory still recall Programmer Dvorak? To my surprise, the answer was a resounding *yes*!

As I sat down to test it, my fingers remembered the layout far better than my conscious mind did. When I overthought it—trying to mentally locate keys—I was prone to mistakes. But when I let my fingers take over, they instinctively found their way to the right keys.

## Customizing My Setup

Alongside this experiment, I started using Sway, a Wayland compositor, and wanted to configure it to support my old layout. After some research, I created an XKB configuration file to define my customized Programmer Dvorak with German umlauts. Here's what I did:

### Step 1: Create the XKB Config File

I placed the following in `~/.xkb/symbols/us-dvp-german-umlaut`:

```xkb
default partial alphanumeric_keys
xkb_symbols "basic" {
	include "us(dvp)"
	include "level3(ralt_switch)"

	name[Group1] = "English (US, Dvorak with German umlaut)";
        key <AE01> { [ ampersand, 1, ampersand, 1 ] };
        key <AE02> { [ bracketleft, 2, bracketleft, 2, currency ] };
        key <AE03> { [ braceleft, 3, braceleft, 3, cent ] };
        key <AE04> { [ braceright, 4, braceright, 4, yen ] };
        key <AE05> { [ parenleft, 5, parenleft, 5, EuroSign ] };
        key <AE06> { [ equal, 6, equal, 6, sterling ] };
        key <AE07> { [ asterisk, 7, asterisk, 7 ] };
        key <AE08> { [ parenright, 8, parenright, 8, onehalf ] };
        key <AE09> { [ plus, 9, plus, 9 ] };
        key <AE10> { [ bracketright, 0, bracketright, 0 ] };
        key <AE11> { [ exclam, percent, exclam, percent, exclamdown ] };
        key <AE12> { [ numbersign, grave, numbersign, grave ] };

        key <AC01> { [ a, A, adiaeresis, Adiaeresis ] };
        key <AC02> { [ o, O, odiaeresis, Odiaeresis ] };
        key <AC03> { [ e, E, EuroSign, cent ] };
        key <AC04> { [ u, U, udiaeresis, Udiaeresis ] };

};
```

### Step 2: Update the Sway Config

In the Sway configuration file, I activated the custom layout for all keyboards:

```sway
input "type:keyboard" {
  xkb_layout us-dvp-german-umlaut
}
```

This setup builds upon the default Programmer Dvorak (`us(dvp)`) layout, reconfigures the top row for natural numeric order, and maps German umlauts to AltGr combinations.

## The Aftermath

While reconnecting with Programmer Dvorak definitely was a nice experiment, ... I switched back to regular German keyboard layout after the Christmas break. While regular typing went decently well, I struggled and didn't feel well with the keyboard shortcuts (for example in IntelliJ), many of them get awkward easily.
