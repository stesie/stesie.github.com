---
slug: V8PromiseFactory
date: 2016-03-25
tags:
- V8Js
- ES6
- Promise
category: V8Js
title: V8PromiseFactory
categories: V8Js
lastMod: 2025-01-03
---
V8 has support for ES6 Promises and they make a clean JS-side API. So why not create promises from PHP, (later on) being resolved by PHP?

V8Js doesn't allow direct creation of JS objects from PHP-code, a little JS-side helper needs to be used. One possibility is this:

```php
class V8PromiseFactory
{
    private $v8;

    public function __construct(V8Js $v8)
    {
        $this->v8 = $v8;
    }

    public function __invoke($executor)
    {
        $trampoline = $this->v8->executeString(
            '(function(executor) { return new Promise(executor); })');
        return $trampoline($executor);
    }
}
```

... it can be used to construct an API method that returns a Promise like this:

```php
$v8 = new V8Js();
$promiseFactory = new V8PromiseFactory($v8);

$v8->theApiCall = function() use ($promiseFactory) {
  return $promiseFactory(function($resolve, $reject) {
      // do something (maybe async) here, finally call $resolve or $reject
      $resolve(42);
  });
};

$v8->executeString("
  const p = PHP.theApiCall();
  p.then(function(result) {
      var_dump(result);
  });
");
```

this code

  + initializes V8, V8Js and the `V8PromiseFactory` first

  + then attaches an API call named `theApiCall`, that uses `$promiseFactory` and passes it an executor that immediately resolves to the integer 42.

  + then executes some JavaScript code that uses the `theApiCall` function and attaches a `then` function that simply echos the value (42)

`V8PromiseFactory::__invoke` should cache `$trampoline` if it is used to create a lot of promises.

This code requires V8Js with [pull request #219](https://github.com/phpv8/v8js/pull/219) applied to function properly.
