---
date: 2025-01-06
tags:
- Hugo
- Logseq
- Logseq Schrödinger
status: budding
title: Learning Out Loud
categories:
lastMod: 2025-01-12
---
Lately, I've come across the concepts of "learning in public" and "digital gardens." A digital garden is a unique approach to organizing and sharing knowledge in a non-linear and evolving manner. Think of it as a personal wiki where one can cultivate ideas, insights, and resources over time. Unlike traditional blogs or websites that present polished and finalized content, digital gardens focus on capturing the learning process itself, fostering exploration and serendipitous connections between different pieces of information. This approach encourages collaboration, creativity, and continuous learning in a more open and transparent way.

A quote that deeply resonated with me is

> *"Knowledge grows when shared, not hoarded."*  — Unknown

This resonated with my approach to using Logseq as my own knowledge management system, fitting well with the concept of a digital garden. I start with an initial thought, a seed, which gradually matures. Over time, several journal entries evolve into a page (some may refer to this as a Zettelkasten, though I don't use that term).

I have been doing this for myself for quite some time, but now I am considering sharing some of my pages and insights, where it makes sense. For now, I don't plan to share my entire knowledge base as it contains many intertwined personal elements.

### More quotes :)

> *"Learning is not a spectator sport."* — D. Blocher

> *"Your unfinished thoughts might just be the spark someone else needs."* — Unknown

Another (false) quote I really liked is

> *"If a note is not published, does it really exist?"* — Erwin Schrödinger

### The publication process

The publication process is straight forward and involves these steps:

  + marking a Logseq page with the metadata `public:: true`, along with relevant details such as `date`, `category`, and tags

  + then using the [Logseq Schrödinger plugin](https://github.com/sawhney17/logseq-schrodinger), which generates a ZIP archive named "publicExport.zip" after a brief processing time (the plugin itself doesn't need any configuration, just tag at least one page as public, then it should start to do stuff -- and don't be impatient, give it a second or two)

  + simply extract this archive into the /content directory of my website repository

  + followed by a `git commit` and `git push`

  + a GitHub Action then takes over, using [hugo](https://gohugo.io/) to build the website and deploy it on GitHub Pages. The hugo repository is based on this [Logseq Hugo Template](https://github.com/CharlesChiuGit/Logseq-Hugo-Template).

Currently, I perform these steps manually to ensure the content is accurate, but it runs smoothly enough that I plan to automate it soon.

### Finished-ness status indication

From [Maggie Appleton](https://maggieappleton.com/)'s wonderful post [A brief History & Ethos of the Digital Garden](https://maggieappleton.com/garden-history) I have learned, that it's important to make clear, what the state of each and every note/post is. For this I've taken over her categorization scheme of

  + 🌱 *Seedling* for early ideas

  + 🌿 *Budding* for tidied up notes

  + 🌳 *Evergreen* for reasonably complete work (think of blog posts)

In addition I've meanwhile also added

  + 🥀 *Wilted* for outdated "tombstone" articles

To achieve this, I've introduced a new page-level metadata attribute in Logseq, which I just call `status`. This status attribute is exported (by the Schrödinger plugin) to the front matter of the post, which is then picked up by Hugo.

Last but not least I've [extended the post_meta.html template](https://github.com/stesie/stesie.github.com/blob/main/layouts/partials/post_meta.html#L5) to actually render that information. And also, already being there, prefixed the post's date with a "planted:" label ... and also adding a "last tended" field, showing the date of last modification (if different).
