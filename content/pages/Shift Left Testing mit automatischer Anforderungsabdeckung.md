---
tags:
- Fachfunktion
- Shift Left Testing
- SoCraTes Day Franken
date: 2025-01-12
status: seedling
title: Shift Left Testing mit automatischer Anforderungsabdeckung
categories:
lastMod: 2025-01-12
---
Am 29. Juni war ich auf dem wunderbaren [6. SoCraTes Day Franken](https://socrates-day-franken.de/Home) (große Empfehlung, falls es eine nächste Version geben wird). In der Session „Shift Left Testing“ von Felix Tensing beleuchtete er die Herausforderungen und seine Lösungsansätze im Bereich der Software-Anforderungsabdeckung. Hierbei stellte er sein Konzept vor, das speziell das Problem von inhaltlich veralteten oder unvollständigen Jira-Tickets adressiert.

## Problemstellung

Jira-Tickets oder ähnliche Systeme dienen dazu, Anforderungen und Aufgaben im Entwicklungsprozess festzuhalten. Allerdings haben sie grundsätzliche Schwächen:

  + **Vergangenheitsbezug**: Tickets spiegeln oft nur den Status zum Zeitpunkt ihrer Erstellung wider und repräsentieren nicht, was die Software aktuell tut oder tun soll.

  + **Unvollständigkeit**: Tickets dokumentieren meist nur die Anforderungen des Product Owners (PO). Wenn Entwickler:innen aus guten Gründen von der ursprünglichen Planung abweichen, wird dies nicht zwangsläufig im Ticket nachgehalten.

  + **Bug-Tracking**: Beim Auftreten von Fehlern müssen oft zahlreiche Tickets zurückliegend überprüft werden, um die relevante Historie zu rekonstruieren.

## Lösung: Fachfunktionen

Felix präsentierte als Lösungsansatz das Konzept der **Fachfunktionen**. Diese sind langlebige, eindeutige Einheiten, die Anforderungen, ihre Umsetzung und Tests zusammenführen.

![Foto vom Beamer: Was ist eine Fachfunktion?](/assets/signal-2024-06-29-220711_003_1719694678170_0.jpeg)

### Eigenschaften der Fachfunktionen

  + **Eindeutige Kennung**: Jede Fachfunktion erhält eine eindeutige ID, die nicht wiederverwendet wird.

  + **Lebendiges Dokument**: Fachfunktionen werden kontinuierlich gepflegt und aktualisiert.

  + **Akzeptanzkriterien (AK)**: Sie bestehen aus einer Reihe von Akzeptanzkriterien: Ursprünglich vom PO formuliert. Durch die Entwickler:innen detailliert und ergänzt.

  + **Evolution durch Stories**: Neue Stories referenzieren bestehende Fachfunktionen und aktualisieren deren Akzeptanzkriterien, z. B. durch Hinzufügen oder Streichen von Kriterien.

### Struktur der Fachfunktion

Eine Fachfunktion setzt sich aus zwei Teilen zusammen:

**Kurz- und Langbeschreibung**: Enthält eine Beschreibung der Funktionalität, dokumentiert in AsciiDoc, was die Integration von frei strukturierten Inhalten wie Tabellen ermöglicht.

**Tabelle der Akzeptanzkriterien**:

  + Enthält eine Kurzbeschreibung sowie Links zu automatisierten Tests (hauptsächlich Unit- oder Integrationstests).

  + Kriterien sind spezifisch für ein Modul und vermeiden End-to-End-Abhängigkeiten. Dadurch bleiben sie auch für frühere Git-Versionen valide.

### Beispiel

![Foto vom Beamer: Beispiel einer Fachfunktion](/assets/signal-2024-06-29-220711_005_1719693657952_0.jpeg)

### Technische Umsetzung

  + **AsciiDoc und YAML**: Der Prosa-Teil der Fachfunktion wird in AsciiDoc verfasst, die Akzeptanzkriterien in YAML abgelegt.

  + **Annotationen in Tests**: Tests werden direkt mit den entsprechenden Fachfunktions-IDs annotiert.

  + **Build-Prozess**: Die Inhalte aus AsciiDoc und YAML werden zu einem finalen AsciiDoc-Dokument zusammengeführt und in verschiedene Formate wie HTML gerendert.

## Innovative Nutzung von Storybook

Als Viewer für die gerenderten Fachfunktionen wird **Storybook** eingesetzt. Jede Fachfunktion wird dabei als Story oder Komponente abgebildet. Vorteile:

  + **Transparenz**: Die Storybook-Instanz zeigt den aktuellen Stand der Fachfunktionen an, passend zur jeweiligen Umgebung.

  + **Deployment**: Storybook wird auf den Umgebungen deployed, um den Zustand der implementierten Fachfunktionen unmittelbar sichtbar zu machen.

## Zusätzliche Integration

Ein Publikumsvorschlag betraf die Einbindung von **Architectural Decision Records (ADRs)**. Diese könnten in das System integriert werden, um Architekturentscheidungen nachvollziehbar mit Fachfunktionen zu verknüpfen.

## Fazit

Das Konzept der Fachfunktionen bietet einen innovativen Ansatz, um die oft statische und unvollständige Dokumentation von Anforderungen zu überwinden. Durch die Kombination aus lebendiger Dokumentation, automatisierten Tests und modernen Tools wie Storybook können Entwicklungsteams effizienter und transparenter arbeiten.
