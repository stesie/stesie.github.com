---
category:
- Chat Dialogs
tags:
- AI
- Claude
- Telegram
- Image Recognition
status: seedling
title: Claude writing a Telegram Bot, 1st try
categories:
- Chat Dialogs
date: 2025-01-27
lastMod: 2025-01-27
---
This post is the first part, in a mini series (I'm aiming for three posts in a row), where I try prompting Claude with different levels of verbosity and compare the results. Below you'll find results of my initial try in using Claude to write a Telegram Bot.

My ultimate goal is to figure out how much gas I need to heat my apartment. The gas meter is located in the hallway outside my apartment and doesn't have a digital interface to tap into. Since I just rent the place and the meter is outside the apartment, I can't tinker with it. The idea is to snap a quick picture of the meter in the morning and evening, or whenever I feel like it. Just in passing... and have the value automatically stored in a database for future analysis.

![Photo of my gas meter, reading 00773,078 m3](/assets/gasmeter.png)

In short, it needs to be quick and easy. My initial thought was to create an iPhone app, perhaps using Flutterflow. However, since I don't have an Apple Developer Account, that's a bit tricky. The next idea that came to mind was Telegram. Send the image to a bot, and let it do the rest. Since I already have an API account with OpenAI, the image will be sent there. GPT-4o will read the meter reading, store it in a PostgreSQL table, and that's it. That's the plan...

## First try: being verbose while prompting step by step

Before firing up Claude AI I quickly tried image recognition with GPT-4o and already played a little, what's a proper prompt to read the meter value. Given that some numbers might be hard to read, since the meter is "in between" two values, I noticed to get more reliable results if I tell it, that the number has five digits before the comma, and three decimal places.

After I found out that GPT is perfectly able to read the meter, and isn't confused by any of the other numbers and/or text written onto the meter ... I wanted to find out how to write a Telegram bot. To be honest, I've never tried that before, ... neither with nor without an LLM as support.

Furthermore I haven't used Claude much before. But I heard that Claude would be better with JavaScript, and GPT better with Python ... since I'm a JavaScript/TypeScript person, I went with claude and asked for JavaScript.

As I'm just on the free tier, and there was much traffic on their site, Claude 3.5 Sonnet wasn't available. Therefore I went with the Haiku model. Going step by step, I started out asking how it would write a bot in the first place

> Which JavaScript library would you use to create a telegram bot, that I would want to send images to?

Response: 
> For creating a Telegram bot in JavaScript that can send images, I recommend using the `node-telegram-bot-api` library. It provides a straightforward way to interact with the Telegram Bot API and supports sending images easily. Here's a quick example:

```javascript
const TelegramBot = require('node-telegram-bot-api');
const bot = new TelegramBot(token, {polling: true});
- // Sending an image
bot.sendPhoto(chatId, 'path/to/image.jpg');
```

> The library handles image uploads, supports various methods for sending media, and provides a robust set of features for Telegram bot development.

Ok, so it misunderstood me, that I want to _send_ images. No idea how that comes, but let's correct it right away:

> No, I wouldn't want the bot to send images, but receive them. Does this library handle it anyways?

Response:

> Yes, `node-telegram-bot-api` handles receiving images as well. Here's a simple example:

```javascript
bot.on('photo', (msg) => {
  const photo = msg.photo;
  // Access the photo details and download if needed
});
```

> The library provides methods to access image metadata and download received images, making it convenient for handling image uploads to your Telegram bot.

Ok, seems like this could work. So let's just move on to resizing the image. The camera image will initially be quite large. OpenAI doesn't accept images bigger than 2048px anyways, and it's billing by block sizes of 512x512 pixels,  ... so let's see how we can shrink the image

> ok, fine. This image can be pretty big in size. How would you scale the image so it's longer edge doesn't have more than roughly 1000 pixels ?

Response:

> I'll demonstrate how to resize an image using the Sharp library in Node.js:

```javascript
const sharp = require('sharp');

bot.on('photo', async (msg) => {
  const fileId = msg.photo[msg.photo.length - 1].file_id;
  const file = await bot.getFile(fileId);
  const filePath = file.file_path;

  await sharp(filePath)
    .resize(1000, 1000, {
      fit: 'inside',
      withoutEnlargement: true
    })
    .toFile('resized-image.jpg');
});
```

> This code:
> * Retrieves the highest resolution photo file
> * Uses Sharp to resize, maintaining aspect ratio
> * Ensures no edge exceeds 1000 pixels
> * Prevents image enlargement if smaller

Ok, that was easy. So let's ask it to connect to OpenAI's GPT API. Admittedly asking Claude to do so feels a little bit mean ...

> Nice! ok, so how would I send this image to OpenAI GPT API to run image recognition along with a prompting message "Wie lautet der Zählerstand auf dem Foto des Gaszählers. Die Zahl hat fünf Ziffern vor dem Komma und drei Nachkommastellen. Gib nur die Zahl aus, keinen Text davor oder danach" ?

Response:

> Here's a code snippet to send the image to OpenAI's API with the specified prompt:

```javascript
const axios = require('axios');
const fs = require('fs');

bot.on('photo', async (msg) => {
  const fileId = msg.photo[msg.photo.length - 1].file_id;
  const file = await bot.getFile(fileId);
  const filePath = file.file_path;

  // Resize image with Sharp
  await sharp(filePath)
    .resize(1000, 1000, {
      fit: 'inside',
      withoutEnlargement: true
    })
    .toFile('resized-image.jpg');

  // Send to OpenAI API
  const response = await axios.post('https://api.openai.com/v1/chat/completions', {
    model: "gpt-4-vision-preview",
    messages: [
      {
        role: "user",
        content: [
          {
            type: "text",
            text: "Wie lautet der Zählerstand auf dem Foto des Gaszählers. Die Zahl hat fünf Ziffern vor dem Komma und drei Nachkommastellen. Gib nur die Zahl aus, keinen Text davor oder danach"
          },
          {
            type: "image_url",
            image_url: { url: `data:image/jpeg;base64,${fs.readFileSync('resized-image.jpg', 'base64')}` }
          }
        ]
      }
    ],
    max_tokens: 300
  }, {
    headers: {
      'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
      'Content-Type': 'application/json'
    }
  });

  console.log(response.data.choices[0].message.content);
});
```

> Note: Requires setting `OPENAI_API_KEY` environment variable.

Looks good so far. It cannot know that the model is no longer in preview. So let's tell it that.
I also wonder why it's using `axios` over `node-fetch`, but likely it just has seen more examples with that one.

I'm not sure why it's using the temp file, therefore let's briefly ask it:

> ok, cool. you can just assume that meanwhile there is a model named gpt-4o-mini that's good to use.
>
> one question to the code, do I really need to create a temporary file on disk? (resized-image.jpg as you've called it)

Response:

> No, you don't need to create a temporary file. You can resize the image directly in memory using Sharp's buffer methods:

```javascript
const axios = require('axios');

bot.on('photo', async (msg) => {
  const fileId = msg.photo[msg.photo.length - 1].file_id;
  const file = await bot.getFile(fileId);
  const filePath = file.file_path;

  // Resize image to buffer
  const resizedImageBuffer = await sharp(filePath)
    .resize(1000, 1000, {
      fit: 'inside',
      withoutEnlargement: true
    })
    .toBuffer();

  // Send to OpenAI API
  const response = await axios.post('https://api.openai.com/v1/chat/completions', {
    model: "gpt-4o-mini",
    messages: [
      {
        role: "user",
        content: [
          {
            type: "text",
            text: "Wie lautet der Zählerstand auf dem Foto des Gaszählers. Die Zahl hat fünf Ziffern vor dem Komma und drei Nachkommastellen. Gib nur die Zahl aus, keinen Text davor oder danach"
          },
          {
            type: "image_url",
            image_url: { url: `data:image/jpeg;base64,${resizedImageBuffer.toString('base64')}` }
          }
        ]
      }
    ],
    max_tokens: 300
  }, {
    headers: {
      'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
      'Content-Type': 'application/json'
    }
  });

  console.log(response.data.choices[0].message.content);
});
```

> This approach avoids creating a temporary file on disk.

Okay, looks good on first sight. So let's move on to the last step: saving things to the database:

> Very nice! Last but not least, how would I connect to a PostgreSQL database and insert a new record into a table called `gas_meter`, simply storing the number returned from the GPT model along with the current timestamp?

Response:

> Here's how to connect to PostgreSQL and insert the gas meter reading:

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

bot.on('photo', async (msg) => {
  // Previous image processing and GPT API call code...

  const meterReading = response.data.choices[0].message.content;

  try {
    const client = await pool.connect();
    await client.query(
      'INSERT INTO gas_meter (reading, timestamp) VALUES ($1, NOW())', 
      [meterReading]
    );
    client.release();
  } catch (err) {
    console.error('Database insert error:', err);
  }
});
```

> This code:
>
> * Uses pg library for PostgreSQL connection
> * Connects via DATABASE_URL environment variable
> * Inserts reading with current timestamp
> * Handles connection and potential errors

I've seen before, that GPT uses a comma, instead of a dot, to separate the decimal places. Let's help Claude ...

> Take into account, that the GPT may answer in German locale, so using a comma as a decimal separator. The database should save the value as a floating point number

Response:

> Here's the updated code to handle German number format:

```javascript
bot.on('photo', async (msg) => {
  // Previous code...

  const meterReading = response.data.choices[0].message.content
    .replace(',', '.'); // Convert German decimal comma to dot

  try {
    const client = await pool.connect();
    await client.query(
      'INSERT INTO gas_meter (reading, timestamp) VALUES ($1, NOW())', 
      [parseFloat(meterReading)]
    );
    client.release();
  } catch (err) {
    console.error('Database insert error:', err);
  }
});
```

> Key changes:
>
> * Replace comma with dot
> * Use parseFloat() to convert to a proper floating-point number
> * Directly pass to PostgreSQL query

Ok, so we have all pieces together. Let's ask it to combine everything

> Cool. So now let's piece everything together. Create a Telegram bot in JavaScript language, that takes an images, scales it to not eat too many tokens. Feed it through GPT to read the number and store it to the database please!

Response:

> Requirements before running:
> 1. Set environment variables:
>    * TELEGRAM_BOT_TOKEN
>    * OPENAI_API_KEY
>    * DATABASE_URL
> 2. Install dependencies: npm install node-telegram-bot-api pg sharp axios
> 3. Ensure PostgreSQL table exists with schema: CREATE TABLE gas_meter (reading FLOAT, timestamp TIMESTAMP);

I like having .env files, at least while running stuff locally. So let's ask it to add dotenv:

> Modify the code so that it optionally reads from an .env file, if it exists

Response:

> [telegram-gas-meter-bot.js, second version](https://github.com/stesie/gaszaehler-bot-1/blob/2c4012df8d4d5bbffc171448176e20689789df08/telegram-gas-meter-bot.js)

> Key changes: 
> * Added check for .env file existence
> * Uses dotenv to load environment variables if file exists
> * Requires minimal additional setup

Ok, so it was easy to run now. However it didn't work. Giving Claude a clue:

> First of all, connection to telegram API seems to work just fine. However it fails to process the image with the following error message
>
> Error processing gas meter reading: Error: Input file is missing: photos/file_0.jpg
>
> Any idea on that one?
>
> And adding to that, what do you think of adding more log output to the code?

Response:

> The error suggests the bot isn't correctly downloading the Telegram file. Here's an improved version with more logging and file download:

> [telegram-gas-meter-bot.js, third version](https://github.com/stesie/gaszaehler-bot-1/blob/296e94d528fc904db2a083ce37e768264fd6a410/telegram-gas-meter-bot.js)

> Key changes:
>
> * Added custom file download function
> * Extensive console logging
> * Explicit file URL construction
> * Added file cleanup in finally block
> * Log at bot startup
>
> This version should:
> 
> 1. Explicitly download the file from Telegram
> 2. Provide more detailed logging
> 3. Handle file download errors more robustly

Getting closer, it messed up with the temp file ([in line 55 here](https://github.com/stesie/gaszaehler-bot-1/blob/296e94d528fc904db2a083ce37e768264fd6a410/telegram-gas-meter-bot.js#L55) it's assigning a `const` within the `try` block ... however that's out of scope in the `finally` block). Let's tell it ...

>  nice, almost works. the GPT call is correct and the value is even stored to the database.
>
> However it fails to delete the file in the end, error message is this one:
>
> ReferenceError: localFilePath is not defined
>
> ... that leads me to the question, is it safe to assume the current directory is writable and we can hardcode a filename? shouldn't this go to the temp directory and use a random filename instead?

Response:

> You're right. Here's an improved version using the system's temp directory and a random filename:

> [telegram-gas-meter-bot.js, fourth version](https://github.com/stesie/gaszaehler-bot-1/blob/272f11e3e09e90d751d8ce48c5cbb384deb438ba/telegram-gas-meter-bot.js)

> Key changes:
> * Use os.tmpdir() for temporary file location
> * Generate random filename with crypto.randomBytes()
> * Add null check for localFilePath before deletion

Yay, it found out, that it needs a `let` before the `try`/`catch` 🙂
That one was actually working well. I just noticed that it would be nice to have some feedback

> Please also make the bot reply with the meter reading, so as a user I have some feedback that everything worked successfully and can also verify, that the value was indeed read correctly

Response

> [telegram-gas-meter-bot.js, fifth version](https://github.com/stesie/gaszaehler-bot-1/blob/9d4a5076657a98f71e41ef26d7af1035c23ec5ed/telegram-gas-meter-bot.js)

> Changes:
> * Added bot.sendMessage() to reply with meter reading
> * Added error message if processing fails
> * Uses German language for messages

## Summary

That went pretty smoothly. Including the time needed to create the Bot on Telegram and creating a fresh API key in the OpenAI backend, all together hardly took 15 minutes. After all putting together this post took me way longer 🙂

And well, what more can I say, the code just works fine.

Having some user interface at hand now, I started out playing some more and quickly found out that GPT-4o yields way better results compared to GPT-4o-mini. The latter once failed to put the comma correctly, so it read a number 10 times too high. GPT-4o never did that.

If I wanted to nitpick on the code, ...

  + I think it's weird, that it's using `https` module to initially download the image from Telegram, but then uses `axios` to call GPT-4o

  + arguably it's unnecessary to create a temporary file ... especially since I asked it to remove the temp file, when it passes the scaled image to the LLM ... it could have thought of not using a temp file for the file download

... but hey, nothing too weird. Would it be in a code review, I likely asked to change the former and ignored the latter. And in the end, it just works, therefore I take it as it is 🙂
