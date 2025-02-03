---
date: 2025-02-03
status: seedling
category: TIL
tags:
- Chromium
- Kagi
- TIL
title: Chromium Site Search
categories: TIL
lastMod: 2025-02-03
---
Pretty likely this is a well-known thing to many 🥱, and to be honest, I also kindof knew that Chromium has some search shortcuts, but I never bothered to learn how to use them. To even add to that, I'm even well aware that I quite regularly went to pages like dict.leo.org, and used the search feature there. Or I went to our Jira instance, and used the search feature there, regularly just typing a ticket number. Always with that annoying intermediate step. But so far I never cared ...

Today I also started a trial period of [kagi search engine](https://kagi.com/), and therefore bothered to change the default search engine of my Chromium browser. Which is why I navigated to the search engine configuration page (`chrome://settings/searchEngines`).

... and there you have it, the "Site search" headline. And there's also this "Inactive shortcuts" section. And wait, it already lists our Jira instance!? And dict.leo.org!? Where do these come from?

## OpenSearch description format

The first clue is in the `<head>` part of dict.leo.org's HTML code:
```html
<link rel="search" type="application/opensearchdescription+xml" href="/pages/helpers/shared/searches/opensearch_ende_de.xml" title="LEO Eng-Deu"/>
```

... and if you follow that href, then you'll find the following XML structure:

```xml
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <ShortName>LEO Eng-Deu</ShortName>
  <Description>Verwenden Sie LEOs Englisch-Deutsch Online Wörterbuch um einzelne Wörter oder Phrasen vom Englischen ins Deutsche (oder umgekehrt) zu übersetzen.</Description>
  <Image height="16" width="16" type="image/x-icon">https://dict.leo.org/img/favicons/ende.ico</Image>
  <Url type="text/html" method="get" template="https://dict.leo.org/englisch-deutsch/{searchTerms}"/>
  <Url type="application/x-suggestions+json" method="get" template="https://dict.leo.org/dictQuery/m-query/conf/ende/query.conf/strlist.json?q={searchTerms}&sort=PLa&shortQuery&noDescription&noQueryURLs"/>
  <Url type="application/opensearchdescription+xml" rel="self" template="https://dict.leo.org/pages/helpers/shared/searches/opensearch_ende_de.xml"/>
  <Contact>dict@leo.org</Contact>
  <Tags>LEO dictionary wörterbuch online translate übersetzen translation Übersetzung german english deutsch englisch</Tags>
  <LongName>LEOs Englisch-Deutsch Online Wörterbuch</LongName>
  <Query role="example" searchTerms="map"/>
  <Developer>LEO GmbH</Developer>
  <Attribution>Copyright LEO GmbH</Attribution>
  <SyndicationRight>private</SyndicationRight>
  <AdultContent>false</AdultContent>
  <InputEncoding>UTF-8</InputEncoding>
  <OutputEncoding>UTF-8</OutputEncoding>
</OpenSearchDescription>
```

... and that's all that is to it. In the `<url type="text/html">` node you'll find the URL that shall be called by the browser (and that Chromium picked up). And then there's some more fluff left and right.

There also is a URL registered for mime type `application/x-suggestions+json`, which looks promising ... but I haven't looked into that one.

[MDN has some more details on OpenSearch](https://developer.mozilla.org/en-US/docs/Web/OpenSearch)



## Using it

Given that Chromium already added the OpenSearch element,

  + you just need to activate it

  + and likely you want to modify the shortcut

By default the shortcut is the domain name. But I think typing "dict.leo.org <space> searchTerm" a little long. Inspired by kagi's bang feature I decided to go with "!l" (Bang + Small Letter L). So in order to search Leo's dictionary, I can now just go to the address bar (Control + L) and type "!l <space> searchTerm". Similar for Jira 🤗



## Configuring kagi

And since I'm getting to know kagi, ... I also just added these to my kagi settings > Search > Advanced > Custom Bangs. Bang shortcut is e.g. `!leo` and then just copy the URL, e.g. `https://dict.leo.org/englisch-deutsch/%s` and give it a name. Then you can just type `!leo word` to kagi's search bar. Likewise for Jira. And others.
