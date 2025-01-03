---
slug: two-more-releases
date: 2015-09-01
tags:
- V8Js
- performance
- release
category: V8Js
title: Two more V8Js releases
categories: V8Js
lastMod: 2025-01-03
---
Today as well as last Thursday I uploaded two more V8Js releases to PECL, both fixing issues around `v8::FunctionTemplate` usage that bit me at work.

Those `v8::FunctionTemplate` objects are used to construct constructor functions (and thus object templates) in V8. The problem with them? They are not object to garbage collection. So if we export a object with a method attached to it from PHP to JS, V8Js at first exports the object (and caches the `v8::FunctionTemplate` used to construct it; re-using it on subsequent export of the same *class*). If JS code wants to call the method first the named property is got, which exports a function object (via a `v8::FunctionTemplate`) to the JavaScript world -- afterwards the function object is invoked. The problem: this `v8::FunctionTemplate` was *not* cached, hence re-created on each and every call of the method, of course leading to problems if functions are called thousands of times.

Version 0.2.4 fixes a related issue, regarding export of "normal" numeric arrays to JavaScript. Those are exported to Array-esque objects, that however do *not* share the normal Array prototype ... the template needed to construct those was, once more, not cached ... and hence lead to thousands of those templates lingering around unusable.
