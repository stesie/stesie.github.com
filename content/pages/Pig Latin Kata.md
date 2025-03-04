---
slug: pig-latin-kata
date: 2016-08-05
tags:
- Pig Latin
- Kata
- Softwerkskammer
- Nuremberg
title: Pig Latin Kata
categories:
lastMod: 2025-03-04
---
Yesterday I ran the Pig Latin kata at the local software craftsmenship meetup in Nuremberg. Picking *Pig Latin* as the kata to do was more a coincidence than planned, but it turned out to be an interesting choice.

So what I've prepared were four user stories (from which we only tackeled two; one team did three), going like this:

(if you'd like to do the kata refrain from reading ahead and do one story after another)

[Pig Latin](https://en.wikipedia.org/wiki/Pig_Latin) is an English language game that alters each word of a phrase/sentence, individually.

Story 1:

  + a phrase is made up of several words, all lowercase, split by a single space

  + if the word starts with a vowel, the transformed word is simply the input + "ay" (e.g. "apple" -> "appleay")

  + in case the word begins with a consonant, the consonant is first moved to the end, then the "ay" is appended likewise (e.g. "bird" -> "irdbay")

  + test case for a whole phrase ("a yellow bird" -> "aay ellowyay irdbay")

Story 2:

  + handle consonant clusters "ch", "qu", "th", "thr", "sch" and any consonant + "qu" at the word's beginning like a single consonant (e.g. "chair" -> "airchay", "square" -> "aresquay", "thread" -> "eadthray")

  + handle "xr" and "yt" at the word's beginning like vowels ("xray" -> "xrayay")

Story 3:

  + uppercase input should yield uppercase output (i.e. "APPLE" -> "APPLEAY")

  + also titlecase input should be kept intact, the first letter should still be uppercase (i.e. "Bird" -> "Irdbay")

Story 4:

  + handle commas, dashes, fullstops, etc. well

The End. Don't read on if you'd like to do the kata yourself.

## Findings

When I was running this kata at Softwerkskammer meetup we had eight participants, who interestingly formed three groups (mostly with three people each), instead of like four pairs. The chosen languages were Java, Java Script (ES6) and (thanks to Gabor) Haskell :-)

... the Haskell group unfortunately didn't do test first development, but I think even if they would have they'd anyways have been the fastest team. Since the whole kata is about data transformation the functional aspects really pay off here. What I really found interesting regarding their implementation of story 3 was that they kept their transformation function for lowercase words unmodified (like I would have expected) but before that detected the word's case and build a pair consisting of the lower case word plus a transformation function to restore the casing afterwards. When I did the kata on my own I kept the case in a variable and then used some conditionals (which I think is a bit less elegant) ...

Besides that feedback was positive and we had a lot of fun doing the kata.

... and as a facilitator I underestimated how long it takes the pairs/teams to form, choose a test framework and get started. Actually I did the kata myself with a stopwatch, measuring how long each step would take as I was nervous that my four stories wouldn't be enough :-) ... turns out we spent more time exercising and didn't even finish all stories.

## Further material:

  + [Pig Latin on exercism.io](https://exercism.org/tracks/java/exercises/pig-latin)

  + [my solution in Java 8](https://exercism.org/tracks/java/exercises/pig-latin/solutions/stesie)
