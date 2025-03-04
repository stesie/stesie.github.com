---
status: budding
tags:
- Java
- Java Agents
- Byte Code
date: 2025-02-26
title: Let's create a Coverage Analyzer, Part 2
categories:
lastMod: 2025-02-26
---
This is part two of my journey creating a Java (Line) Coverage Analyzer.

Here we'll actually implement the Byte Code Instrumentation, as [pointed out in the first part]({{< ref "/pages/Let's create a Coverage Analyzer, Part 1" >}}).

Since processing the Byte Code itself, i.e. reading the classes, finding the methods, processing line number information, is in itself a huge task, let's rely on [the ASM library](https://asm.ow2.io/) for that.
After all JaCoCo and Cobertura also rely on that, so this seems to be a valid choice 😂

## Hello ASM

Usage of ASM is after all pretty simple. It provides two classes `ClassReader` and `ClassWriter`, which both do what their names promise. ASM heavily relies on the visitor pattern, and `ClassWriter` itself extends the abstract `ClassVisitor` class.

The constructor of `ClassReader` does take either a `byte[]` or an `InputStream`, hence nothing fancy. A very simple example would look like this:

```java
public byte[] instrumentClass(final byte[] classBytes) throws IOException {
    final var reader = new ClassReader(classBytes);
    final var writer = new ClassWriter(0);
  
    reader.accept(writer, 0);
  
    return writer.toByteArray();
}
```

... obviously this in itself isn't very useful, since it doesn't do anything 🙂

But we can bring our own implementation of `ClassVisitor` to the table, which itself takes a `ClassVisitor` to delegate to and then starts taking action:

```java
@Log
public class CoveristaClassVisitor extends ClassVisitor {

	public CoveristaClassVisitor(final ClassVisitor writer) {
		super(Opcodes.ASM9, writer);
	}

	@Override
	public MethodVisitor visitMethod(final int access, final String name, final String descriptor,
			final String signature, final String[] exceptions) {
		log.fine("visitMethod: " + name);
		return super.visitMethod(access, name, descriptor, signature, exceptions);
	}
}
```

Nothing fancy here, we just pass the `ClassVisitor` to the parent constructor and override the `visitMethod`, logging the method name.

{{< logseq/orgNOTE >}}You might wonder what the `Opcodes.ASM9` bit is. It's just setting the ASM API version we're relying on. And as of this writing, ASM9 is the latest (stable) one.
{{< / logseq/orgNOTE >}}

Given we have a `ClassVisitor` now, let's hook that into the `instrumentClass` method from above. The reader instance delegates to our visitor. Our visitor delegates to the writer. Like this:

```java
	public byte[] instrumentClass(final byte[] classBytes) throws IOException {
		final var reader = new ClassReader(classBytes);
		final var writer = new ClassWriter(0);

		final var classVisitor = new CoveristaClassVisitor(writer);
		reader.accept(classVisitor, 0);

		return writer.toByteArray();
	}
```

... and that's it. We have a _very_ simple first `ClassVisitor` that logs all the method definitions it finds.

And given the return type of `visitMethod` you might already have noticed that there's a `MethodVisitor` as well. Given that we actually want to instrument the method, the obvious next step is to create our own implementation of such a `MethodVisitor` and hook it into our `visitMethod` call path.

```java
@Log
public class CoveristaMethodVisitor extends MethodVisitor {

	public CoveristaMethodVisitor(final MethodVisitor methodVisitor) {
		super(Opcodes.ASM9, methodVisitor);
	}

	@Override
	public void visitLineNumber(final int line, final Label start) {
		log.finer("instrument line: " + line);
		super.visitLineNumber(line, start);

		super.visitMethodInsn(Opcodes.INVOKESTATIC, "de/brokenpipe/dojo/undercovered/coverista/Tracker", "track", "()V", false);
	}
}
```

Again, the implementation is very straight forward. We receive a `MethodVisitor` instance, which we pass to the parent constructor. Then we override the `visitLineNumber` method, log the invocation, delegate to the next visitor first, ... and then the magic happens: we also call `visitMethodInsn`, and ask it to write an `INVOKESTATIC` opcode for us.

The arguments to that invocation are also very simple: the (internal) class name, the method name and the type signature. The final `false` is assigned to an argument named `isInterface`.

Internally the `visitMethodInsn` call will allocate an entry in the constants pool and write the `INVOKESTATIC` opcode, referencing the new constant. ASM also does some bookkeeping, so it won't put the same constant to the pool over and over. Therefore we can happily invoke `visitMethodInsn` for each and every line number label we'll find, and the constant will be added only once.

## Connecting it to the Agent

As we've seen in the first part, our agent just needs to provide a `premain` method and register a transformer there. Like this:

```java
@Log
public class UndercoveredAgent {
	public static void premain(final String agentArgs, final Instrumentation inst) {
		log.info("[Agent] In premain method");
		inst.addTransformer(new UndercoverTransformer());
	}
}
```

The `Transformer` just has to implement, as shown, the `transform` method:

```java
@Log
public class UndercoverTransformer implements ClassFileTransformer {
	@Override
	public byte[] transform(final Module module, final ClassLoader loader, final String className,
			final Class<?> classBeingRedefined, final ProtectionDomain protectionDomain, final byte[] classfileBuffer) {
		log.info("transforming " + className);

		try {
			return new Instrumenter().instrumentClass(classfileBuffer);
		} catch (final IOException e) {
			throw new RuntimeException("instrumentation of '" + className + "' failed", e);
		}
	}
}
```

... and the rest we've seen above.

The full source code of [the above implementation can be found on GitHub](https://github.com/stesie/undercovered/tree/naive). Make sure to check out the branch named `naive`, which matches the current progress. The repo contains a multi-module Maven setup, therefore just run `mvn package` to build.

Finally, time has come to run it for the first time. The basic invocation of the minimalist demo application looks like this:
```console
$ java -cp demo/target/demo-1.0-SNAPSHOT.jar de.brokenpipe.dojo.undercovered.demo.Demo
Hello World
to the blarg
```

Obviously we want to add our agent to the mix, and also configure logging, so our log output on fine & finer levels will show up:

```console
$ java -Djava.util.logging.config.file=./coverista/src/main/resources/logging.properties -javaagent:agent/target/agent-1.0-SNAPSHOT.jar -cp demo/target/demo-1.0-SNAPSHOT.jar de.brokenpipe.dojo.undercovered.demo.Demo
[2025-02-26 21:44:20] [INFO   ] [Agent] In premain method 
[2025-02-26 21:44:20] [INFO   ] transforming java/lang/Thread$ThreadNumbering 
[2025-02-26 21:44:20] [INFO   ] transforming sun/launcher/LauncherHelper 
[2025-02-26 21:44:20] [INFO   ] transforming de/brokenpipe/dojo/undercovered/demo/Demo 
[2025-02-26 21:44:20] [FINE   ] visitMethod: <init> 
[2025-02-26 21:44:20] [FINER  ] instrument line: 3 
[2025-02-26 21:44:20] [FINE   ] visitMethod: main 
[2025-02-26 21:44:20] [FINER  ] instrument line: 6 
[2025-02-26 21:44:20] [FINER  ] instrument line: 8 
[2025-02-26 21:44:20] [FINER  ] instrument line: 9 
[2025-02-26 21:44:20] [FINER  ] instrument line: 11 
[2025-02-26 21:44:20] [FINE   ] visitMethod: bla 
[2025-02-26 21:44:20] [FINER  ] instrument line: 14 
[2025-02-26 21:44:20] [FINER  ] instrument line: 15 
[2025-02-26 21:44:20] [INFO   ] transforming jdk/internal/misc/MainMethodFinder 
[2025-02-26 21:44:20] [INFO   ] transforming de/brokenpipe/dojo/undercovered/coverista/Tracker 
[2025-02-26 21:44:20] [FINE   ] visitMethod: <init> 
[2025-02-26 21:44:20] [FINER  ] instrument line: 6 
[2025-02-26 21:44:20] [FINE   ] visitMethod: track 
[2025-02-26 21:44:20] [FINER  ] instrument line: 9 
[2025-02-26 21:44:20] [FINER  ] instrument line: 10 
[2025-02-26 21:44:20] [FINER  ] instrument line: 11 
[2025-02-26 21:44:20] [FINER  ] instrument line: 12 
[2025-02-26 21:44:20] [FINE   ] visitMethod: <clinit> 
[2025-02-26 21:44:20] [FINER  ] instrument line: 5 
[2025-02-26 21:44:20] [INFO   ] transforming java/lang/ExceptionInInitializerError 
Exception in thread "main" [2025-02-26 21:44:20] [INFO   ] transforming java/lang/Throwable$WrappedPrintStream 
[2025-02-26 21:44:20] [INFO   ] transforming java/lang/Throwable$PrintStreamOrWriter 
java.lang.StackOverflowError
	at de.brokenpipe.dojo.undercovered.coverista.Tracker.track(Tracker.java:9)
	at de.brokenpipe.dojo.undercovered.coverista.Tracker.track(Tracker.java:9)
	at de.brokenpipe.dojo.undercovered.coverista.Tracker.track(Tracker.java:9)
	at de.brokenpipe.dojo.undercovered.coverista.Tracker.track(Tracker.java:9)
	at de.brokenpipe.dojo.undercovered.coverista.Tracker.track(Tracker.java:9)
[...]
```

The first few lines look promising, it's crawling through the classes, logging the method names and telling that it's instrumenting certain lines. As soon as the actual execution starts, it throws a `StackOverflowError` ...

... since, well, we instrumented ourselves 🙈

Also it's logging that it tried instrumenting stuff like `jdk/internal/misc/MainMethodFinder`, where it didn't find any line numbers, hence didn't do anything. But we can also just safely ignore all the `java.*`, `jdk.*` and `sun.*` classes.

Let's just slam in a simple if statement and `return null`:

```java
if (className.startsWith("java/") || className.startsWith("sun/") || className.startsWith("jdk/")
    || className.startsWith("de/brokenpipe/dojo/undercovered/coverista/")) {
    log.fine("*not* instrumenting class " + className);
    return null;
}
```

... and try again:

```console
$ java -Djava.util.logging.config.file=./coverista/src/main/resources/logging.properties -javaagent:agent/target/agent-1.0-SNAPSHOT.jar -cp demo/target
/demo-1.0-SNAPSHOT.jar de.brokenpipe.dojo.undercovered.demo.Demo
[2025-02-26 21:54:49] [INFO   ] [Agent] In premain method 
[2025-02-26 21:54:49] [FINE   ] *not* instrumenting class java/lang/Thread$ThreadNumbering 
[2025-02-26 21:54:49] [FINE   ] *not* instrumenting class sun/launcher/LauncherHelper 
[2025-02-26 21:54:49] [INFO   ] transforming de/brokenpipe/dojo/undercovered/demo/Demo 
[2025-02-26 21:54:49] [FINE   ] visitMethod: <init> 
[2025-02-26 21:54:49] [FINER  ] instrument line: 3 
[2025-02-26 21:54:49] [FINE   ] visitMethod: main 
[2025-02-26 21:54:49] [FINER  ] instrument line: 6 
[2025-02-26 21:54:49] [FINER  ] instrument line: 8 
[2025-02-26 21:54:49] [FINER  ] instrument line: 9 
[2025-02-26 21:54:49] [FINER  ] instrument line: 11 
[2025-02-26 21:54:49] [FINE   ] visitMethod: bla 
[2025-02-26 21:54:49] [FINER  ] instrument line: 14 
[2025-02-26 21:54:49] [FINER  ] instrument line: 15 
[2025-02-26 21:54:49] [FINE   ] *not* instrumenting class jdk/internal/misc/MainMethodFinder 
[2025-02-26 21:54:49] [FINE   ] *not* instrumenting class de/brokenpipe/dojo/undercovered/coverista/Tracker 
[2025-02-26 21:54:49] [FINE   ] *not* instrumenting class java/lang/StackTraceElement$HashedModules 
[2025-02-26 21:54:49] [FINER  ] hit de.brokenpipe.dojo.undercovered.demo.Demo:6 
[2025-02-26 21:54:49] [FINER  ] hit de.brokenpipe.dojo.undercovered.demo.Demo:8 
[2025-02-26 21:54:49] [FINER  ] hit de.brokenpipe.dojo.undercovered.demo.Demo:14 
Hello World
[2025-02-26 21:54:49] [FINER  ] hit de.brokenpipe.dojo.undercovered.demo.Demo:15 
[2025-02-26 21:54:49] [FINER  ] hit de.brokenpipe.dojo.undercovered.demo.Demo:9 
[2025-02-26 21:54:49] [FINER  ] hit de.brokenpipe.dojo.undercovered.demo.Demo:14 
to the blarg
[2025-02-26 21:54:49] [FINER  ] hit de.brokenpipe.dojo.undercovered.demo.Demo:15 
[2025-02-26 21:54:49] [FINER  ] hit de.brokenpipe.dojo.undercovered.demo.Demo:11 
[2025-02-26 21:54:49] [FINE   ] *not* instrumenting class java/util/IdentityHashMap$IdentityHashMapIterator 
[2025-02-26 21:54:49] [FINE   ] *not* instrumenting class java/util/IdentityHashMap$KeyIterator 
```

yay, it works 🥳

Our very simple tracker method keeps logging, which lines were hit. Obviously we'd still need to collect all the data and write it to a coverage report. But first let's try our little new analyzer a bit more...

## Trying a Loop

In the output above we've already seen, that it hits lines 14 & 15 twice each. That's the invocation of our static `bla` method, that actually prints the lines. But wouldn't it be cool to have a little for loop, that calls our method a few more times!?

Let's extend our simple demo code a little bit:

```java
public class Demo2 {
	public static void main(final String[] argv) {
		final String greeting = "Hello World";
		bla(greeting);

		for (int i = 0; i < 3; i++) {
			bla("to the blarg");
		}

		final Supplier<Integer> numberSupplier = () -> Integer.valueOf(42);
		bla("the value: " + numberSupplier.get());
	}

	private static void bla(final String greeting) {
		System.out.println(greeting);
	}
}
```

... again, nothing fancy.

Let's try & see

```console
$ java -Djava.util.logging.config.file=./coverista/src/main/resources/logging.properties -javaagent:agent/target/agent-1.0-SNAPSHOT.jar -cp demo/target
/demo-1.0-SNAPSHOT.jar de.brokenpipe.dojo.undercovered.demo.Demo2
Error: Unable to initialize main class de.brokenpipe.dojo.undercovered.demo.Demo2
Caused by: java.lang.VerifyError: Expecting a stackmap frame at branch target 41
Exception Details:
  Location:
    de/brokenpipe/dojo/undercovered/demo/Demo2.main([Ljava/lang/String;)V @21: if_icmpge
  Reason:
    Expected stackmap frame at this location.
  Bytecode:
    0000000: b800 1112 194c b800 1112 19b8 001d b800
    0000010: 1103 3d1c 06a2 0014 b800 1112 21b8 001d
    0000020: b800 1184 0201 a7ff edb8 0011 ba00 3400
    0000030: 004d b800 112c b900 3801 00b8 003c ba00
    0000040: 4800 00b8 001d b800 11b1               
  Stackmap Table:
    append_frame(@19,Object[#31],Integer)
    chop_frame(@44,1)
```

... oh no 😠

What's a `VerifyError` after all? and what stackmap frame is it talking about!? That's what [Let's create a Coverage Analyzer, Part 3]({{< ref "/pages/Let's create a Coverage Analyzer, Part 3" >}}) is about.
