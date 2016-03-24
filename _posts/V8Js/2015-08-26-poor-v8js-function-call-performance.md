---
layout: post
title: "Poor V8Function call performance"
tags: [ "V8Js", "performance", "release" ]
category: V8Js
---
Today I noticed, that invocations of `V8Function` objects have a really poor
call performance.  A simple example might be:

{% highlight php %}<?php
$v8 = new V8Js();
$func = $v8->executeString('(function() { print("Hello\\n"); });');

for($i = 0; $i < 1000; $i ++) {
    $func();
}
{% endhighlight %}

... on my laptop this takes 2.466 seconds (with latest V8Js 0.2.1); older
versions like V8Js 0.1.5 even take 80 seconds.

That felt strange, since V8Js performance generally is pretty good and the
slightly changed version

{% highlight php %}<?php
$v8 = new V8Js();
for($i = 0; $i < 1000; $i ++) {
    $v8->executeString('(function() { print("Hello World\\n"); })();');
}
{% endhighlight %}

... has drastically better performance figures, just 0.168 seconds with recent
V8Js and 0.247 seconds with ancient 0.1.5.

So there clearly is something going wrong.

My [pull request #159](https://github.com/phpv8/v8js/pull/159) shows the
solution, V8Js was re-using cached `v8::Context` on subsequent `executeString`
calls but kept creating new `v8::Context` instances for `V8Function`
invocations.  With the patch applied the first example now passes in 0.135
seconds, which is slightly better than the `executeString` performance (as
expected).

After that huge improvement I released [V8Js version
0.2.2](https://pecl.php.net/package-info.php?package=v8js&version=0.2.2),
which also ships some memory leaks and errors mainly related to `require()`
functionality.

