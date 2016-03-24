---
layout: post
title: "thoughts on phpspec"
tags: [ "phpspec", "unit testing" ]
---
As I’ve recently been poked whether I had used phpspec and I had to negate, today I finally gave it a try (doing the Bowling Kata) ...

phpspec has some class and method templating built into it.  If for example a test fails due to a missing function, it asks whether it should create one (that does nothing at all). This is nice but IMHO breaks the workflow a bit as you have to move the cursor to the terminal window and answer the question. You don’t just Shift+F10, see “red” in the panel and then hit Alt+Enter in PhpStorm and choose to create the method (which is my way of working with phpunit).

I like the well readable test code that can be written with it like

```php
$this->getScore()->shouldReturn(150)
```

... yet that code shows also what I hate about it. Since `$this` actually is the test-class, having to call the message to test on it feels strange (or even wrong) and also phpstorm has no support for that ... so no auto-completion here.

Calling methods of the SUT directly on `$this` gets even more messy once you add test helper methods like

```php
function it_grants_spare_bonus()
{
    $this->rollSpare();
    $this->roll(5);
    $this->rollMany(17, 0);
    
    $this->getScore()->shouldBe(20);
}
```

... here only `roll` is a method of the SUT, `rollSpare` and `rollMany` are just helper methods.

After all I'm still torn, I like the readability, but the rest still feels strange and I miss native support in PhpStorm.

