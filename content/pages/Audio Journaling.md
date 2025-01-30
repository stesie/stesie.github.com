---
tags:
- Audio Journaling
- Whisper
- Logseq
status: seedling
date: 2025-01-30
title: Audio Journaling
categories:
lastMod: 2025-01-30
---
For quite some time now, I've been using Logseq as my personal knowledge management system. It has been an invaluable tool for organizing my thoughts, projects, and ideas. A few months ago, I decided to take it a step further by incorporating journaling into my daily routine. Each morning and evening, I reflect on how I'm feeling, what has moved me, what went well during the day, where I excelled, and where there might be room for improvement.

This daily journaling practice has led me to spend even more time at the computer, diving into topics that interest me. Yet, I often find myself falling down rabbit holes, getting sidetracked from my main goal of reflection and wrapping up the day.

A few weeks ago, I stumbled upon a [journal entry by Brian Sunter](https://github.com/briansunter/graph/blob/master/logseq/journals/2023_06_10.md), where he shared his thoughts on audio journaling. He uses the Voice Memos app on his iPhone to record his thoughts, then shares the file with Logseq. From there, he employs Whisper and his GPT plugin to derive the content he needs. While his idea didn't immediately resonate with me—I couldn't see myself journaling during a walk, nor did I want to keep audio files in my Logseq assets—it did spark an interest in exploring audio journaling further.

[Thomas Frank also wrote an article](https://thomasjfrank.com/how-to-transcribe-audio-to-text-with-chatgpt-and-notion/) on the subject and created several YouTube videos. He uses Pipedreams to push data into Notion, which is an interesting approach but more suited to Notion's web-based API system.

## My Current Solution

To ease into audio journaling while keeping it simple, I've devised the following workflow:
1. Record a voice memo on my iPhone.
2. Share the recording via the Nextcloud app.
3. (The next morning) Process the audio file with OpenAI Whisper.
4. Run the transcript through a language model to correct names, remove filler words, and summarize the text into bullet points.
5. Copy and paste the results into Logseq.

I've consolidated the last three steps into a small shell script that processes the latest file, transcribes it, and runs it through a language model. The output is automatically copied to the clipboard, allowing me to simply press Control+V in Logseq.

### Automating Transcription

OpenAI Whisper is open source and easy to install. On Arch Linux, you can set it up with `sudo pacman -S python-openai-whisper`. Running `whisper "New Recording.m4a" --language German` provides initial results. However, on my Thinkpad without a powerful graphics card, it takes quite a while.

For the impatient (like me), there's a paid API option:
```bash
curl --request POST \
--url https://api.openai.com/v1/audio/transcriptions \
--header "Authorization: Bearer $OPENAI_API_KEY" \
--header 'Content-Type: multipart/form-data' \
--form file=@'New Recording.m4a' \
--form model=whisper-1 -F response_format=text -o out
```

In just a second or two, you get a transcript of your lengthy recording.

### Summarizing with the Language Model

Now that we have a transcript, it's still more of a ramble than concise answers to my daily reflection questions. Software project names and people’s names might also be misspelled.

I've come to appreciate the [Python module llm](https://llm.datasette.io/en/stable/) as a CLI tool for interacting with language models. On Arch, it's conveniently installed with `python-pipx`. Simply run `pipx install llm`. Done.

The advantage of this tool is its ability to pipe files through standard input and abstract different language models. Whether using a local Llama model or one hosted on AWS Bedrock, Claude, or OpenAI, the command remains the same. You can also set a template with maximum token count, temperature, and system prompt.

Here's the command to use:

```bash
llm --system "$(cat system.txt)" -o max_tokens 4096 --save audio-journal
```

To trigger it, simply run:

```bash
llm -t audio-journal < out
```

{{< logseq/orgNOTE >}}**System Prompt**

The system prompt is highly personal, but I'm happy to share mine for inspiration (actually mine is in German language):

You are a helpful assistant preparing transcribed audio notes for a journal. The focus is on evening reflection questions. The journal is in German. Summarize the answers concisely using bullet points, but form complete sentences. Remove filler words and phrases. Each bullet point should start with `[[gpt]]`. If a bullet point is too long, split it into two or more points.

Correct misspelled project and product names.

Correct misspelled names of people. Add last names if I only mention the first name and it's clear. Names should also be enclosed in square brackets, e.g., [[Max Mustermann]].

Names of friends: XXX

Names of some colleagues: XXX

Nicknames: XXX is YYY, XXX is YYY. Replace nicknames with full names.

Names of software projects, etc., that might be mentioned: Logseq, Todoist, Claude, Chat-GPT, Deepseek, Llama, cadiff

Your response should be formatted as follows:

## [[Evening Questions]] #daily
### [[How Am I feeling?]]
  - [[gpt]] Insert bullet points from transcript here
  - [[gpt]] Repeat line if necessary

### [[What’s Something Good That Happened Today?]]
  - [[gpt]] Insert bullet points from transcript here
  - [[gpt]] Repeat line if necessary

### [[What Did I Do Well?]]
  - [[gpt]] Insert bullet points from transcript here
  - [[gpt]] Repeat line if necessary

### [[What Could I Have Done Better?]]
  - [[gpt]] Insert bullet points from transcript here
  - [[gpt]] Repeat line if necessary

### [[What Am I Thinking of?]]
  - [[gpt]] Insert bullet points from transcript here
  - [[gpt]] Repeat line if necessary
{{< / logseq/orgNOTE >}}

By integrating audio journaling into my routine, I've found a new way to streamline my reflections and make the most of my personal knowledge management system. While it took some experimentation to find the right approach, the combination of open-source tools and creative scripting has made the process both efficient and effective.
