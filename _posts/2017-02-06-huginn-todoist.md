---
layout: post
title: "Automating my Todoist with Huginn"
tags: [ "Huginn", "Todoist", "automation", "Twitter" ]
---
So for some time now I'm using Todoist as my personal means of
organization and (at least try to) practise [GTD](https://de.wikipedia.org/wiki/Getting_Things_Done).
It really helps me to stay organised (mostly) and keep focus, and even
so non-free I'm using [Todoist](https://todoist.com) as it has both a
nice and user-friendly Web UI as well as an Android App (both working
well offline).

And then there's [Huginn](https://github.com/cantino/huginn) which is a
self-hosted IFTTT on steroids, which I'm also using for quite a while
now.  Yet so far I didn't connect both tools.

Then there was that idea:

> I tend to just "like" stuff over on Twitter to flag it for me to
> eventually "Read Somewhen".  Yet I use Todoist to keep a GTD-style
> *somewhen maybe* list.
>
> So wouldn't it be cool if tweets I liked would automatically pop up on
> my Todoist Inbox (at least if they are likely "stuff to read")?

well, so I quickly noticed that Huginn doesn't have a Todoist Agent and
I'm not at all proficient in Ruby ... anyways I gave it a try ...
[so now there is huginn_todoist_agent](https://rubygems.org/gems/huginn_todoist_agent) :-)

In order to "click together" the Twitter-to-Todoist forwarder I created
a scenario using three agents:

1. *Twitter Favorites* Agent to continuously retrieve my Twitter favs
   and create an event for each and everyone
2. a *Trigger Agent* consuming these events and filtering out stuff
   that's not likely "to be read"
3. last but not least the my own *Todoist Agent* configured with a
   "Huginn" label so I know where the tasks come from

The Trigger Agent is configured like this

```json
{
  "expected_receive_period_in_days": "5",
  "keep_event": "false",
  "rules": [
    {
      "type": "regex",
      "value": "^http",
      "path": "entities.urls[0].url"
    },
    {
      "type": "!regex",
      "value": "^https://twitter.com/attn/status/",
      "path": "entities.urls[0].expanded_url"
    }
  ],
  "message": "Potential someday read: {{full_text}}"
}
```

... it simply excludes all Tweets that either have no URL at all (so
nothing to read there) or Tweets just mentioning other Tweets.

Using my "custom" Todoist Agent with [Huginn's docker container](https://hub.docker.com/r/cantino/huginn/)
is pretty simple: you just provide an environment variable
`ADDITIONAL_GEMS` with value `huginn_todoist_agent` and it auto-installs
it during first start of the container :-)
