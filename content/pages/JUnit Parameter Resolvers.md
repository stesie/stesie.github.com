---
category: TIL
date: 2024-12-11
tags:
- JUnit
- cadiff
- TIL
- Java
status: budding
title: JUnit Parameter Resolvers
categories: TIL
lastMod: 2024-12-11
---
Today (err, recently) I learned ... that [JUnit's extension API allows for parameter resolvers](https://junit.org/junit5/docs/current/user-guide/#extensions-parameter-resolution). These kick in every time you use arguments on a test method, lifecycle method or class constructor. For me, so far, none of these methods ever took an argument. But turns out, it's possible ... and even useful.

They have a [primitive example here](https://github.com/junit-team/junit5-samples/blob/r5.11.3/junit5-jupiter-extensions/src/main/java/com/example/random/RandomParametersExtension.java) where they allow a test method to take a random number like so:
```java
@Test
void shouldDoStuff(@Random int number) {
  // actually do stuff here ...
}
```
... in essence you just need an annotation interface, that's linked to an extension class, that implements `ParameterResolver` interface (which just has two methods to implement).

### My Use-case

Recently I've been spending my spare time on a tool called [cadiff](https://github.com/stesie/cadiff), which is about diff-ing bpmn diagram files. Literally all of the integration tests need to load *two* bpmn files, parse them and then actually start testing/asserting stuff. This easily starts to bloat your tests.

Enter *Parameter Resolvers*, my tests now look like this (at least the setup code):
```java
@Nested
public class WithRef extends AbstractComparePatchIT {

  public WithRef(@BpmnFile("empty-diagram.bpmn") final BpmnModelInstance from,
                 @BpmnFile("error-end-event-with-ref.bpmn") final BpmnModelInstance to) {
    super(from, to);
  }

  // actual tests ...
}
```

### Resources

  + [Implementation of @BpmnFile and parameter resolver](https://github.com/stesie/cadiff/blob/main/cadiff-core/src/test/java/de/brokenpipe/cadiff/core/diff/control/BpmnFile.java)

  + [ErrorEndEventIT class as an example](https://github.com/stesie/cadiff/blob/main/cadiff-core/src/test/java/de/brokenpipe/cadiff/core/diff/control/creators/ErrorEndEventIT.java#L56)
