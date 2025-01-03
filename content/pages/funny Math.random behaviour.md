---
slug: math-random-fun
date: 2016-03-05
tags:
- V8Js
- V8 Heap Snapshots
category: V8Js
title: funny Math.random behaviour
categories: V8Js
lastMod: 2025-01-03
---
Playing around with V8's [custom startup snapshots](http://v8project.blogspot.de/2015/09/custom-startup-snapshots.html) I noticed some funny behaviour regarding `Math.random`.

It is clear that if you call `Math.random()` within the custom startup code the generated random numbers are baked into the snapshot and then not so random anymore. If you call `Math.random()` at runtime, without custom startup code, it just behaves as expected: it generates random numbers. However if you have custom startup code, calling `Math.random()` early on startup, it correctly generates random numbers during startup but it breaks runtime random number generation causing weird error messages like

```
TypeError: Cannot read property '4' of undefined
```

@virgofx raised this [issue at the V8 issue tracker](https://bugs.chromium.org/p/v8/issues/detail?id=4810).

For the moment I came up with using random numbers from PHP's Mersenne Twister

```php
$this->v8 = new V8Js('PHP', [], [], true, $blob);
$this->v8->__random = function() { return mt_rand() / mt_getrandmax(); };
$this->v8->executeString('Math.random = PHP.__random; ');
```
