---
tags:
- Keycloak
status: seedling
date: 2026-03-19
title: Keycloak Token Exchange
categories:
lastMod: 2026-03-19
---
At _Bar-Code_ Developer Barcamp last week someone mentioned a feature named _On behalf of_ in Microsoft Entra (in the context of a user requesting an Agent/LLM to query the database on her behalf). That lead me to the question: does keycloak support this as well?

And indeed it does. In Keycloak it's just called [Token Exchange](https://www.keycloak.org/securing-apps/token-exchange) and was introduced as a stable feature in Keycloak 26.2

So given a `ui` client, and orchestrating backend client (named `cxc`) and multiple resource servers (e.g. `backend-a` and `backend-b`), can Keycloak be configured so that

  + the `ui` token does have none of the resource server roles

  + the `cxc` client can trade the user's token for access tokens to the resource servers

I just asked Claude Sonnet (with medium-level reasoning) to try it. And yes, indeed it's possible.

> KC26 allows requesting optional scopes during token exchange that were **not in the subject token's scope**. This is technically "upscoping" but KC26 permits it for the exchange client's optional scopes.

See [Full Demo here](https://wuecode.it/stesie/research/src/branch/main/keycloak-token-exchange/demo2.md).

In Keycloak's config interface it looks like this:

![image.png](/assets/image_1773906343447_0.png)

Each _token mapper_ can add a single hardcoded role. If the scope requires multiple of them, more such mappers may be added.
