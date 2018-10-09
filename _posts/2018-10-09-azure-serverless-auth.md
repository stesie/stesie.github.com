---
layout: post
title: "AD-based auth on Azure w/ serverless framework"
tags: [ "Serverless Framework", "Azure", "AD" ]
---
So I recently gave the marvellous [serverless framework](https://serverless.com/framework)
another try, this time with Azure Functions.  On our company account ... which uses AD-based
login.  Yet serverless framework wants (and only supports to) interactively create a service
principal account and grant access rights to that one.  Per se this is a good idea, yet
my AD-user of course may not grant these rights.

If you try to do it anyway, you'll get an error message like this:

```
  Error --------------------------------------------------
 
  The client 'stefan.siegl@mayflower.de' with object id '00000000-0000-0000-0000-000000000000' does not have authorization to perform action 'Microsoft.Authorization/roleAssignments/write' over scope '/subscriptions/00000000-0000-0000-0000-000000000000'.
```

To me it doesn't feel like a viable option to ask the AD-admin to grant those rights to each
employee's service principal account (manually later on).  So I wanted to try whether it's
feasible to just recycle azure-cli's access tokens (which resides under `~/.azure/accessTokens.json`).

And off I went, ... [here's the Gist with the resulting .patch file](https://gist.github.com/stesie/5ae160647d6ff29a69a4ad7372d706f7).

After installing `serverless-azure-functions` node module, just apply the patch like this:

```
curl https://gist.githubusercontent.com/stesie/5ae160647d6ff29a69a4ad7372d706f7/raw/ebcf67f6c207e2f21be5a0f870de5660c7955e69/serverless-azure-functions-auth.patch | \
  patch -p1
```

... of course this is quite a hack.  For the moment it works.  If you feel like this should
be done differently, or go upstream somehow, feel free to ping me.  Either by e-mail or over
on Twitter.
