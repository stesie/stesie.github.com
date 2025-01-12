---
category: TIL
tags:
- TIL
- JUnit
date: 2024-08-24
lastmod: 2024-08-24
status: budding
title: JUnit Assumptions API
categories: TIL
lastMod: 2024-08-24
---
Today, I discovered a powerful feature in JUnit: the [Assumptions API](https://junit.org/junit5/docs/5.0.0/api/org/junit/jupiter/api/Assumptions.html). This API allows you to define assumptions for your tests. If an assumption isn't met, the test execution is **aborted** rather than marked as failed. This distinction is crucial in scenarios like conditional test execution in CI pipelines. When a test is skipped due to an unmet assumption, it appears as "skipped" in the test reports, not as "passed" or "failed."

### How It Works

Under the hood, the Assumptions API uses a `TestAbortedException` to terminate the test execution gracefully. Here's a simple example:

```java
assumeTrue("CI".equals(System.getenv("ENV")));
```

If the condition in `assumeTrue` is false, the test will halt, signaling that the environment wasn't suitable for execution.

This is far more elegant and meaningful than manually logging and exiting the test with constructs like:

```java
if (!condition) {
    log.info("cannot run");
    assertTrue(true);
    return;
}
```

Avoid using such patterns—they clutter the code and lack the semantic clarity offered by the Assumptions API.

Relevant JUnit documentation: https://junit.org/junit5/docs/current/user-guide/#writing-tests-assumptions
