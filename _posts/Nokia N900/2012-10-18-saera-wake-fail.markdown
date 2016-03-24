--- 
layout: post
title: "Saera - very interesting, but rather alpha"
tags: [ "Nokia N900", "Saera", "Siri", "Python" ]
category: Nokia N900
---
The other day I've noticed yet another very interesting app for the N900,
called [Saera](http://talk.maemo.org/showthread.php?t=84753).  On Youtube
there is a [nice video](http://www.youtube.com/watch?v=ghVOH-6X1yg), showing
it in action.

After all it aims to become a full fledged Siri clone.  It's written in Python,
the GUI is based on PyGtk.  Speech recognition is performed either using 
[Pocketsphinx](http://www.speech.cs.cmu.edu/pocketsphinx/) or the Google
Voice Search backend.

But well, it's rather buggy:

![Screenshot of Saera](/assets/images/saera-fail.png)

First off the speech recognition using Google Voice API was broken.  Saera
was always relying on Pocketsphinx.  If that one didn't come up with the
utterance, it passed the voice recording on to Google's API.  So far, so good.
But it didn't pass the utterance back to the processing module.  It just
passed it on to answers.com.  I've quickly fixed that and provided a pull
request on GitHub, which was merged within two days.

I'll definitely put some more effort into the project.  Mainly I'd like to
speak to Saera in German language and have a plugin based processing backend.
