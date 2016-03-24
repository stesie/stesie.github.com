---
layout: post
title: "Polar-korrigiertes Fräsen und Bohren"
category: PyPC-NC
tags: [ "PyPC-NC", "Fablab", "CNC", "Polar-Koordinaten" ]
---
… immer noch auf dem Weg zur selbst erstellten Platine, genauer gesagt beim
Bohren eben dieser. Kürzlich bin ich noch über das Problem gestoßen, dass
man die Platine exakt gerade in die Fräse einlegen muss, dass die Bohrlöcher
auch an der richtigen Stelle im Epoxyd landen und nicht etwa ein paar
Millimeter daneben. Das ist aber gar nicht so einfach …

… die „Softie“-Lösung, bevor ich mir Mühe mit der „Hardware“ geb‘, arbeite
ich doch lieber mit Software um das Problem herum.

Gegeben sei also eine Platine (hier eine „Simulation“ in Form eines simplen
A4-Blatts), die nicht exakt gerade in der Fräse liegt, etwa so:

![Foto schief eingelegtes Frässtück](/assets/images/wpid-20140712_033202.jpg)

… dann muss man dem Controller der Fräse nur noch beibringen, wo zwei frei
gewählte Punkte aus dem G-Code in der Realität liegen. PyPC-NC ermittelt
daraus mittels Polarkoordinaten dann zwei Korrekturwerte: um wieviel Grad
muss gedreht werden und um welchen Faktor ist der Radius zu korrigieren.

![Screenshot von PyPC-NC mit Polar Fix](/assets/images/PyPC-NC-Polar-Fix.png)

… bei der Gelegenheit ist für PyPC-NC eine grafische Darstellung des G-Codes
auf der XY-Plane abgefallen nebst der Möglichkeit den Ursprung der G-Code
Datei nach belieben fest zu legen.
