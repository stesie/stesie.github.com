---
slug: aws-iot-pubsub
date: 2016-04-02
tags:
- AWS
- IoT
- PubSub
- Javascript
- Webapp
title: Serverless Pub Sub with AWS IoT
categories:
lastMod: 2025-01-03
---
I'm currently very interested in serverless (aka no dedicated backend required) JavaScript Web Applications ... with AWS S3, Lambda & API Gateway you can actually get pretty far.
Yet there is one thing I didn't know how to do: Pub/Sub or "Realtime Messaging".

Realtime messaging allows to build web applications that can instantly receive messages published by another application (or the same one running in a different person's browser). There even are cloud services permitting to do exactly this, e.g. [Realtime Messaging Platform](http://framework.realtime.co/messaging/) and [PubNub Data Streams](https://www.pubnub.com/products/publish-subscribe/) ...

However recently having played with AWS Lambda and S3 I was wondering how this could be achieved on AWS... and at first it seemed like it really isn't possible. Especially the otherwise very interesting article [Receiving AWS IoT messages in your browser using websockets](https://medium.com/@jparreira/receiving-aws-iot-messages-in-your-browser-using-websockets-9b87f28c2357) by @jtparreira misled me, as he's telling that it wouldn't be possible. The article was published Nov 2015, ... not so long ago. But turns out it's outdated anyways...

## Enter AWS IoT

While reading I stumbled over [AWS IoT](https://aws.amazon.com/iot/) which allows to connect "Internet of Things" devices to the AWS cloud and furthermore provides messaging between those devices. It has a message broker (aka Device Gateway) sitting in the middle and "things" around it that connect to it. It's based on the MQTT protocol and there are SDKs for the Raspberry Pi (Node.js), Android & iOS ... sound's interesting, but not at all like "web browsers"

## MQTT over Web Sockets

Then I found an announcement: [AWS IoT Now Supports WebSockets](https://aws.amazon.com/about-aws/whats-new/2016/01/aws-iot-now-supports-websockets-custom-keepalive-intervals-and-enhanced-console/) published Jan 28, 2016.
Brand new, but sounds great :)

... so even when IoT still sounds strange to do Pub/Sub with - it looks like a way to go.

## Making it work

For the proof of concept I didn't care to publish AWS IAM User keys to the web application (of course this is a smell to be fixed before production use). So I went to "IAM" in the AWS management console and created a new user first, attaching the pre-defined `AWSIoTDataAccess` policy.

So the proof of concept should involve a simple web page that allows to establish a connection to the broker, features a text box where a message can be typed plus a publish button. So if two browsers are connected simultaneously then both should immediately receive messages published by one of them.

required parts: ... we of course need a MQTT client and we need to do AWS-style request signing in the browser. NPM modules to the rescue:

  + `aws-signature-v4` does the signature calculation

  + `crypto` helps it + some extra hashing we need to do

  + `mqtt` has an MqttClient

... all of them have browser support through `webpack`. So we just need some more JavaScript to string everything together. To set up the connection:


```js
let client = new MqttClient(() => {
  const url = v4.createPresignedURL(
      'GET',
      AWS_IOT_ENDPOINT_HOST.toLowerCase(),
      '/mqtt',
      'iotdevicegateway',
      crypto.createHash('sha256').update('', 'utf8').digest('hex'),
      {
          'key': AWS_ACCESS_KEY,
          'secret': AWS_SECRET_ACCESS_KEY,
          'protocol': 'wss',
          'expires': 15
      }
  );

  return websocket(url, [ 'mqttv3.1' ]);
});
```

... here `createPresignedURL` from `aws-signature-v4` first does the heavy-lifting for us. We tell it the IoT endpoint address, protocol plus AWS credentials and it provides us with the signed URL to connect to.

There was just one stumbling block to me: I had upper-case letters in the hostname (as it is output by `aws iot describe-endpoint` command), the module however doesn't convert these to lower case as expected by AWS' V4 signing process ... and as a matter of that access was denied first.

Having the signed URL we simply pass it on to a `websocket-stream` and create a new `MqttClient` instance around it.

Connection established ... time to subscibe to a topic. Turns out to be simple:

```js
client.on('connect', () => client.subscribe(MQTT_TOPIC));
```

Handling incoming messages ... also easy:

```js
client.on('message', (topic, message) => console.log(message.toString()));
```

... and last not least publishing messages ... trivial again:

```js
client.publish(MQTT_TOPIC, message);
```

... that's it :-)

## My proof of concept

here's what it looks like:

![screenshot of demo web page](/assets/pubsub-demo.png)

... the last incoming message was published from another browser running the exact same application.

I've published my source code [as a Gist on Github](https://gist.github.com/stesie/dabc9236ef8fc4123609f9d81df6ccd8), feel free to re-use it.

To try it yourself:

  + clone the Gist

  + adjust the constants declared at the top of `main.js` as needed

    + create a user in IAM first, see above

    + for the endpoint host run `aws iot describe-endpoint` CLI command

  + run `npm install`

  + run `./node_modules/.bin/webpack-dev-server --colors`

## Next steps

This was just the first (big) part. There's more stuff left to be done:

  + neither is hard-coding AWS credentials into the application source the way to go nor is publishing the secret key at all

  + ... one possible approach would be to use the API Gateway + Lambda to create pre-signed URLs

  + ... this could be further limited by using IAM roles and temporary identity federation (through STS Token Service)

  + there's no user authentication yet, this should be achievable with [AWS Cognito](https://aws.amazon.com/cognito/)

  + ... with that publishing/subscribing could be limitted to identity-related topics (depends on the use case)
