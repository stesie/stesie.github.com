---
category:
- Chat Dialogs
tags:
- AI
- Claude
- Telegram
- Image Recognition
status: budding
date: 2025-02-01
title: Claude writing a Telegram Bot, 3rd try
categories:
- Chat Dialogs
lastMod: 2025-02-02
---
This is the third part of the mini series on writing Telegram bots to read my gas meter using Claude.

{{< logseq/orgNOTE >}}This post belongs to a mini series (I'm aiming for three posts in a row), where I try prompting Claude with different levels of verbosity and compare the results:
* In [Claude writing a Telegram Bot, 1st try]({{< ref "/pages/Claude writing a Telegram Bot, 1st try" >}}) I'm using an elaborate, step-by-step prompting strategy with Haiku model
* In [Claude writing a Telegram Bot, 2nd try]({{< ref "/pages/Claude writing a Telegram Bot, 2nd try" >}}) I aim for a detailed one-shot prompt
* In [Claude writing a Telegram Bot, 3rd try]({{< ref "/pages/Claude writing a Telegram Bot, 3rd try" >}}) I try a rather short one-shot prompt
* In [Other LLMs writing a Telegram Bot]({{< ref "/pages/Other LLMs writing a Telegram Bot" >}}) I quickly try DeepSeek and some more LLMs 
{{< / logseq/orgNOTE >}}

Like in the first round, I will once more show the full dialog I've used to let it generate the implementation. Then follow up with a discussion of the code and some final thoughts.

This is once more run against Claude 3.5 **Haiku**, so it's comparable to the previous two posts. This time I omitted asking for intermediate steps like, scale the image to reduce the number of tokens used, and which prompt to use.

{{< logseq/orgREQUEST >}}Create a telegram chatbot in JavaScript. I want to take a photo of a gas meter. Upload to OpenAI API to read the gas meter. The number has five digits before comma, and three decimal places. Then store the value to a postgres database table and return it in the chat.
{{< / logseq/orgREQUEST >}}

{{< logseq/orgRESPONSE >}}Here's a breakdown of the implementation:

1. Telegram Bot Setup:

* Uses telegraf for handling Telegram bot interactions
* Responds to /start command
* Handles photo uploads


2. Image Processing:

* Downloads the uploaded photo
* Uses OpenAI's GPT-4 Vision API to read the meter number
* Validates the reading format (5 digits, 3 decimal places)


3. Database Storage:

* Uses PostgreSQL to store meter readings
* Includes user ID, reading, and timestamp
* Includes a method to set up the database table


4. Error Handling:

* Robust error handling for file downloads, API calls, and database operations



Prerequisites and Setup:

1. Install Node.js (version 16+)
2. Create a Telegram bot via BotFather
3. Get an OpenAI API key
4. Set up a PostgreSQL database
5. Install dependencies: npm install
6. Create a .env file with your credentials
7. Run the bot: npm start


Notes and Recommendations:

* Ensure you have the latest versions of the dependencies
* Implement proper error logging in production
* Consider rate limiting and additional security measures
* The bot currently assumes a specific meter reading format


Would you like me to elaborate on any part of the implementation or explain how to set up and deploy this bot?
{{< / logseq/orgRESPONSE >}}

[This is the full code, that it spat out on the first shot](https://gist.github.com/stesie/3f496a10ee4961c00ebbd2a2825e71c4)

## Code Review

```js
const TelegramBot = require('node-telegram-bot-api');
const { Telegraf } = require('telegraf');
const { createClient } = require('@supabase/supabase-js');
const { OpenAI } = require('openai');
const multer = require('multer');
const axios = require('axios');
const fs = require('fs');
const pg = require('pg');
```

Already the initial imports are weird. So in it's summary comment it even mentioned, that it's using `telegraf` as a dependency, to implement the chat bot. However it also imported `node-telegram-bot-api` ... which it doesn't use at all.

Likewise for the `@supabase/supabase-js` import. I mean, it's an interesting thought to use Supabase (which is an open source Firebase alternative, that's actually offering Postgres databases) ... but it's neither what I asked for nor is it actually using it in it's own code later on.

Furthermore it's importing `multer` and even configured it in the constructor:
```js
    // Multer for handling file uploads
    this.upload = multer({ 
      dest: 'uploads/',
      limits: { fileSize: 5 * 1024 * 1024 } // 5MB file size limit
    });
```
... but afterward it's not using it !?

A nice touch, that wasn't present on the first two iterations is this:
```js
    // Start command handler
    this.bot.command('start', (ctx) => {
      ctx.reply('Welcome! Send me a photo of your gas meter, and I\'ll read and store the reading.');
    });
```
... I never asked for it, nor thought of it ... but it's nice offering some "call to action". Obviously it's not really needed, given that the bot is only a personal one and I of course know how to use it. But from a product/project point of view it makes sense.

Like the previous versions also it's a bit lax on assumptions, where it can put temporary files:
```js
  async downloadFile(filePath) {
    const fileUrl = `https://api.telegram.org/file/bot${this.botToken}/${filePath}`;
    const localFilePath = `uploads/${Date.now()}_meter.jpg`;
```

  + It simply assumes, that there's a `uploads/` folder, and furthermore, that it's *writable*.

  + Once more it's not using random names for the temp file and/or check if it's accidentally overwriting stuff. It just writes.

  + ... and as mentioned on the previous post, after all there's no reason at all, to create a temporary file in the first place. The data may just be stored into a `Buffer` directly.

Furthermore, in case of exceptions occuring while accessing the LLM and/or the database, it'll fail to delete the temp file:
```js
        // Reply to user
        ctx.reply(`Meter reading recorded: ${meterReading}`);

        // Clean up uploaded file
        fs.unlinkSync(filePath);
      } catch (error) {
        console.error('Error processing meter reading:', error);
        ctx.reply('Sorry, I couldn\'t process the meter reading. Please try again.');
      }
```
... it even thought of providing a catch block, but then simply forgot about it. Well, on the other hand, one might argue that this is intentional, given that it might aid debugging 🤷

I like that it was able to come up with a meaningful prompt for GPT
```js
{
  role: "user",
  content: [
    { 
      type: "text", 
      text: "Read the number on this gas meter. Ensure it's a 5-digit number before the comma and 3 decimal places." 
    }
    // ...
  ]
}
```
... so it can mimic the standpoint of an entity of it's own, asking GPT as a third party.

However it doesn't consider the freedom in ways of answering it leaves to the GPT. Given this prompt GPT will never just return the pure number. It'll always at least prefix something like "The gas meter reading is ...".

Therefore it's a nice touch, that it even comes up with a regex, asserting the format:
```js
  validateMeterReading(reading) {
    // Regex to match 5 digits before comma, 3 decimal places
    const meterReadingRegex = /^\d{5}\.\d{3}$/;
    return meterReadingRegex.test(reading);
  }
```
... but that's going to fail in all the cases, given that it didn't tell the LLM, that it will make this assertion.

What's actually confusing, is that it just provided some example usage at the end of the file:
```js
// Export for use
module.exports = GasMeterBot;

// Example instantiation
// const gasMeterBot = new GasMeterBot();
// gasMeterBot.setupDatabase();
```
... so it's actually just creating a module ... that it doesn't instantiate anywhere. Which after all is in contrast to the "Setup steps" it brought forward, where it told to run `npm start`. But given that this instruction is commented out, it just will do nothing if started ...

## Comparison with Sonnet

I've also quickly tried exactly the same prompt with Claude 3.5 **Sonnet**, which came up with the following prompt:

```js
{ 
  type: "text", 
  text: "Read the gas meter value in this image. Return only the number with 5 digits before decimal and 3 after. Format: XXXXX.XXX" 
}
```

... where it clearly tells GPT which output it expects.

It also refrained from depending on other modules, which it wasn't using.

Neither the temporary file handling issues were present in that code, it just directly converted the `ArrayBuffer` into a `Buffer`, using `Buffer.from`.

## Conclusion

I think it's fair to say that Claude 3.5 **Haiku** wasn't able to properly cope with the given task. While it does provide a foundation to build upon, it definitely takes a human to address the issues at hand (either fixing directly, or providing further prompts to drive it forward). On the other hand it shows, that quite like you would reason about intermediate steps with (lesser experienced) human developers, you need to have this "thinking together" phase with the LLM as well.

The quick comparison with Claude 3.5 **Sonnet** shows, that that one is far more capable and could handle even this task easily.

{{< logseq/orgNOTE >}}There's a follow-up to this article, where I tried the prompt from above against some other popular LLMs from DeepSeek, Meta & OpenAI: [Other LLMs writing a Telegram Bot]({{< ref "/pages/Other LLMs writing a Telegram Bot" >}}) 
{{< / logseq/orgNOTE >}}
