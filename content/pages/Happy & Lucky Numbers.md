---
slug: happy-and-lucky-numbers
tags:
- kata
- generator
date: 2016-03-10
title: Happy & Lucky Numbers
categories:
lastMod: 2025-01-02
---
The other day I paired with the guys from @solutiondrive and [@niklas_heer](https://twitter.com/niklas_heer), we had a fun evening learing about [happy numbers](https://en.wikipedia.org/wiki/Happy_number), shared PhpStorm knowledge, tried [Codeception](http://codeception.com/) etc. Actually we didn't even finish the ["Happy Numbers" Kata](https://app.box.com/s/4eu8q4799bwjc03lhk5ggzjzs2p5dlcg), since we only wrote the classifying routine, not the loop generating the output.

On my way home I kept googling and also found out about [Lucky Numbers](https://en.wikipedia.org/wiki/Lucky_number). Lucky numbers are natural numbers, recursively filtered by a sieve that eliminates numbers based on their position (where the second number tells the elimination offsets).

So I immediately came up with another Kata: generating those numbers.
My constraint: no upper limit, i.e. use PHP's Generator instead
... so I came up with the idea to implement the sieve itself as a Generator, that reads from an injected Generator, filters as needed and yields the result. The first "sieve generator" is fed from another generator that simply yields all natural numbers. The second one is fed from the first one and so on. The generator into generator injection is handled by yet another generator ... turn's out: it works, but doesn't look so nice.
The outer generator cannot simply inject generators endlessly (since they are actually instanciated), so injection has to be deferred - that however dilutes the self-contained sieve generator :-(

Anyways it was a good exercise on PHP's generators. I think I'll give it another try soon, again with generators yet another approach.
