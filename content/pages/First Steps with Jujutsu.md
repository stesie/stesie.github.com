---
tags:
- Jujutsu
- Seneca
status: seedling
date: 2026-02-06
title: First Steps with Jujutsu
categories:
lastMod: 2026-02-06
---
So the other day I started using [Jujutsu](https://www.jj-vcs.dev/latest/) ... for the moment "just" with two repositories at work. But willing to learn and potentially ramp up usage.

This is after [Daniel Danner](https://github.com/dnnr/) was "advertising" it on last year's [Seneca Camp](https://seneca.camp/) in Erlangen.

## Motivation

Reason for trying it out is that I want to benefit from [Jujutsu megamerges](https://v5.chriskrycho.com/journal/jujutsu-megamerges-and-jj-absorb/) and the `jj absorb` feature.

So at work I'm currently working on a single long-running project, and most of the time working _alone_ on some feature branches in parallel. Those are merged to develop (and release branches) in a monthly cycle.

For the first iteration I just had everything on a single branch, "wildly" interleaving work on features. So it's not that I constantly switch between the features. But let's say I work two days on feature A, then three days on B and then coming back to A again ... and so on.
But I kept doing small commits, and mixed them on the branch -- so for review you had to churn through a melange of everything.

Next iteration I kept working on a single branch, and had mostly a single commit per feature (or maybe two, but not more) ... and kept squashing changes into those commits.
This way I ended up with pretty big commits, but separate ones per feature. Allowing reviewers to concentrate on features, but the commits were quite large.
One nice benefit of this approach was that it enables to easily mix & match -- just pick a single commit to pick a feature. Merge window closing and a single feature not ready? Shove that one commit off the branch and move to next month's branch. So way better, but not perfect.

Enter Jujutsu. I now can have separate "branches" for each of the individual features. On top of these I have one "megamerge" commit, ... after all just a fancy name for "merge commit with more than two parents" (but rather five or six in my case). And this "merge commit" is what I push to the CI pipeline and deploy on the test machine. And that very commit is also the "base commit" for my current work. I fix stuff, add new feature, whatever. Then either a) `jj absorb` and Jujutsu will find out to which "branch" it belongs and squash it into one of the commits or b) I want to keep it as a separate change, then rebase it to the correct "branch" using something like `jj rebase -r @ -A XXX` (where XXX is the change _after_ which it shall be inserted).

## Pager Annoyance

JJ's default behaviour is that every command is triggering the pager. This is if you run `jj st` (the `git status` equivalent) it'll show the status in the pager (e.g. `less`) ... and if you quit that, then the output is gone.

The fix is to add the following bit to `.config/jj/config.toml`:

```toml
[ui]
pager = "less -FRX"
```

What these flags do:

  + don’t page if it fits on one screen (`-F`)

  + allow ANSI colors (`-R`)

  + don’t clear the screen on exit (keeps output visible) `-X`

Especially the `less -F` bit was completely new to me. This is definitely useful beyond `jj` 🥳

## (weird) git fetch behaviour

... so, this isn't actually weird, maybe just unexpected. But to me it still feels strange. And likely it remains strange if you're the only one on the team who's using jj.

> `jj git fetch` **does not move `@origin/*` bookmarks destructively**, even if the remote force-pushes

Or spelled out:

  + a colleague pushes to some branch feature/A

  + you `jj git fetch`

  + the colleague **force pushes** to **her** branch feature/A again (which is perfectly fine, it's her branch)

  + you `jj git fetch`

  + ... now _you_ have a conflict on the `@origin/feature/A` bookmark (since it's now pointing to A and A' at the same time -- and it's up to you to decide)

🤯

I mean, yes, I understand why, but it was rather irritating. And it still confuses me if jj is reporting new conflicts after fetching, and I can just "ignore" them.

But I begin to accept that it's nice that "history loss" must be explicit.

... so far I refrained from aliasing `jj bookmark forget "@origin/*` into my fetch. But I'm not sure if won't give in.
