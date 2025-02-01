---
category:
- Chat Dialogs
tags:
- AI
- Claude
- Telegram
- Image Recognition
status: seedling
date: 2025-01-28
title: Claude writing a Telegram Bot, 2nd try
categories:
- Chat Dialogs
lastMod: 2025-01-30
---
This is the second part of the mini series on writing Telegram bots to read my gas meter using Claude.

{{< logseq/orgNOTE >}}This post belongs to a mini series (I'm aiming for three posts in a row), where I try prompting Claude with different levels of verbosity and compare the results:
* In [Claude writing a Telegram Bot, 1st try]({{< ref "/pages/Claude writing a Telegram Bot, 1st try" >}}) I'm using an elaborate, step-by-step prompting strategy with Haiku model
* In [Claude writing a Telegram Bot, 2nd try]({{< ref "/pages/Claude writing a Telegram Bot, 2nd try" >}}) I aim for a detailed one-shot prompt
* In [Claude writing a Telegram Bot, 3rd try]({{< ref "/pages/Claude writing a Telegram Bot, 3rd try" >}}) I try a rather short one-shot prompt 
{{< / logseq/orgNOTE >}}

Like in the first round, I will first show the full dialog I've used to let it generate the implementation. Then following up with a discussion of the code and some final thoughts.

This time, I aim to provide a more concise approach by offering a single prompt that encompasses all the necessary steps to achieve our goal.

{{< logseq/orgREQUEST >}}Create a Telegram chatbot in JavaScript. The bot receives an image that is sent to it, shall then scale it to have 1000 pixels or less on the longer edge. Then upload the image to OpenAPI gpt-4o model along with the prompt "Wie lautet der Zählerstand auf dem Foto des Gaszählers. Die Zahl hat fünf Ziffern vor dem Komma und drei Nachkommastellen. Gib nur die Zahl aus, keinen Text davor oder danach". Take the resulting number, store it to a database table named gas_meter, along with the current timestamp. Furthermore return the extracted number within the telegram communication, so the chat contact has some feedback.
{{< / logseq/orgREQUEST >}}

{{< logseq/orgRESPONSE >}}I'll help you create a Telegram chatbot in JavaScript for processing gas meter images. I'll break this down into key components.

This implementation requires:
* Telegram bot token
* OpenAI API key
* PostgreSQL database connection
* npm packages: telegraf, axios, sharp, pg, openai


Database setup:
```sql
CREATE TABLE gas_meter (
  id SERIAL PRIMARY KEY,
  reading NUMERIC(8,3),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Recommended environment variables:

* TELEGRAM_BOT_TOKEN
* OPENAI_API_KEY
* DATABASE_URL


Would you like me to elaborate on any specific part of the implementation?
{{< / logseq/orgRESPONSE >}}

Looking at the code, I immediately noticed, that I forgot to mention that I want support for `.env` files and also that it must expect the LLM to reply with German number formatting (using a comma to separate the decimal places), ... quite like I had with the first try.
So let's fix this:

{{< logseq/orgREQUEST >}}consider that the reading, as returned by the LLM, might use a comma as decimal separator (due to the German prompt). Also read environment variables from an .env file, if it exists
{{< / logseq/orgREQUEST >}}

{{< logseq/orgRESPONSE >}}Key changes:

* Added `dotenv` to load `.env` file
* Modified `extractMeterReading()` to replace comma with dot
* Converted reading to `parseFloat()` for correct number parsing


Requires npm install dotenv in addition to previous dependencies.
{{< / logseq/orgRESPONSE >}}

Running it for the first time I noticed it's calling the LLM wrongly

{{< logseq/orgREQUEST >}}the code causes the following openai error:

Error processing image: BadRequestError: 400 Invalid value: 'image'. Supported values are: 'text', 'image_url', 'input_audio', 'refusal', 'audio', and 'file'.

figure out what's wrong please
{{< / logseq/orgREQUEST >}}

{{< logseq/orgRESPONSE >}}Key changes:

* Use `image_url` instead of image
* Write image to temporary file
* Convert image to base64 using file-based method
* Ensure cleanup of temporary file


This approach resolves the OpenAI API image submission issue by using the correct `image_url` format.
{{< / logseq/orgRESPONSE >}}

I've uploaded the [generated JavaScript code to GitHub](https://github.com/stesie/gaszaehler-bot-2/blob/main/telegram-gas-meter-bot.js).

## Code Review

Compared to the results of the first iteration I like that this time it's using `axios` for all http requests. Be it downloading from Telegram image storage, be it the call to the LLM.

When scaling the image, I think it's interesting how it calculates the target image size (considering the aspect ratio) manually this time, where it simply delegated that stuff to `sharp` with the first implementation.

What I really find weird is the way how it's converting the `ArrayBuffer` from `sharp` to a base64-encoded `Buffer`, which it's passing on to the LLM. To do so it first writes the `ArrayBuffer` to disk, just to re-read it immediately after, like this:
```js
  const tempFilePath = `/tmp/gas_meter_${Date.now()}.jpg`;
  
  // Write buffer to temporary file
  fs.writeFileSync(tempFilePath, imageBuffer);

  // Read file and convert to base64
  const fileBuffer = fs.readFileSync(tempFilePath);
  const base64Image = fileBuffer.toString('base64');
```
... would this be an actual code review situation, I very likely would address this.
Especially since the guessable filename might pose a security risk.

Instead this should just do the trick in one go:
```js
const base64Image = Buffer.from(imageBuffer).toString('base64');
```

Furthermore, the way it's (not) handling errors from the LLM invokation, it would not remove the temporary file, if the LLM invocation fails.

As mentioned earlier, the above code was produced by Claude 3.5 **Haiku**. I've later on tried the same prompt with Sonnet, and that just directly converted the `ArrayBuffer` as shown by me.

## Final thoughts

All in all another nice solution to the problem, that just works fine :-)

This demonstrates that it's not always essential to be overly wordy when giving guidance, unlike I initially did. However, breaking it down into individual steps, also aids personal understanding. Moreover, since I haven't created a Telegram bot before and it's been a while since I've scaled an image using Node.js, examining code samples in detail has helped me gain insights.

Observing the variations in how the `sharp` library is used with the `.resize(...)` function, it brings to mind the differing approaches that two human developers might take when writing code. Similar to Claude's example, it is possible for two individuals to reach different conclusions, with one opting to manually calculate the aspect ratio and the other choosing to utilize the library's built-in features.

{{< logseq/orgNOTE >}}There's a follow-up to this article, where I tried a very short one-shot prompt and compare the results: [Claude writing a Telegram Bot, 3rd try]({{< ref "/pages/Claude writing a Telegram Bot, 3rd try" >}}).
{{< / logseq/orgNOTE >}}
