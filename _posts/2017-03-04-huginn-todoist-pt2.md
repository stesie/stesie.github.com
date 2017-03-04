---
layout: post
title: "Huginn loves Todoist, pt. 2"
tags: [ "Huginn", "Todoist", "automation", "Querynaut", "REST", "API" ]
---
As written about here before I'm heavily relying on Todoist to stay organized,
and one part of the story (so far) have been three recurring tasks on my todo list:

![Screenshot of those three tood items](/assets/images/todoist-recurring-tasks.png)

... they are just there to nag me every morning to consider what's in my Inbox
(sitting there waiting to be assigned to projects and otherwise classified), what's
over-due (to re-schedule or postpone) or labelled `@waiting_for` (I assign that
label to all tasks that wait for someone else; and I skim over them reconsidering whether
they got actionable meanwhile or need me poking).  It's just a routine, I
briefly go over them and tick them off.

Yet sometimes the Inbox is empty or there just are no items labelled `@waiting_for`.
It's not much of a deal but I felt like having to automate that -- i.e. just create
those tasks if there are items in the inbox, overdue or waiting for ...

Well, as I already have Huginn connected to my Todoist it was pretty clear that
Huginn should also do that.  So I had a look at the [ruby-todoist-api Gem](https://github.com/maartenvanvliet/ruby-todoist-api/)
I'm already using for the [TodoistAgent](https://github.com/stesie/huginn_todoist_agent)
I wrote a month ago ... turns out it has a query API, yet it isn't as flexible as
the [filter expressions](https://support.todoist.com/hc/en-us/articles/205248842-Filters)
supported by Todoist's web frontend.
It indeed allows you to do simple queries like `today` or `tomorrow` or `over due`.
But it doesn't allow to search for projects, neither does it allow to combine queries
with boolean operators (like `(today | overdue) & #work`).

Yet another topic that escalated quickly, ... I kicked off a new project
[Todoist Querynaut](https://github.com/stesie/todoist_querynaut/), a Ruby gem, that
has a Treetop-based parser for Todoist's query language, uses the somewhat limitted
API mentioned above and does the rest on the client-side.  So if you query
`(today | overdue)` it actually does two calls to the REST API and combines the items
returned from both queries (filtering out duplicates).
So far *Querynaut* is still in its' early days, yet already usable.  It doesn't yet
support some fancy kinds of queries (filtering by due date, to mention one), but
the outline is there.

The next part then was to extend Huginn by another agent, which I named `TodoistQueryAgent`.
It takes a query, executes it (via querynaut) and either emits an event for each
and every task found (for `mode=item`) or just emits the number of search results
(for `mode=count`).

For the use-case from above I created three new agents scheduled for 8am every day,
went on setting mode to `count` and using `p:Inbox`, `over due` and `@waiting_for`
as query strings.  Then I connected those three agents to three more *Trigger Agents*
that just compare the number of found tasks to be larger than zero and emit a suitable
message that ends up on Todoist -- those of course are connected to a *Todoist Agent*
that properly forwards then.  Like so:

![Screenshot of Huginn Agent visualisation](/assets/images/todoist-huginn-flow.png)

In case you'd like to import this scenario, here's my [Huginn's scenario JSON export](https://huginn.brokenpipe.de/scenarios/8/export.json).
For that to work you need to have [TodoistAgent](https://github.com/stesie/huginn_todoist_agent) 0.5.0 or newer installed.
