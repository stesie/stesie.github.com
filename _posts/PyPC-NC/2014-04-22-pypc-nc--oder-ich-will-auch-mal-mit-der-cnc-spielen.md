---
layout: post
title: "PyPC-NC … oder: ich will auch mal mit der CNC spielen"
category: PyPC-NC
tags: [ "PyPC-NC", "Fablab", "CNC" ]
---
Zugegebenermaßen hat mich der CNC-Tisch in unserem Fablab schon eine ganze
Weile gereizt, wenn nicht schon von Anfang an. Vor guten zwei Wochen kam mir
dann die Idee, nachdem ich in den Schränken 7-Segment-Anzeigen in rauen
Mengen liegen sah, mal wieder ein bisschen mit Elektronik zu basteln … und
da war noch das leidige Thema mit den Platinen … aber wir haben jetzt ja
diesen Tisch und da müsste doch was gehen …

Also, Tisch ansteuern.  Aber so einfach ist das nicht, zumindest wenn man
nicht die Windows-Software nutzen möchte, von der wir ohnehin nur eine
einzige Lizenz haben.  Paul hatte sich hieran ja auch schon versucht, vgl.
ältere Posts hier im Blog, … aber sein Projekt ist groß angelegt (er möchte
ja einen Großteil der Ansteuerungselektronik des Tisches ersetzen) und wird
noch eine ganze Weile bis zur Fertigstellung brauchen.

Eine andere Lösung musste her; der Tisch selbst hat ja einen Achscontroller
integriert, warum also nicht den nutzen?  Schließlich hat der auch relativ
intelligente look-ahead Funktionen eingebaut, etc., also bringt’s auch
durchaus Vorteile den zu lassen … nur spricht die Windows-Software ihr
eigenes Protokoll mit dem Achscontroller, das alles andere als
standardisiert und offen ist.

Aber egal, Fablab heißt ja „selber machen“, los ging’s also letzte Woche
Samstag beim Osterbasteln, erste Gehversuche wie man den Achscontroller
ansteuert und das Protokoll zu einem großen Stück reversed.  Genau geguckt,
gelernt, nachmachen, … Software schreiben.  In Anlehnung an das
Windows-Programm WinPC-NC wurde PyPC-NC geboren, die freie Alternative in
Python, … primär für Linux:

![Screenshot von PyPC-NC](/assets/images/IMG_20140419_000324.jpg)

… so sieht’s aus :-)

Optisch nicht gerade ein Leckerbissen, aber funktional und kann soweit alles
was man braucht.  Automatische Referenzfahrt, manuelles Fahren zu einer
beliebigen Position, diese als Werkstückposition speichern und G-Code
importieren um „Fahr-Programme“ aus anderen Anwendungen zu übernehmen.

<div class='media' markdown="1">
<div class='media-right' markdown="1">
![Papier mit Kugelschreiberstrichen](/assets/images/IMG_20140421_232531.jpg)
</div>
In Kombination mit den Linux Anwendungen „gEDA“ und „PCB“ kann man sich dann
ein Platinenlayout entwerfen und via G-Code Export an PyPC-NC übergeben.
Das Ergebnis findet sich hier im Bild rechts (wobei in den Tisch eine 08/15
Kugelschreibermine eingespannt war).
</div>

<div class='media' markdown="1">
<div class='media-left' markdown="1">
  ![Foto der Leiterplatine mit ersten Fräsversuchen](/assets/images/IMG_20140421_232508.jpg)
</div>
Links sieht man erste Fräsversuche auf
einer Leiterplatine, ein paar waren zu tief, manche Bahnen sind echt gut
gelungen.
</div>

Der Teufel steckt wie so häufig im Detail, aktuell gibt’s noch das Problem,
dass das Brett, das als Unterlage im CNC-Tisch liegt sowie die Platine
selbst leicht gebogen sind, … ungünstig wenn man die Platine im 1/100-tel
Millimeter-Bereich genau anfährt.  Mal sehen, kriegen wir auch noch gelöst
:-)

<div class='media' markdown="1">
<div class='media-right' markdown="1">
![Foto eines abgebrochenen Fräsers](/assets/images/IMG_20140422_000548.jpg)
</div>
Ein Opfer gibt es leider jedoch bereits zu beklagen:
 
… dieser Fräsbohrer musste wegen einem Bug in der Software sein Leben
lassen.  In X-Richtung wurde dieser blöderweise fünfmal so schnell
angefahren wie gewollt … das war dann wohl zu viel Druck :-/
</div>

… wir brauchen bald wohl auch einen Satz neue Bohrer …

