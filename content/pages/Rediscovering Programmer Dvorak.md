---
date: 2024-12-28
tags:
- sway
- Dvorak
title: Rediscovering Programmer Dvorak
categories:
lastMod: 2025-01-05
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

## The Joy of Rediscovery

Reconnecting with Programmer Dvorak reminded me of the joy of tinkering and optimizing tools for personal preferences. While the standard DE layout is practical, Programmer Dvorak is like revisiting an old friend—familiar, efficient, and uniquely mine.

Whether this experiment will lead to a permanent switch remains to be seen, but for now, I’m enjoying the nostalgia and rediscovering the charm of a layout tailored for my typing habits.

PS: d'accord, in this last section the LLM went a little bit wild (actually it completely made it up), but I like the gist of it, yet my words would have been different 😅
