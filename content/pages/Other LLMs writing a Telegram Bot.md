---
category:
- Chat Dialogs
tags:
- AI
- Claude
- Telegram
- Image Recognition
status: budding
date: 2025-02-02
title: Other LLMs writing a Telegram Bot
categories:
- Chat Dialogs
lastMod: 2025-02-02
---
This is the fourth (and likely last) part in this mini series.

{{< logseq/orgNOTE >}}This post belongs to a mini series (I'm aiming for three posts in a row), where I try prompting Claude with different levels of verbosity and compare the results:
* In [Claude writing a Telegram Bot, 1st try]({{< ref "/pages/Claude writing a Telegram Bot, 1st try" >}}) I'm using an elaborate, step-by-step prompting strategy with Haiku model
* In [Claude writing a Telegram Bot, 2nd try]({{< ref "/pages/Claude writing a Telegram Bot, 2nd try" >}}) I aim for a detailed one-shot prompt
* In [Claude writing a Telegram Bot, 3rd try]({{< ref "/pages/Claude writing a Telegram Bot, 3rd try" >}}) I try a rather short one-shot prompt
* In [Other LLMs writing a Telegram Bot]({{< ref "/pages/Other LLMs writing a Telegram Bot" >}}) I quickly try DeepSeek and some more LLMs 
{{< / logseq/orgNOTE >}}

Since DeepSeek currently is all the rage, obviously I had to prompt it as well. So here we go

## DeepSeek V3

I go with the very same prompt that I used with my 3rd try on Claude Haiku:

{{< logseq/orgREQUEST >}}Create a telegram chatbot in JavaScript. I want to take a photo of a gas meter. Upload to OpenAI API to read the gas meter. The number has five digits before comma, and three decimal places. Then store the value to a postgres database table and return it in the chat.
{{< / logseq/orgREQUEST >}}

For reference, [here's the full JavaScript code it spat out on first try](https://gist.github.com/stesie/34c17f535de828d9e3b268093c6e3fc6)

What I found weird, that it initially has a code section where it hard-codes credentials and asks you to fill these like so:
```js
// Replace with your actual tokens and database credentials
const TELEGRAM_BOT_TOKEN = 'YOUR_TELEGRAM_BOT_TOKEN';
const OPENAI_API_KEY = 'YOUR_OPENAI_API_KEY';
const DATABASE_URL = 'postgresql://user:password@localhost:5432/gas_meter_db';
```
... just to finally conclude with a note
> **Security**: Ensure your tokens and database credentials are stored securely, not hardcoded in the script.

I mean, if you know it, why not use `dotenv` right away!? 🤷

Also it hallucinated the OpenAI endpoint
```js
 // Send the photo to OpenAI API for processing
    const response = await openai.createImageCompletion({
      image: fileUrl,
      prompt: "Extract the gas meter reading. The number has five digits before the comma and three decimal places."
    });
```
... that one just doesn't exist. Image/text recognition works via the regular completion API (using one of the omni models).

## DeepSeek R1

Of course I had to run it against their new reasoning model -- especially since it also shares it's reasoning monologue. So that is it's reasoning:

{{< logseq/orgRESPONSE >}}Okay, I need to create a Telegram chatbot using JavaScript that can take a photo of a gas meter, process it through the OpenAI API to read the numbers, store the value in a PostgreSQL database, and return it in the chat. Let me break this down step by step.

First, the user mentioned using JavaScript, so I'll probably go with Node.js since it's common for backend services. I'll need to set up a Telegram bot using the Telegram Bot API. The `node-telegram-bot-api` library is a popular choice for that.

Next, handling photo uploads. When a user sends a photo, the bot needs to download it. Telegram provides a file ID, which I can use to get the file path and then download the image. I'll need to use the `axios` library or something similar to download the image from Telegram's servers.

Then, sending the image to the OpenAI API. Wait, does OpenAI have an API for OCR? I know they have GPT-4 with vision capabilities, so maybe using the Chat Completions API with the image as a part of the prompt. The user wants to extract a number with five digits before the comma and three decimal places. So the prompt should instruct the model to return the number in that format. I'll have to structure the API request correctly, including the image in base64 encoding.

Once the number is extracted, I need to validate it. The response from OpenAI might need some regex checking to ensure it's in the correct format (#####,###). If it's not valid, the bot should ask the user to try again.

Storing the data in PostgreSQL. I'll need a PostgreSQL database set up. The `pg` library in Node.js can handle the connections. Create a table with columns for the user ID, the meter reading, and a timestamp. The bot should insert the validated number into this table.

Then, the bot needs to send a confirmation message back to the user with the stored value. Maybe also include a history feature if the user wants to see previous entries, but the user didn't mention that, so maybe stick to the basics.

Error handling is important. If the OpenAI API fails, or the image isn't clear, the bot should notify the user. Also, handle cases where the response from OpenAI isn't in the correct format.

Environment variables for API keys and database credentials. Using `dotenv` to manage them. Security-wise, make sure not to expose these in the code.

Putting it all together: the bot listens for photos, processes them through OpenAI, stores the result, and responds. Testing each part step by step would be crucial. Maybe start with the Telegram bot setup, then add image downloading, then integrate OpenAI, then database storage.

Potential issues: image quality affecting OCR accuracy, rate limits on the OpenAI API, database connection problems. Need to handle exceptions and provide user feedback for each possible failure point.

Also, cost considerations. Using OpenAI's API for image processing might incur costs, so the user should be aware of that. But that's beyond the code itself.

So, the final code structure would involve initializing the bot, handling the 'photo' message event, downloading the image, converting it to base64, sending to OpenAI with a prompt, parsing the response, validating the format, inserting into PostgreSQL, and replying to the user. Each step needs async/await handling since everything is asynchronous in Node.js.

Need to make sure the database table is correctly set up with the right schema. Maybe include a SQL script for creating the table.

Documentation in the code for clarity, and instructions on how to set up the environment variables and install dependencies.
{{< / logseq/orgRESPONSE >}}

I really like (and at the same time I'm deeply impressed) how it touches on all the topics I've addressed in the recent posts. It just ticks all the boxes, ... compared to V3 it notes that it should use `dotenv` for improved security and also that it concludes to use the vision capabilities of the regular completion API.

For reference, [here's the full JavaScript code it spat out on first try](https://gist.github.com/stesie/96ea61d51ab49b709a35fb9d5e12e696).

I also like the fact, that it went including emojis in the reply message, adding a nice touch like this:
```js
    // Send confirmation
    bot.sendMessage(chatId, `✅ Reading stored: ${reading}`);
  } catch (error) {
    console.error(error);
    bot.sendMessage(chatId, '❌ Error processing meter reading. Please try again.');
```

## Llama 3.3 70B (and 3.1 405B)

Failed to come up with a proper prompt to the third-party LLM:
```js
// Upload the photo to OpenAI API
const openaiResponse = await axios.post('https://api.openai.com/v1/images/generate', {
  prompt: 'Read the gas meter value from the image',
  image: photoBuffer.toString('base64'),
}, {
  headers: {
    'Authorization': `Bearer ${openaiApiKey}`,
    'Content-Type': 'application/json',
  },
});
```

  + First of all, why doesn't it use a library, but call the API directly!?

  + Next the URL is completely made up, there's no such thing as `/v1/images/generate`. And why "generate" at all? After all it's about *reading* an image.

  + Last but not least the prompt is a bit short. Why doesn't it share the information on how many digits it is supposed to find?

Directly afterward it makes very strict assumptions on what it's going to receive:
```js
// Extract the gas meter value from the OpenAI response
const gasMeterValue = openaiResponse.data.choices[0].text;
const regex = /^\d{5},\d{3}$/;
if (regex.test(gasMeterValue)) {
```
... which is likely to work in none of the cases. It even assumes a comma, instead of a point. Without asking the LLM for that, it's (supposedly) never going to use that in it's response.

For reference, [here's the full JavaScript source it spat out on first shot](https://gist.github.com/stesie/37406b103050e068018765d485c25aef)

By the way, very much the same happens with Llama 3.1 405B. That's the LLM call it generates:
```js
 const response = await axios.post('https://api.openai.com/v1/images/generations', {
   prompt: 'Read the gas meter value from the image',
   n: 1,
   size: '256x256',
   response_format: 'json',
   image: image,
 }, {
   headers: {
     'Authorization': `Bearer ${config.openai.apiKey}`,
     'Content-Type': 'application/json',
   },
 });

const gasMeterValue = response.data.data[0].text.trim();
const match = gasMeterValue.match(/^(\d{5}),(\d{3})$/);
if (match) {
  return `${match[1]}.${match[2]}`;
} else {
  throw new Error('Invalid gas meter value');
}
```
... again, the call is completely made up and/or it didn't "understand" the job. After all it's not supposed to generate an image, here it's even asking for a 256x256 result 🤷

## ChatGPT

Interestingly ChatGPT fails for the very same reason:

```js
// Upload image to OpenAI API for OCR processing
const openAiResponse = await fetch('https://api.openai.com/v1/images/generate', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    image: buffer.toString('base64'),
    model: "openai-ocr-model-id", // Assuming OpenAI has a specific OCR model
  }),
});

const data = await openAiResponse.json();

// Assuming the OCR API response contains a readable text of the gas reading
const text = data.text.trim();

// Parse the reading (assuming format like "12345.678")
const reading = parseFloat(text);
```

... the API call is made up, I like the comment "Assuming OpenAI has a specific OCR model". I mean, hey ChatGPT, you belong to OpenAI ... you maybe should know best 😂

I also quickly checked against o1-mini, which hardly did any better.

## Conclusion

I knew before that Claude 3.5, especially Sonnet, is really good at coding tasks. And the previous examples really underline that IMHO. Besides the new DeepSeek R1 it's the only model that successfully addressed the task with a brief one-shot prompt.

Furthermore I really like the reasoning output of DeepSeek R1, since it sheds some light into the problem domain, asks questions that one might want to address.

Comparing the prices, Claude 3.5 Sonnet API access currently is at input US$ 3,00 per MTOK (caches disabled) and output US$ 15,00 per MTOK.

DeepSeek R1 is at input US$ 0,55 per MTOK and output US$ 2,19 per MTOK.  Even including the tokens spent on the "chain of thought" ... it's still way cheaper than Sonnet.
