---
layout: post
title: "v8js patches merged"
tags: [ "PHP", "V8Js", "V8", "Sandboxing", "PECL" ]
category: V8Js
---
Today the last pull request in a series of contributions to the [V8Js PHP
extension](https://github.com/preillyme/v8js) has been merged.
Good time to loose some words on the project and why I like it, so here we go :-)

V8Js is a PHP extension that integrates Google's V8 JavaScript engine into
PHP.  This is the extension allows you to execute JavaScript code securely
sandboxed from PHP.  Besides it allows for simple exchange of data from
PHP to JavaScript and back.

I like V8Js as it allows to run customer-provided code on the server, knowing
that it is properly sandboxed so it cannot interact with all your PHP classes,
variables and whatnot.  Instead you can (and have to) provide a restricted
set of classes acting as an API the JavaScript code can use.

First things first, a simple hello world:

{% highlight php %}<?php
$a = new V8Js();
$a->executeString('print("Hello World\n");');
{% endhighlight %}

... super simple and doesn't do very much.

Of course you can inject object instances as well:

{% highlight php %}<?php
class LoaderWriter {
    public function addRecord($type = 'text', $value = '') {
        echo "addRecord -- $type, $value\n";
    }
}

$jscode = <<< EOT
    PHP.loader.addRecord("text", "first loader insert");
EOT;

$a = new V8Js();
$a->loader = new LoaderWriter();
$a->executeString($jscode);
{% endhighlight %}

However that's still stuff you'd expect to work.  What about pushing
closures from JavaScript to PHP and call these from PHP?  Works!

{% highlight php %}<?php
class Parser {
    protected $_callbacks = array();

    public function on($element, $callback) {
        $this->_callbacks[$element] = $callback;
    }

    public function runParser() {
        // should be fleshed out of course :-)
        $this->_callbacks['node']('node-1 content');
        $this->_callbacks['node']('node-2 content');
    }
}

$jscode = <<< EOT
    PHP.parser.on("node", function(data) {
        print("Found node, content " + data + "\n");
    });
EOT;

$a = new V8Js();
$a->parser = new Parser();
$a->executeString($jscode);

$a->parser->runParser();
{% endhighlight %}

... this way you can easily use PHP's nice XmlReader to read chunks from
XML files and have a customer-provided piece of JavaScript code bind on
certain elements to drive customer-fitted data imports.

The code just does what you expect, it initializes a parser class,
binds an element handle (which is a JavaScript function) and afterwards
the parser (written in PHP) just calls the callback function transparently.
And of course it's not just possible to provide scalar values back and forth,
you can pass objects just as transparently.

Turned out that V8Js leaked some memory for each object being passed
back to JavaScript, which doesn't hurt much if you do it for a limited
number of times.  If you run the callback from above for a huge XML file
you're quickly hit.  The problem was, that V8Js incremented the refcount
on the PHP object, but didn't decrease if V8 decided to dispose the
JavaScript instance.  The fix for this is merged since July 11th.

Officially the PECL package is still in beta state and I found some bugs
after a limited number of evaluation hours ... if you can live with that
I think V8Js is a pretty cool sandbox environment, definitely worth a
look.

Since I've made myself familiar with the source I also replaced
deprecated calls to V8 API by newer equivalents and allowed for construction
of PHP objects from JavaScript.  This is do stuff like that:

{% highlight php %}<?php
$v8 = new V8Js();

class Greeter {
    function sayHello($a) {
        echo "Hello $a\n";
    }   
}

$jscode = <<< EOT
    PHP.greeter.sayHello("John");
    // prints "Hello John" as expected

    print(PHP.greeter); print("\n");
    // prints "[object Greeter]" as expected

    // What about the constructor function of greeter?
    print(PHP.greeter.constructor);
    // ... yields "function Greeter() { [native code] }"

    // ... super, so let me create more greeters  :-)
    var ngGreeter = new PHP.greeter.constructor();
    ngGreeter.sayHello("Ringo");
    // well, ... used to segfault :-)
EOT;

$v8->greeter = new Greeter();
$v8->executeString($jscode);
{% endhighlight %}

... I can't immediately come up with a use case, but hey, JavaScript
is all about (constructor) functions, so it definitely should work.
And of course it shouldn't be possible to crash the sandbox :-)
