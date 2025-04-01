---
status: budding
tags:
- WueRide
- Aider
- Komoot
- Kotlin
- Vibe Coding
date: 2025-03-30
title: Building WueRide - Experimenting with LLM-Powered Coding and the Fediverse
categories:
lastMod: 2025-03-30
---
A few weeks ago, I came across Harper Reed’s blog post, [My LLM codegen workflow atm](https://harper.blog/2025/02/16/my-llm-codegen-workflow-atm/), which made the rounds in the developer community. While his approach to using a LLM to collect and refine requirements was interesting, ... what really caught my attention was him mentioning, that he uses [Aider](https://aider.chat/) to let LLMs modify his code.

**So what is Aider?** Simply put, Aider is a CLI tool that isn’t tied to a specific LLM. It takes a prompt, sends it to a language model, requests code in a diff-based format, and applies those changes automatically to your project. Additionally, it commits the changes to a Git repository, complete with generated commit messages. Put differently: it saves you from copy & pasting the LLM suggestions, but takes them over automatically.

Aider also gathers relevant information about the local project (package structure, existing classes etc.) and implicitly provides that context to the LLM, preventing it from acting in a vacuum.

So, Aider piqued my curiosity. Vibe Coding is all the rage, and I had been thinking about learning some Kotlin.

Then came the news that [Komoot was acquired by Bending Spoons](https://www.dcrainmaker.com/2025/03/komoot-acquired-history-says-this-wont-end-well.html), which didn’t seem promising. This reminded me of [an old side project I had tinkered with back in October 2022](https://codeberg.org/stesie/wueride/src/tag/php-legacy) — a Fediverse-enabled route/trip-sharing application. I had spent a few nights on it before getting sidetracked.

Furthermore my friend Simon asked if I’d be up for a hackathon-style project. I said yes, though I had no idea what we could work on.

## Enter WueRide

Why not combine all these interests into one project?

On Monday morning, I texted Simon:
> Somehow I also want/need to resist the urge to start a new software project 😅

Yet, the temptation was too strong to resist. Hardly one hour later, I fired up IntelliJ, created a new Kotlin project, and started Aider the first time. My plan was clear: let Aider handle the implementation while I focused on architecture and requirements. Given that I had barely any Kotlin experience—just a quick read of the docs the night before—this approach was both necessary and exciting.

Fast-forward three days, and I [published this toot on wue.social](https://wue.social/@rolf/114236651019278127):

> May I introduce: WueRide
>
>  ... a #fediverse version of the social aspect of #komoot, i.e. a federated adventure log. With support for trips, multi trips (read: collections), images, stars & commenting.
>
>  Currently rather a proof of concept, I hacked together over the last three days. Nothing fancy. (yet)
>
>  See my profile for a first impression: https://wueride.bike/@stesie@wueride.bike
>
>  Source code released under AGPLv3 here: https://codeberg.org/stesie/wueride

And just like that, an early version of WueRide became a reality. Users can create accounts, log in, upload GPX files to create trips, add images (automatically matched to GPX data), follow others, star trips, and leave comments—not just within WueRide but also from Mastodon or any other Fediverse client.

All this for about $8 in LLM usage fees (using Anthropic’s Claude Sonnet 3.7), which was less than what I spent on the domain name!

## Could I Have Done This Without an LLM?

Certainly—but not in this timeframe. The federation aspect and high-level goals were mostly clear to me, but the rapid implementation speed wouldn’t have been possible.

So, was this experiment a success? I’d say yes. I now have a working prototype that I can iterate on.

## Was This "Vibe Coding"?

Some might say yes, but based on [Andrej Karpathy’s definition](https://x.com/karpathy/status/1886192184808149383), I’d say no. [Simon Willison surely would also reject](https://simonwillison.net/2025/Mar/19/vibe-coding).

Why not? Because we’re not there **yet**. Aider is an excellent tool, and Claude performed well, but I couldn’t completely ignore the code.

Looking at git blame, here’s how the contributions played out:

  + Total Kotlin lines: **4767**

  + Excluding blanks/imports: **3513**

  + Lines last touched by Claude: **3056** (87%)

  + Lines last touched by me: **13%**

But could I *forget* about the source code? Definitely not. Claude focused on feature implementation, while I debugged and refined the results.

Analyzing commit types:

**Aider's commits:**

  + feat: 61 (64.9%)

  + refactor: 26

  + fix: 6

  + style: 1

**My commits:**

  + fix: 51

  + chore: 18

  + refactor: 12

  + feat: 8

So I hardly implemented any feature myself (especially not a larger chunk of work), but had to do a lot of little fix here, small refactor there and from time to time some "oh, no I actually meant it that way"  work.

## Where Did It Struggle?

I think generally it did better churning out new code, compared to changing existing code (it wrote earlier). Some struggles it had:

  + **Kotlin’s Null Safety:** The model struggled with strict null checks, since trained mostly on JavaScript and Python (and these don't exist there) ([example 1](https://codeberg.org/stesie/wueride/commit/5e6d5a63b36694f3e26721f3bbdfe74d15af7ac6), [example 2](https://codeberg.org/stesie/wueride/commit/09e1bf2f7d83a2dd068fb446e59a145731f77904)).

  + **Hibernate Polymorphism:** Aider didn’t always handle Hibernate proxies correctly ([example](https://codeberg.org/stesie/wueride/commit/82337176bea7cc52d8c7b7a2dc12ee55b9968f23)).

  + **Backward-Incompatible Library Changes:** For example, the [Jenetics JPX (GPX) parser](https://github.com/jenetics/jpx) had breaking changes "recently", so many (?) of the code examples, Claude was trained on, no longer apply

  + **Refactoring Challenges:** Sometimes existing variable names were re-used (not in the diff itself, but if it adds more code to an existing method), and Claude occasionally failed to recognize inheritance structures ([example](https://codeberg.org/stesie/wueride/commit/89e4a41b50febe2c7a535dd8c6c94a2d17c784e3)).

Juniors struggle with that kind of stuff as well. And I'm pretty sure Claude (and other LLMs) will even get better soon 🙂

## Conclusion

Use of Aider was definitely a huge boost in my productivity. The "paired" approach of dividing implementation work and debugging turned out to be effective. And I feel like I've seen (at least) most of the code, and have a fair understanding of its weaknesses.

... that said, I'd definitely use Aider again and can warmly recommend (at least) trying it.

However I traded (short term) productivity for (long term) deeper understanding of Kotlin. Which is a pity, given that I wanted to actually learn it in the first place 😂

And I wouldn't agree that you can just "Vibe Code" away and forget about the code. Or you shouldn't at least impose Kotlin-use when doing so.

## What’s Next?

Honestly, I don’t know yet.

I’d love to build a local, community-driven trip-sharing platform. Perhaps some of you are interested in a hackathon around it?

But a social network without users doesn’t make sense. So, the big question is: Would you be interested in joining or contributing to such a platform?

[Comment here](https://wue.social/@rolf/114252302119667603).
