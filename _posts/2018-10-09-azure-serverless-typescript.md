---
layout: post
title: "Azure Functions on Typescript"
tags: [ "Serverless Framework", "Azure", "Azure Functions", "Typescript", "Webpack" ]
---
I've been playing around with Azure Functions for quite some time now.  However I've
been trying it with the corresponding Visual Studio Code extension.  After all it's a
pretty smooth start, all things are published by Microsoft itself and well documented.

Soon I noticed that access to the filesystem seems to be slow on Azure's
serverless runtime.  This is if your code relies on larger amounts of files to be loaded
from `node_modules`, then you'll face long cold start times.  However there's a simple
solution to that: Webpack.  And I wanted to go with Typescript anyhow, so let's
use `ts-loader` as well.  How hard can it be.

Since there was no template project for it, I've just [created a new project template
azure-nodejs-typescript](https://github.com/stesie/azure-nodejs-typescript) over on GitHub.
It's mainly a mashup of [aws-nodejs-typescript](https://github.com/serverless/serverless/tree/master/lib/plugins/create/templates/aws-nodejs-typescript)
template and the [azure-nodejs](https://github.com/serverless/serverless/tree/master/lib/plugins/create/templates/azure-nodejs) one.

To create a new serverless service project based on it, simply run the following (after
possibly installing serverless framework globally before):

```
$ sls create --template-url https://github.com/stesie/azure-nodejs-typescript --name my-new-service
$ cd my-new-service
$ yarn install
```

It's just the minimal outline to get you started: a simple hello function with HTTP bindings.

```typescript
import { IContext, HttpRequest } from 'azure-functions-typedefinitions';

export function hello (context: IContext, req: HttpRequest): void {
  context.log.info('Hello from a typed function!');

  const resBody = {
    invocationId: context.invocationId,
    name: context.executionContext.functionName,
    startTimeUtc: context.bindingData.sys.utcNow
  };

  context.res.json(resBody);
}
```

... as you can see it already comes with a dependency on `azure-functions-typedefinitions`
and declares types on both handler arguments.  This allows for convenient auto-completion
(and type-checking) within context, i.e. `context.res.json`.


PS: I haven't noticed those before, but there are helper methods on the `context.res` object,
to fluently construct the response.
[See the definition of Response class for details](https://github.com/Azure/azure-functions-nodejs-worker/blob/dev/src/http/Response.ts).
