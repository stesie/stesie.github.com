---
layout: post
title: "Handyhalterung aus PET"
tags: [ "Handyhalterung", "PET", "Fablab", "3D-Druck" ]
---
Mein VW New Beetle hat werkseitig eine Handyvorbereitung … dafür gibt es für
mehr oder weniger viel Geld auch Schalen, die man da reinklipsen kann … die
dann das jeweilige Handy aufzunehmen versprechen.

Aber dafür jetzt nochmal Münzen einwerfen, zumal gut alle Jahr eh ein neues
Handy folgt … weiß nicht. Und Fablab heißt ja auch selber machen.

Also OpenSCAD angeworfen und eine Handyhalterung gezeichnet, die einerseits
mein Samsung Galaxy S5 aufnimmt und andererseits dem Clips-Mechanismus von
VW genügt:

![Screenshot Entwurf Handyhalterung, von vorn](/assets/images/Bildschirmfoto-vom-2015-04-05-015723-640x360.png)

![Screenshot Entwurf Handyhalterung, von hinten](/assets/images/Bildschirmfoto-vom-2015-04-05-020221-640x360.png)

<div class='media' markdown="1">
<div class='media-left' markdown="1">
![Foto vom Ergebnis](/assets/images/wpid-wp-1428191508347-e1428191916225-360x640.jpeg)
</div>
… das ganze dann auf den 3D Drucker gejagt. Als Filament habe ich PET
verwendet — im Gegensatz zu PLA sollte das auch der direkten
Sonneneinstrahlung im Auto längere Zeit trotzen.  Und die Transparenz macht
sich schon auch irgendwie gut …

Einige Fehlversuche später lässt sich das Ergebnis im Auto dann auch
ansehen.
</div>

Learning des Abends: Wenn man im Cura eine „Pause at Z“ einstellt, dann die
Parkposition niemals auf 0 / 0 stellen. Das führt dazu, dass der Druckkopf
satt vorne links an den Anschlag läuft :-/   … zwar nicht mehr weit, sodass
nicht wirklich was passiert (außer dass die Stepper Schritte verlieren und
der Ausdruck dadurch Müll ist), aber trotzdem ein Schreckmoment …
