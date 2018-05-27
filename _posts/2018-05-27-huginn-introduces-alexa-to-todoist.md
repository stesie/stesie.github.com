---
layout: post
title: "Automating my Todoist with Huginn & Alexa"
tags: [ "Huginn", "Todoist", "automation", "Alexa" ]
---
As mentioned here before I'm heavily relying on Todoist to stay organized.
And I have a pretty detailed set of recurring tasks reminding me of things
like taking dietary supplements or watering the flowers.

However it's troublesome to take out the cell phone, unlock it and tick off
the item on Todoist after e.g. watering the flowers.  As I'm currently
experimenting with having Amazon Echos in my flat I wondered if it'd be
feasible to ask Alexa to close the Todoist item.  Turns out it is pretty
simple to do, aside from one caveat: every custom skill has a so-called
*invocation name* and it must be part of the invocation utterance.

So I decided to invoke like this:

> Alexa, tell James that I just watered the flowers.

So first of all you need an own custom skill, in this case named James --
which is never going to be published, just used in developer mode.  Then you
need to provide at least one intent, e.g. *FlowersWateredIntent*, along
with some sample utterances (in this case things like *that I just watered
the flowers*).  All this can be done [in Amazon's Developer Services
Portal](https://developer.amazon.com/).

Then Huginn has to be configured, we need three agents (actually 1 + 2n
where n is the number of intents to handle):

1. one *WebhookAgent* that simply provides an endpoint for the Alexa skill to call, set *payload_path* to a single dot
2. one *TriggerAgent* per intent that shall be handled, matching on the name
   of the intent.  The *rules* array should look like this:
```javascript
"rules": [
        {
            "type": "field==value",
            "value": "FlowersWateredIntent",
            "path": "name"
        }
]
```
3. an agent to perform the requested task, in my case a *TodoistCloseItemAgent* with *id* set to the item id of the item I'd like to be closed upon invocation

Last but not least we need some glue between Alexa Skills Kit and Huginn.
The easiest approach is a AWS Lambda function like this, which after all is
a straight forward, minimalist Alexa skill handler simply passing all
incoming request forward:

```javascript
/* eslint-disable  func-names */
/* eslint quote-props: ["error", "consistent"]*/

'use strict';
const Alexa = require('alexa-sdk');

// Replace with your app ID (OPTIONAL).  You can find this value at the top
// of your skill's page on http://developer.amazon.com.
const APP_ID = 'amzn1.ask.skill.3dbd7451-5830-4b20-a2d6-d1ab0387119e';

const HELLO_MESSAGE = 'Hey, schön, dass du da bist. Das nächste mal sag einfach gleich was du von mir willst.';
const OK_MESSAGE = 'Okay';
const FAIL_MESSAGE = 'Irgendwie hat das nicht geklappt, Sorry!';
const HELP_MESSAGE = 'Hilf dir selbst, nur dann hilft dir England!';
const STOP_MESSAGE = 'Bye bye cruel world!';

const https = require('https');
const post_options = { 
    host: 'hostname.of.your.huginn.tld',
    port: 443,
    path: '/users/2/web_requests/67/allofthebeautifulandreallyloooooooooooongrandomtokengoeshere',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json'
    }
};  


const handlers = {
    'LaunchRequest': function () {
        this.response.speak(HELLO_MESSAGE);
        this.emit(':responseReady');
    },
    'Unhandled': function () {
        console.log(this.event);
        const data = JSON.stringify(this.event.request.intent);
        
        post_options.headers['Content-Length'] = data.length;

        const post_request = https.request(post_options, (res) => {
            if (res.statusCode == 201) {
                this.response.speak(OK_MESSAGE);
            } else {
                console.log(res);
                this.response.speak(FAIL_MESSAGE);
            }

            this.emit(':responseReady');
        });
        
        post_request.write(data);
        post_request.end();
    },
    'AMAZON.HelpIntent': function () {
        this.response.speak(HELP_MESSAGE);
        this.emit(':responseReady');
    },
    'AMAZON.CancelIntent': function () {
        this.response.speak(STOP_MESSAGE);
        this.emit(':responseReady');
    },
    'AMAZON.StopIntent': function () {
        this.response.speak(STOP_MESSAGE);
        this.emit(':responseReady');
    },
};

exports.handler = function (event, context, callback) {
    const alexa = Alexa.handler(event, context, callback);
    alexa.APP_ID = APP_ID;
    alexa.registerHandlers(handlers);
    alexa.execute();
};
```

So if I now speak to Alexa the Alexa Skills Kit backend does the voice
recognition and triggers the lambda function.  This lambda function calls
out to Huginn's PostAgent endpoint which emits an event (that includes all
of the data ASK forwarded, so you even can handle slots there).  The
TriggerAgent matches on this event and triggers the task to actually be
done.
