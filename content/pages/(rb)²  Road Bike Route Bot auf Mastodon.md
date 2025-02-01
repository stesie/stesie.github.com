---
date: 2022-05-09
tags:
- Bot
- Geodaten
- Mastodon
- OpenStreetMap
canonicalurl: https://blog.mayflower.de/12803-mastodon-bot.html
showcanonicallink: true
status: evergreen
title: (rb)² – Road Bike Route Bot auf Mastodon
categories:
lastMod: 2022-05-09
---
Ein Erfahrungsbericht, weil ich …

  + mal wieder was mit Geodaten machen wollte (und mich OpenStreetMap schon eine ganze Weile immer wieder umtreibt)

  + schon länger darüber nachdenke, wie gut es wohl funktioniert, einen zufälligen Fahrrad-Routenvorschlag nach eigenem Gusto zu erzeugen

  + schon länger im Fediverse (Mastodon) bin und während des Alle-Verlassen-Twitter-Hypes einen Bot zu bauen nahe liegt

Also los geht’s. How hard can it be?

Zunächst soll nicht unerwähnt bleiben, dass Dienste wie Strava erlauben, eine zufällige Route zu erzeugen; meinen Geschmack treffen die Ergebnisse jedoch eher selten. Wenn man “nur Straße” auswählt, wird man häufig über Staats- und teilweise auch Bundesstraßen geführt, was ich (insbesondere alleine) ätzend finde.

## Kartenmaterial

Ganz grundsätzlich brauchen wir zunächst einmal Kartenmaterial, weil eine Route ohne Straßen und Karte nicht funktioniert. Zum Glück gibt es das großartige Projekt [OpenStreetMap](https://openstreetmap.org/), bei dem viele Freiwillige Kartendaten zusammen tragen. Meist in sehr hoher Qualität, und das auch was Nebenstraßen angeht. Und gerade dort macht es mit dem Rad auch einen großen Unterschied, wie es um Belag und Oberflächenbeschaffenheit bestellt ist.

OpenStreetMap ist erstmal eine große Datenbank, in der alle möglichen Informationen “gemapped” sind. Das geht beim Offensichtlichen los: Straßen und Häuser. Umfasst aber auch Gleise, Läden & Cafes, Stromtrassen, Bushaltestellen, Glascontainer, Mülleimer, Bänke … kurzum alles, was irgendwie mit Geodaten zu tun hat und zu dem sich bisher Freiwillige fanden, es einzupflegen. An diesen Elementen hängen dann mit Schlüssel-Wert-Paaren weitere Informationen, wie beispielsweise Straßenbelag, Wegbeschaffenheit, Gehsteig vorhanden, Beleuchtet, etc.

Uns interessieren davon erstmal nur Wege. Und da nur die Typen `highway` (Straße), `track` (sonstige Wege) und `path` (Pfade). Die Straßen sind dabei weiter detailliert, sodass man Bundesstraßen (`primary`), Staatsstraßen (`secondary`), Kreisstraßen (`tertiary`), Ortsverbindungsstraßen (`unclassified`), etc. auseinanderhalten kann.

## Ein (naiver) erster Ansatz

Wir haben einen Startpunkt und eine grobe Idee von der Streckenlänge. Anschließend …

1. berechnen wir den Radius eines Kreises, der im Umfang der gewünschten Streckenlänge entspricht

2. wählen wir einen zufälligen Kreis dieses Radiuses, der unseren Startpunkt schneidet (damit bestimmen wir die Himmelsrichtung in die die Runde geht)

3. wählen wir fünf zufällige Checkpoints, die auf diesem Kreis liegen (wobei einer der Startpunkt ist)

4. suchen wir für jeden Checkpoint einen Punkt, den wir potentiell anfahren wollen/können (anders ausgedrückt: suche den nächst gelegenen Punkt, der auf einer Kreis- oder Ortsverbindungsstraße liegt – schließlich wollen wir nicht viermal auf den Acker laufen)

5. suchen wir eine Route von Checkpoint zu Checkpoint

… damit haben wir eine Route. Um diese dann auf Mastodon zu bringen, brauchen wir einerseits einen API-Client, andererseits noch eine Möglichkeit, die Route auf einer Karte darzustellen. Weil ohne Bild wäre der Tröt (“Tweet” in Mastodon-Lingo) wenig attraktiv.

## Bestandsaufnahme

Nachdem wir das nicht alles selbst bauen wollen, brauchen wir im Wesentlichen also

  + einen “fernsteuerbaren” Router

  + eine Möglichkeit, wie wir die nächstgelegene geeignete Straße zu einem gegebenen Punkt finden können.

Besagter Router muss nicht nur skriptbar sein und auf OpenStreetMap fußen, sondern soll flexibel/clever genug sein was die Streckenauswahl betrifft und – optional – auch das Höhenprofil berücksichtigen.

Hier kommt [BRouter](https://brouter.de/) ins Spiel. Das ist eine Java-Anwendung (ursprünglich für Android), die man mit einem Routing-Profil füttern kann, und dann via HTTP die “beste” Strecke zwischen zwei (oder mehr) Punkten abfragen kann.
Besagter BRouter bringt auch gleich ein Profil mit dem tollen Namen [fastbike-verylowtraffic](https://github.com/abrensch/brouter/blob/master/misc/profiles2/fastbike-verylowtraffic.brf) mit, das genau das tut was es verspricht: nur befestigte Wege, wenn möglich Kreis- oder Ortsverbindungsstraßen und Radwege. Standardmäßig ohne Berücksichtigung der Höhenmeter, das kann man auf Wunsch jedoch aktivieren.

Bei der initialen Suche nach geeigneten Checkpoints bietet sich die [Overpass API](http://overpass-api.de/) an. Dieser kann man beliebige Anfragen in einer speziellen Abfragesprache ([Overpass Query Language](https://wiki.openstreetmap.org/wiki/Overpass_API/Overpass_QL)) stellen. Im einfachsten Fall die Suche nach z. B. einem Geldautomaten in einem bestimmten Bereich (typischerweise rechteckig). Es gibt jedoch auch einen `around`-Filter, mit dem man Objekte relativ zu anderen Elementen suchen kann.

Die Abfrage selbst wirkt zunächst arkan:

```
    [out:json];
    (way
        [highway~'tertiary|unclassified']
        (around:1000.0,49.84178672462459,10.06466533810437);
        >;
    );
    out;
```

Sehen wir uns die Abfrage genauer an:

  + wir fordern eine Antwort in JSON (statt XML)

  + suchen einen/alle Weg/e

    + mit Attribut `highway=tertiary` oder `highway=unclassified`

    + im Umkreis von 1000 Metern um einen gegebenen Punkt

  + von den so selektierten Wegen sollen sodann die Punkte (aka parents) abgefragt werden (`>;`)

  + und das Ergebnis wollen wir auch haben (`out;`)

## Umsetzung

Meine Lieblingsprogrammiersprache ist TypeScript. Eine kurze Recherche hat gezeigt, dass es gut gepflegte NPM-Module zum Ansprechen von Overpass (`overpass-ts`) und für erdräumliche Berechnungen (`@turf/turf`) gibt.

Alle Funktionen von `turf` basieren auf GeoJSON, einem offenem Format, um eben geografische Daten in Form sog. Features zu repräsentieren. Solche Features können dann Punkte, Linien oder Polygone sein.

Um den Ablauf des Skriptes transparenter zu bekommen, bietet es sich an, sämtliche Zwischenschritte als GeoJSON-`FeatureCollection` abzuspeichern. Unter geojson.io findet sich ein Online-Viewer, in den man jenes GeoJSON dann kopieren (und sodann betrachten) kann.

An diesem lässt sich dann gut erkennen, wie die Anwendung Schritt für Schritt vorgeht:

![Vorschau über geojson.io](/assets/mastodon-bot_1.jpg)

## Was passiert hier eigentlich?

Sehen wir uns nun einmal im Detail an, was auf diesem Bild alles zu sehen ist:

1. der Startpunkt (= grauer Marker) direkt in Würzburg

2. Kreis um diesen ziehen und einen Punkt davon als Routenmittelpunkt bestimmen (= grüner Marker)

3. Kreis um den grünen Marker bestimmen und fünf Checkpunkte auf diesem festlegen (= graues Polygon)

4. für alle Ecken (mit Overpass) die nächstgelegene (geeignete) Straße finden (= gelbliche Marker/Polygon)

5. mit BRouter Routen zwischen ebendiesen Punkten erstellen (= rote Linien)

6. “dead ends” entfernen, also Wege, die zu gelben Markern führen und dann direkt wieder zurück (= rote Marker)

Die Koordinaten von Startpunkt und (korrigierten) Checkpoint-Markern können wir dann ein letztes mal dem BRouter füttern, der daraus eine GPX-Datei zaubert. GPX (= GPS Exchange Format) ist ein offenes XML-Format, mit dem Routen beschrieben werden können und das von den üblichen GPS-Geräten verstanden wird.

Der o.g. Viewer für GeoJSON kann übrigens, trotz des Namens, auch GPX laden.

## Grafik rendern

Ein Tröt ohne Bild ist langweilig. Aber wie bekommen wir einen Screenshot einer Karte mit unserer Route darauf?

Vielleicht nicht die effizienteste Lösung, aber zumindest straight forward: wir nehmen einfach einen Browser plus die Standard-JavaScript-Library zum Kartenrendering: [Leaflet](https://leafletjs.com/) nebst [GPX-Track-Plugin](https://github.com/mpetazzoni/leaflet-gpx).

Nun brauchen wir nur noch etwas, das uns den Screenshot auf Kommando anfertigt: [Googles Rendertron](https://github.com/GoogleChrome/rendertron). Rendertron kann man auch wieder einfach per HTTP aufrufen, die URL übergeben (+ gewünschte Größe) und bekommt den Screenshot im JPG-Format zurück.

![Unsere fertig gerenderte Route.](/assets/mastodon-bot_2.jpg)

## Automatisch Tröten

Jetzt brauchen wir noch einen (Bot-)Account auf der Mastodon-Instanz unserer Wahl. In meinem Fall ist das [wue.social](https://wue.social/). Und ein CLI-Tool, mit dem wir Route nebst Bild tröten können: [toot](https://toot.readthedocs.io/en/latest/index.html).

Das Ergebnis all der Arbeit? Ein Tröt:

![… und fertig ist der Tröt.](/assets/mastodon-bot_3.jpg)

Damit kann unser Mashup auf die Zielgerade: noch ein bisschen Docker und ein paar Cronjobs – fertig ist der Bot :-)

## … und der ganze Rest

Natürlich kann ich euch viel erzählen – ihr könnt euch aber auch selbst vom Bot überzeugen:

Profilseite des Bots: [@rbrb](https://wue.social/web/@rbrb)

[Quellcode des Projekts](https://github.com/stesie/routebot)
