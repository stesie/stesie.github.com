---
tags:
- Camunda
- Dependency Inversion
date: 2025-06-19
status: seedling
title: Dependency Inversion for Camunda Tasks
categories:
lastMod: 2025-06-19
---
In Camunda Service Tasks can be implemented using so-called _delegate expressions_, which, in the context of CDI, resolve to `@Named` annotated beans.

This task class has to implement the `JavaDelegate` interface, which mandates a method named `execute`, which receives a single argument with a `DelegateExecution` instance. However there is the _Dependency Inversion Principle_ (DIP), and this way our business code directly depends on two classes from Camunda. Can't we do better?

What about providing an abstraction over the variable scopes and an interface of our own, tagging all our service classes? And afterward have implementation that binds these interfaces.

First of all, Camunda has a hard-coded `instanceof` check, asserting the invoked Bean actually implements the interface like this:
```java
        Object delegate = expression.getValue(execution);

        // ...
        } else if (delegate instanceof JavaDelegate) {
          Context.getProcessEngineConfiguration()
            .getDelegateInterceptor()
            .handleInvocation(new JavaDelegateInvocation((JavaDelegate) delegate, execution));
        }
// ...

    executeWithErrorPropagation(execution, callable);
```
([see here](https://github.com/camunda/camunda-bpm-platform/blob/7.23.0/engine/src/main/java/org/camunda/bpm/engine/impl/bpmn/behavior/ServiceTaskDelegateExpressionActivityBehavior.java#L115))

... so it's not as simple as just leaving it away.

My next thought was to provide a `@AroundConstruct` interceptor. However these do **not** allow to replace (or rather wrap) the constructed object. You delegate the call, upon the inner-most delegate call the object is created and then passed upwards. You may invoke methods on the newly created object, but there's no API to replace it.

## Enter CDI Extensions

The plan is after all simple

  + take the `@Named` service task implementations, register them with CDI, but do **not** actually register them under the name

  + create proxy classes, that implement `JavaDelegate`, register these under the original name

  + when that proxy is actually invoked, create an instance of the actual implementation and delegate to it

### Observing ProcessAnnotatedType

Let's assume our service tasks now implement the `AcmeTask` interface, then we can **observe** on `ProcessAnnotatedType` and check for instances of it like so:

```java
        <T> void processAnnotatedType(@Observes final ProcessAnnotatedType<T> pat) {
                if (AcmeTask.class.isAssignableFrom( pat.getAnnotatedType().getJavaClass() ) {
                        log.info("Processing annotated type " + pat.getAnnotatedType().getJavaClass());
                        pat.setAnnotatedType(new AnnotatedTypeShadowNamedWrapper<>(pat.getAnnotatedType()));
                        // pat.veto(); // Prevent CDI from registering it
                }
        }
```

With `pat.veto()` we could keep the bean from being registered at all. Yet this is not what we want, since in the end we still want to be able to instantiate these beans later on -- and profit from the dependency injection functionality into these.

Instead we just hide the `@Named` annotation from `pat`. The `AnnotatedTypeShadowNamedWrapper` is a lightweight wrapper, delegating all calls to the wrapped object, ... just denying existence of that single annotation like so:

```java
public static class AnnotatedTypeShadowNamedWrapper<T> implements AnnotatedType<T> {

  private final AnnotatedType<T> delegate;

  public AnnotatedTypeShadowNamedWrapper(final AnnotatedType<T> delegate) {
    this.delegate = delegate;
  }

  @Override
  public <A extends Annotation> A getAnnotation(final Class<A> annotationType) {
    if (annotationType == Named.class) {
      return null;
    }

    return delegate.getAnnotation(annotationType);
  }

  @Override
  public Set<Annotation> getAnnotations() {
    final Set<Annotation> annotations = new HashSet<>(delegate.getAnnotations());
    annotations.removeIf(a -> a.annotationType().equals(Named.class));
    return annotations;
  }

  @Override
  public boolean isAnnotationPresent(final Class<? extends Annotation> annotationType) {
    if (annotationType == Named.class) {
      return false;
    }

    return delegate.isAnnotationPresent(annotationType);
  }
  
  // everything else is just passed through ...
}
```

## Creating the Proxy Beans

Now that we've hidden the Named beans, we need to provide suitable replacements, that implement `JavaDelegate` and are named.

To achieve this, we need to add some bookkeeping to the observer method above, that tracks the registered name and class instance. Next we can observe the `AfterBeanDiscovery` event, which provides a means to register extra beans (one for each task), declaring its type, name and scope:

```java
void afterBeanDiscovery(@Observes final AfterBeanDiscovery abd, final BeanManager bm) {
  abd.addBean(new Bean<JavaDelegate>() {
    @Override
    public Class<?> getBeanClass() {
      return JavaDelegate.class;
    }

    @Override
    public Set<Annotation> getQualifiers() {
      return Set.of(NamedLiteral.of("taskValidateStuff"));
    }

    @Override
    public String getName() {
      return "taskValidateStuff";
    }
    
    @Override
    public Class<? extends Annotation> getScope() {
      return Dependent.class;
    }

```

... next we need to implement the `create` method, which must create an instance of `JavaDelegate`, every time the bean manager is asked for one. Since `JavaDelegate` is an interface, we can just use good old `Proxy.newProxyInstance` to get an instance and provide an `InvocationHandler` that waits for the `execute` call and delegates to our `AcmeTask`. There we can also add a wrapper abstracting process engine access.

```java

    @SneakyThrows
    @Override
    public JavaDelegate create(final CreationalContext<JavaDelegate> ctx) {
      final var baseInstance = (AcmeTask) bm.getReference(bm.resolve(bm.getBeans(clazz)), clazz, ctx);

      return (JavaDelegate) Proxy.newProxyInstance(clazz.getClassLoader(),
        new Class[] { JavaDelegate.class },
        (InvocationHandler) (proxy, method, args) -> {
          log.info("Intercepted method: " + method.getName());
          if ("execute".equals(method.getName())) {
            // args[0] has the DelegateExecution
            baseInstance.execute( new DelegateExecutionWrapper( args[0] ));
          }
          return null;
        });
    }
```
