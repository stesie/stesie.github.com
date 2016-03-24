---
layout: post
title: "Redmine Extender"
tags: [ "Redmine", "Tampermonkey", "userscript" ]
---
Last week my colleage [Tino Dietel](https://github.com/StilgarBF) wrote a
little Tampermonkey userscript, that improves the *Assigned to* dropdown
of Redmine.  In large teams it becomes tedious to pick the right assignee,
especially if you almost always pick the same four or five people from a
list of say thirty people.  His solution to the problem was to simply
add secondary option elements to the top of the list, one for each of the top
assignees which have to be previously chosen.  His work is [published on
GitHub](https://github.com/StilgarBF/extended-redmine) as well.

Inspired by this and having a bunch of further improvements in mind, I
started out writing a little framework today, that eases development of
Redmine userscripts.  It tests for the existence of jQuery and jQueryUI
on the page, optionally injecting those if no recent versions are found.
Afterwards it starts each and every extension.  Besides it provides some
helper methods like easy access to `localStorage` and a user selector.

More details can be found on the fresh [Redmine Extender](/redmine-extender)
page.  If you already have a userscript manager (like Tampermonkey) installed,
just click the download links and you are set.
