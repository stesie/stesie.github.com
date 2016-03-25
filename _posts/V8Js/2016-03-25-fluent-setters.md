---
layout: post
title: "V8Js: improved fluent setter performance"
tags: [ "V8Js", "fluent setters", "performance" ]
---
After fixing V8Js' behaviour of not retaining the object identity of passed back V8Object
instances (i.e. always re-wrapping them, instead of re-using the already existing object)
I tried how V8Js handles fluent setters (those that `return $this` at the end).

Unfortunately they weren't handled well, that is V8Js always wrapped the same object
again and again (in both directions).  Functionality-wise that doesn't make a big difference
since the underlying object is the same, hence further setters can still be called.

But still the wrapping code takes some time -- with simple "just store that" setters it
is approximately half of the time.  Here is a performance comparison of
calling 200000 minimalist fluent setters one after another:

![performance comparison of old & new handling](/assets/images/fluent-setter-performance.png)

Besides the performance gain it also keeps object identity intact, however I assume noone
ever stores the result of such a setter to a variable and compares it against another object.
So that isn't a big deal by itself.

The behaviour is changed with pull requests [#220](https://github.com/phpv8/v8js/pull/220)
and [#221](https://github.com/phpv8/v8js/pull/221).
