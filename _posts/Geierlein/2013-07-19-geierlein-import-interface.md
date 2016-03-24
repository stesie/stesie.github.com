---
layout: post
title: "Geierlein's import interface"
tags: [ "Geierlein", "data passing", "interface", "ERP", "Kivitendo" ]
category: Geierlein
---
From version 0.5.2 on Geierlein now has an import interface, which I came up while
discussing [issue #19](https://github.com/stesie/geierlein/issues/19).  Initially
Peter wanted to know whether and how it is possible to load form data from disk
from within the web interface, since there were neither buttons nor a menu allowing
to do so (opposed to the XUL-backed frontend, which has already been providing this
freature from the initial release on).

During the discussion it turned out, that what Peter really wanted to do was
integrating Geierlein with a web-based ERP system.  Having the ERP system
export a file (via download) and then uploading that particular file
into Geierlein seemed cumbersome, hence I was looking for a clean interface
between the two.

As Geierlein is a fully client-side application, that fetches just a single HTML file
along with a bunch of JavaScript files, data passing has to be fully client-side
as a consequence.  This is the data cannot just be POSTed (which would transmit the data
to the webserver) or so.  Either it has to be provided by a local means like
`localStorage` or Geierlein has to actively fetch the data from elsewhere (the calling
application), which leads to authentication issues in turn.

According to Peter [Kivitendo ERP](https://github.com/kivitendo/kivitendo-erp) has
no Ajax layer or REST API, from which the data could be fetched, hence it
would be a lot of work on that side, if Geierlein would insist on actively fetching
the data.  Therefore I went the local data passing route and implemented both,
data passing via `localStorage` and `window.name`.

This is any calling application can store data in Geierlein file format into
the `localStorage` object and forward to Geierlein providing a special hash like
so:

{% highlight javascript %}
  localStorage["geierlein.import"] = "\
name = Stefan Siegl\n\
strasse = Philipp-Zorn-Str. 30\n\
plz = 91522\n\
ort = Ansbach\n\
land = 2\n\
steuernummer = 123/123/12345\n\
jahr = 2013\n\
zeitraum = 5\n\
kz81 = 1000\n\
kz89 = 500\n\
kz83 = 285,00\n";
  location.href = "http://localhost:4080/#importLocalStorage";
{% endhighlight %}

The special hash triggers an import routine in Geielein, which reads the key
from the storage object, fills the form accordingly, clears the storage and
adds a notice to the begining of the page, that the import has taken place
successfully.  The calling application can _not_ directly trigger data
transmission of any sort.  The user of Geierlein always has the ability to
review the data and finally has to click the send button (and fill her
signature credentials).

As access to local storage is restricted by the Same-Origin-Policy there
is no risk of leaking data to external sites, however it is required, that
the data providing application (like Kivitendo ERP) and Geierlein are
installed under the same domain.

If that is not possible, data can be passed via `window.name`.  This however
has the problem of possibly leaking data, if the calling application (ERP)
is not configured correctly and forwards to a third-party site instead of
Geierlein.

Anyways, to pass form data to Geierlein using `window.name`, the example from
above just has to be modified slightly:

* data must obviously be stored to `window.name` instead
* the hash needs to be `#importWindowName`




