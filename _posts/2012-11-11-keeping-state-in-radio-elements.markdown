--- 
layout: post
title: "keeping state with radio elements"
tags: [ "HTML", "CSS", "General Sibling Combinator", "Page Stack Widget" ]
---
Recently I came accross a Pen by Azik Samarkandiy, who implemented a
[accordion in pure CSS](http://codepen.io/html5web/details/FpuHb) and
immediately wondered how he did that.  So far I was pretty convinced,
that you just have to use JavaScript to achieve something like that,
since you can't keep state (i.e. which content part is active) with
just CSS ...

Azik had a very clever idea, that easily solves the problem: he
just uses radio buttons.  This way he doesn't even have to disable
(i.e. hide) the other elements, since the radio elements already
make sure that at most one is active all the time.

After all the radio buttons are made invisible (via `display: none`)
and controlled with labels, that are easily stylable using CSS.
The appropriate content is made visible using CSS's general sibling 
cominator, i.e. `~`, and otherwise defaults to invisible like so:

```css
/* Show .info, if the related radio button is checked. */
.block input[type='radio']:checked ~ .info {
    height: 130px;
}

/* Generally hide all .info blocks. */
.info {
    height: 0;
} 
```

Transitions between state can easily be achieved using transition
CSS properties.

After all I think it is still questionable to add radio (form) elements
to HTML markup to keep presentation state, since it mixes the concerns
of the HTML/CSS/JS triple, i.e. I'd still expect the state to be wrapped
in a JS (be it jQuery) module.  On the contrary e.g. Geierlein has
a checkbox to show/hide large (hardly used) parts of it's tax declaration
form.  In that case I would not object using CSS at all, since the
checkbox is a visible, directly user controllable element.

<strike>
Anyways I wanted to give it a try and also wanted to tell about my projects on
this blog's frontpage.  Therefore I have added a page stack widget to it, that
keeps it's state using this radio element technique.  Just give it a try :-)
The page stack is only activated for device widths beyond 1024px,
so you might not see it on your mobile device...
</strike>

*Update* October 10, 2015: just removed the widget during a major update
of the blog itself.
