---
layout: post
title: "Nervenfräse"
category: PyPC-NC
tags: [ "PyPC-NC", "Fablab", "CNC", "Polar-Koordinaten" ]
---
Bernd war heute da und irgendwann kam die Idee auf, die CNC zu nutzen um
seinen nickname auf einen USB-Stick zu gravieren.

Gesagt, versucht, gescheitert. Die Idee war zunächst mit Inkscape den
Schriftzug zu erstellen und den Pfad als G-Code zu exportieren. PyPC-NC hat
den Schriftzug ein bisschen verstümmelt:

![Foto 1. Versuch](/assets/images/wpid-20140719_001325.jpg)

Wie sich beim Debuggen zeigte war die Polar-Koordinaten gestützte Korrektur
noch nicht fehlerfrei. Nach einigen Versuchen sah es dann deutlich besser
aus:

![Foto ein paar Versuche später](/assets/images/wpid-20140719_021722.jpg)

… der letzte Versuch mit einem Streckfaktor von zwei und phi von 45°.

