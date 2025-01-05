---
slug: first-dev-night
date: 2016-08-10
tags:
- Meetup
- Ansbach
- Tradebyte
title: Starting a local developer meetup
categories:
lastMod: 2025-01-03
---
As Ansbach (and the region around it) neither has a vibrant developer community nor a (regular) meetup to attract people to share their knowledge, mainly [@niklas_heer](https://twitter.com/niklas_heer) and me felt like having to get active...

Therefore we came up with the idea to host a monthly meetup named [/dev/night](https://www.tradebyte.com/dev-night/) at @Tradebyte office (from August on regularly every 2nd Tuesday evening), give a short talk to provide food for thought and afterwards tackle a small challenge together.

... looking for some initial topics we noticed that patterns are definitely useful to stay on track and that there are many good ones beyond the good old GoF patterns. And as both of us are working for an eCommerce middleware provider we came to eCommerce patterns ... and finally decided to go with *Transactional Patterns* for the first meeting.

So yesterday [@niklas_heer](https://twitter.com/niklas_heer) gave a small presentation on what ACID really means and why it is useful beyond database management system design (ever thought of implementing an automated teller machine? or maybe to stick with eCommerce what about fetching DHL labels from a web-service if you're immediately charged for them? You definitely want to make sure that you don't fetch them twice if two requests hit your system simultaneously). Besides he showed how to use two-phase commit to construct composite transactions from multiple, smaller ACID-compliant transactions and how this can aid (i.e. simplify) your system's architecture.

As a challenge we thought of implementing a fictitious, distributed Club Mate vending machine, ... where you've got one central "controller" service that drives another (remote) service doing the cash handling (money collection and provide change as needed) as well as a Club Mate dispensing service (that of course also tracks its stock). Obviously it is the controller's task to make sure that no Mate is dispensed if money collection fails, nor should the customer be charged if there's not enough stock left.

... this story feels a bit constructed, but it fits the two-phase commit idea well and also suits the microservice bandwagon :-)

## Learnings

the challenge we came up with was (again) too large -- quite like last Thursday when I was hosting the [Pig Latin Kata in Nuremberg](https://github.com/stesie/stesie.github.com/blob/master/2016/08/pig-latin-kata) ... the team forming and getting the infrastructure working took way longer than expected (one team couldn't even start to implement the transaction handling, as they got lost to details earlier on)

after all implementing a distributed system was funny, even so we couldn't do a final test drive together (as not all of the services were feature complete)

... and it's a refreshing difference to "just doing yet another kata"

the chosen topic *Transactional Patterns* turned out to be a good one, [@sd_alt](https://twitter.com/sd_alt) told us that he recently implemented some logic which would have benefitted from this pattern

one participant was new to test-driven development (hence his primary takeaway was how to do that with PHP and phpspec/codeception)

this also emphasises that we should address developers not familiar with TDD in our invitation (and should try not to scare them away by asking to bring laptops with an installed TDD-ready environment with them)

for visitors from Nuremberg 6:30 was too early, they ask to start at 7 o'clock

all participants want us to carry on :-)

... so the next */dev/night/* is about to take place on September 13, 2016 at 7:10 p.m. The topic is going to be *Command Query Responsibility Segregation pattern and Event Sourcing*.
