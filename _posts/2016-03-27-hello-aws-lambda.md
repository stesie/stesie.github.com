---
layout: post
title: "replacing Huginn with λ"
tags: [ "AWS", "Lambda", "Node.js", "S3", "SES", "Huginn" ]
---
I used to self-host the Ruby application [Huginn](https://github.com/cantino/huginn) which is some kind of [IFTTT](https://ifttt.com) on steroids.  That is it allows to configure so-called agents that perform certain tasks online, automatically.  One of those tasks was to regularly scrape the [Firefox website](https://www.mozilla.org/en-US/firefox/new/) for the latest firefox version number (which happens to be a data-attribute on the html element by the way), take only the major version number, compare it to the most recent known value (aka last crawl cycle) and send an email notification if it changes.  I wanted to have that notification so I could test, update & release Geierlein.

The thing is that that worked really well (I had it around for almost a year now), ... nevertheless I decided to cut down (many) self-hosted projects (saving time on hosting, constantly updating, etc. to have more time for honing my software development skills).  But I still needed those notifications so I had to find an alternative ... and I found it in AWS Lambda.

(actually I've been interested in Lambda since they had it in private beta, I even applied for the beta program, ... but never really used it as I had no idea what to do with it back then)

So my all AWS services approach involves

* a CloudWatch scheduler event that triggers AWS Lambda
* [AWS Lambda](https://aws.amazon.com/lambda/) doing the web scraping & flow control
* [S3](https://aws.amazon.com/s3/) to persist the last known major version number
* [SES (simple e-mail services)](https://aws.amazon.com/ses/) to send the e-mail notification

I've used S3 and configured stuff with IAM before, SES is really straight forward, so actually only Lambda was new to me.  Then the learning curve is okayish, as the AWS documentation guides into the right direction and Google + StackOverflow helps for the rest.  If you've never used AWS services before, then the learning curve might be a bit steeper (mainly because of IAM) ...

All in all I got it working within two hours or maybe three ... and it just works now :)  
... without nothing for me to host anymore  
... and actually everything for free (as Lambda & SES stay within free usage quota and the single S3 object's cost is negligible)

In case you want to follow along, here's my ...

step by step guide
------------------

under IAM service ...

* create AWS user with API keys to do local development (using AWS root account is undesirable)
* grant that user the necessary permissions
   * managed policy `AWSLambdaFullAccess` (that includes full access to logs & S3)
   * yet it doesn't include the right to send e-mails via SES, therefore create a user policy like

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1459031930000",
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

under S3 service ...

* create a new Bucket to be used with Lambda, I picked *lambdabrain* (so pick something else)

again under IAM service ...

* create an AWS role, to be used by our lambda function later on
* choose *AWS Lambda* from *AWS Service Roles* in Step 2 of the assistant, then attach `AWSLambdaBasicExecutionRole` policy
* do *not* attach the `AWSLambdaExecute` managed policy as it includes read/write access to all object of all your S3 buckets
* last not least add a custom Role Policy to grant rights on the newly created S3 Bucket + `ses:SendEmail` with

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::lambdabrain"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::lambdabrain/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```
... turns out the `s3:ListBucket` is actually needed to initially create the persistance object.

under AWS SES

* validate your mail domain (so you can send mails to yourself)
* if you would like to send mails to other domains you also need to request a limit increase also


After setting up [AWS CLI](https://aws.amazon.com/cli/) finally it's time to (locally) create a Node.js application (the Lambda function to be).

* create a new folder
* ... and an initial `package.json` file like this:

```json
{
  "name": "firefox-version-notifier",
  "version": "0.0.1",
  "description": "firefox version checker & notifier",
  "main": "index.js",
  "dependencies": {
    "promise": "^7.1.1",
    "scrape": "^0.2.3"
  },
  "devDependencies": {
    "node-lambda": "^0.7.1",
    "aws-sdk": "^2.2.47"
  },
  "author": "Stefan Siegl <stesie@brokenpipe.de>",
  "license": "MIT"
}
```

I used promises throughout my code, and `scrape` to do the web scraping.

* `aws-sdk` is actually needed in production as well, still I declared it under `devDependencies` as it is available globally on AWS Lambda and hence need not be included in the ZIP archive upload later on.
* `node-lambda` is a neat tool to assist development for AWS Lambda

* run `npm install` and `./node_modules/.bin/node-lambda setup`
* configure node-lambda through the newly created `.env` file as needed
   * `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` of the IAM user from above
   * `AWS_ROLE_ARN` is the full role ARN (from above)
   * `AWS_HANDLER=index.handler` (`index` because of the `index.js` file name, `handler` will be the exported name in there)

Here's my straight-forward code, ... definitely deserves some more love, yet it's just a better shell script ...  
Adapt the name of the S3 bucket and the e-mail addresses (sender and receiver) of course.

```js
var Promise = require('promise');
var AWS = require('aws-sdk');
var scrape = Promise.denodeify(require('scrape').request);

var brain = new AWS.S3({ params: { Bucket: 'lambdabrain' }});
var ses = new AWS.SES();

function getCurrentFirefoxVersion() {
	return scrape('https://www.mozilla.org/en-US/firefox/new/')
		.then(function($) {
			var currentFirefoxVersion = $('html')[0].attribs['data-latest-firefox'].split(/\./)[0];
			console.log('current firefox version: ', currentFirefoxVersion);
			return currentFirefoxVersion;
		});
}

function getBrainValue(key) {
	return new Promise(function(resolve, reject) {
		brain.getObject({ Key: key })
		.on('success', function(response) {
			resolve(response.data.Body.toString());
		})
		.on('error', function(error, response) {
			if(response.error.code === 'NoSuchKey') {
				resolve(undefined);
			} else {
				reject(error);
			}
		})
		.send();
	});
}

function setBrainValue(key, value) {
	return new Promise(function(resolve, reject) {
		brain.putObject({ Key: key, Body: value })
		.on('success', function(response) {
			resolve(response.requestId);
		})
		.on('error', function(error) {
			reject(error);
		})
		.send();
	});
}

function sendNotification(subject, message) {
	return new Promise(function(resolve, reject) {
		ses.sendEmail({
			Source: 'stesie@brokenpipe.de',
			Destination: { ToAddresses: [ 'stesie@brokenpipe.de' ] },
			Message: {
				Subject: { Data: subject },
				Body: {
					Text: { Data: message }
				}
			}
		})
		.on('success', function(response) {
			resolve(response);
		})
		.on('error', function(error, response) {
			console.log(error, response);
			reject(error);
		})
		.send();
	});
}

exports.handler = function(event, context) {
	Promise.all([
		getCurrentFirefoxVersion(),
		getBrainValue('last-notified-firefox')
	])
	.then(function(results) {
		if(results[0] === results[1]) {
			console.log('Firefox versions remain unchanged');
		} else {
			return sendNotification('New Firefox version!', 'Version: ' + results[0])
				.then(function() {
					return setBrainValue('last-notified-firefox', results[0]);
				});
		}
	})
	.then(function(results) {
		context.succeed("finished");
	})
	.catch(function(error) {
		context.fail(error);
	});
};
```

* `exports.handler` function initially creates an all-promise that (in parallel)
   * scrapes the Firefox website
   * fetches the S3 object
* then compares the two and (if different) ...
   * creates another promise to send a notification
   * ... (if successful) then updates the S3 object
* and finally marks the lambda function as successful (via `context.succeed`)

I really like how the promises allow to easily parallelize stuff as well as make things depend on another (S3:PutObject on SES:SendMail)

Run `./node_modules/.bin/node-lambda run` to test the script locally.  If it works run `./node_modules/.bin/node-lambda deploy` to upload.

Back in the AWS console, now under "Lambda"

* you should see the new function, click it and hit "Test" to try it on AWS.
* if it does, choose "Publish new version" from the "Actions".
* under "Event sources" add a new event source, choose "CloudWatch Events - Schedule" and choose an interval (I picked daily)

