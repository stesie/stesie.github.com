---
status: budding
tags:
- Java
- Java Agents
- Byte Code
date: 2025-03-01T18:30:00Z
title: Let's create a Coverage Analyzer, Part 4
categories:
lastMod: 2025-03-01
---
This is part four of my journey creating a Java (Line) Coverage Analyzer.

This time around we'll test the [implementation created in part three]({{< ref "/pages/Let's create a Coverage Analyzer, Part 3" >}}) and look into details what still goes wrong.

One (simplified) example that crashes the current analyzer implementation is this one:

```java
public class Demo3 {
	public static void main(final String[] argv) {
		final Stuff stuff = new Stuff(
				!getBoolean());
		bla("value: " + stuff.boolValue());
	}

	public static boolean getBoolean() {
		return true;
	}

	private static void bla(final String greeting) {
		System.out.println(greeting);
	}

	record Stuff(boolean boolValue) {
	}
}
```

... the line break between lines 3 and 4 is actually important. Having the argument on the same line wouldn't cause the issue. However adding more arguments, and spreading these over multiple lines, would again trigger the issue.

If we run the example above against the current version of the analyzer, we'll see this error message:
> Error: Unable to initialize main class de.brokenpipe.dojo.undercovered.demo.Demo3
>
> Caused by: java.lang.ClassFormatError: StackMapTable format error: bad offset for Uninitialized in method 'void de.brokenpipe.dojo.undercovered.demo.Demo3.main(java.lang.String[])'

So what is this _Uninitialized_ thing?

Let's have a look at the byte code of the *not* instrumented code first:

```
  public static void main(java.lang.String[]);
      stack=3, locals=2, args_size=1
         0: new           #7                  // class de/brokenpipe/dojo/undercovered/demo/Demo3$Stuff
         3: dup
         4: invokestatic  #9                  // Method getBoolean:()Z
         7: ifne          14
        10: iconst_1
        11: goto          15
        14: iconst_0
        15: invokespecial #15                 // Method de/brokenpipe/dojo/undercovered/demo/Demo3$Stuff."<init>":(Z)V
[...]
      LineNumberTable:
        line 6: 0
        line 7: 4
[...]
      StackMapTable: number_of_entries = 2
        frame_type = 255 /* full_frame */
          offset_delta = 14
          locals = [ class "[Ljava/lang/String;" ]
          stack = [ uninitialized 0, uninitialized 0 ]
        frame_type = 255 /* full_frame */
          offset_delta = 0
          locals = [ class "[Ljava/lang/String;" ]
          stack = [ uninitialized 0, uninitialized 0, int ]
```

... the Stack Map Table again, our old friend 🙂

First of all, note how the creation of the class instance (`new` opcode, in location 0) and the actual initialization (`invokespecial` opcode, in location 15) are actually two different steps. It is simply *not* the case, that the `new` opcode invokes the constructor.

Since the Java code inverts the result of the `getBoolean` invocation, it also emits some code to actually invert the result. Since it's using `ifne` and `goto`, which both are branch instructions targeting different locations ... two entries to the Stack Map Table become necessary. And within these, it records, that the class instantiated by the `new` opcode in location 0 is not yet *initialized*.

If you have a close look at the Line Number Table, it becomes clear that our implementation will instrument at locations 0 & 4 ... and you can already guess what's going wrong.

Let's have a look at the byte code after instrumentation:

```
  public static void main(java.lang.String[]);
      stack=5, locals=2, args_size=1
         0: ldc           #16                 // String de/brokenpipe/dojo/undercovered/demo/Demo3
         2: bipush        6
         4: invokestatic  #22                 // Method de/brokenpipe/dojo/undercovered/coverista/tracking/Tracker.track:(Ljava/lang/String;I)V
         7: new           #7                  // class de/brokenpipe/dojo/undercovered/demo/Demo3$Stuff
[...]        
      StackMapTable: number_of_entries = 2
        frame_type = 255 /* full_frame */
          offset_delta = 21
          locals = [ class "[Ljava/lang/String;" ]
          stack = [ uninitialized 0, uninitialized 0 ]
```

... the stack frames are still properly written, but the offsets of the `uninitialized` still point to location 0. However at location 0 there's now our `ldc` opcode, and the `new` is at 7 now. The goal is clear: we need to update that offset.

ASM's way of handling this is, that it tracks the offsets using labels. Therefore let's push our new label right before the `new` opcode and map the label in the `visitFrame` call. I've added a class-level field `surrogateLabels` to hold the mapping:
```java
public class InstrumentingMethodVisitor extends MethodVisitor {
	private Label currentLabel = null;
	private Map<Label, Label> surrogateLabels = new HashMap<>();

	@Override
	public void visitFrame(final int type, final int numLocal, final Object[] local, final int numStack,
			final Object[] stack) {
		for (int i = 0; i < numStack; i ++) {
			if (stack[i] instanceof Label && surrogateLabels.containsKey(stack[i])) {
				log.finer("applying surrogate label: " + stack[1]);
				stack[i] = surrogateLabels.get(stack[i]);
			}
		}

		super.visitFrame(type, numLocal, local, numStack, stack);

		if (jumpLabels.contains(currentLineNumber)) {
			instrument(currentLineNumber);
		}
	}

	@Override
	public void visitLabel(final Label label) {
		super.visitLabel(label);
		currentLabel = label;
	}

	@Override
	public void visitTypeInsn(final int opcode, final String type) {
		if (opcode == Opcodes.NEW) {
			final var surrogateLabel = new Label();
			super.visitLabel(surrogateLabel);
			surrogateLabels.put(currentLabel, surrogateLabel);
		}

		super.visitTypeInsn(opcode, type);
	}
```

This implementation does three things:

  + In `visitLabel` (which is called first) the "current" label is recorded.

  + The `visitTypeInsn`, which is (among others) invoked for the `NEW` opcode, has some special handling for it. *prior* to delegating the call to the super method (which causes the opcode to be written), it also creates a new label, and adds an entry to the `surrogateLabels` map, mapping the current label to our surrogate.

  + Last but not least `visitFrame` iterates the stack elements of the frame. For every label existing in the map, it uses the surrogate instead.

And yay, that's it. Our simple coverage analyzer finally seems to be working 🥳

Final source code is available from [stesie/undercovered GitHub repository](https://github.com/stesie/undercovered).



## Bookkeeping

So far the `track` method doesn't do much. It just logs the invocation. With the goal of creating a coverage report in mind, obviously we have to collect that data. Since this project is mostly about collecting the data, and not about rendering a nice report, ... I just want to dump the data to a JSON file. For the JSON Writing I just went on with the Jackson library.

In order to be able to also report uncovered lines, I've added another tiny `MethodVisitor`, that just "registers" the line with the tracking layer and also passes information to which method the line is related. The latter is important for "method coverage" aggregation.

After all nothing fancy:
```java
public class LineRegisteringMethodVisitor extends MethodVisitor {
	private final ClassTracker classTracker;
	private final String methodName;
	private final String descriptor;

	protected LineRegisteringMethodVisitor(final MethodVisitor methodVisitor,
			final ClassTracker classTracker, final String methodName, final String descriptor) {
		super(Opcodes.ASM9, methodVisitor);
		this.classTracker = classTracker;
		this.methodName = methodName;
		this.descriptor = descriptor;
	}

	@Override
	public void visitLineNumber(final int line, final Label start) {
		super.visitLineNumber(line, start);
		classTracker.trackLine(line, methodName, descriptor);
	}
}
```

The `Tracker` instance holds a static reference to the collector, simply tracking each and every invocation like so:

```java
public class Tracker {
	static TrackingCollector currentCollector;

	public static void track(final String callingClass, final int line) {
		log.finer("hit " + callingClass + ":" + line);
		currentCollector.trackClass(callingClass).line(line).hit();
	}

	public static TrackingCollector createCollector(final Set<String> includePatterns,
			final Set<String> excludePatterns) {
		currentCollector = new TrackingCollector(includePatterns, excludePatterns);
		return currentCollector;
	}
}
```

Last but not least we can register a shutdown hook from our `premain` method, that dumps the collected data to the JSON file, once program execution comes to an end.

```java
public class UndercoveredAgent {
	public static void premain(final String agentArgs, final Instrumentation inst) {
// ...
		Runtime.getRuntime().addShutdownHook(
				new Thread(() -> {
					inst.removeTransformer(transformer);

					if (args.destfile != null) {
						serializeCollectorToJson(collector, args.destfile);
					}
				})
		);
	}

	private static void serializeCollectorToJson(final TrackingCollector collector, final String destfile) {
		final var objectMapper = new ObjectMapper();

		try (final var writer = new java.io.FileWriter(destfile)) {
			objectMapper.writeValue(writer, collector);
		} catch (final Exception e) {
			log.severe("Unable to serialize collector to JSON:" + e);
		}
	}
}
```

... and that's it. We finally have an agent, that can collect coverage data and store that information to a json file.

Running the demo application with coverage collection one last time:

```console
$ java -javaagent:agent/target/agent-1.0-SNAPSHOT.jar=destfile=cover.json -cp demo/target/demo-1.0-SNAPSHOT.jar de.brokenpipe.dojo.undercovered.demo.Demo
Hello World
to the blarg
```

Resulting json report, after running the demo application:

```json
{
  "includePatterns": [],
  "excludePatterns": [],
  "classes": [
    {
      "className": "de/brokenpipe/dojo/undercovered/demo/Demo",
      "lines": [
        {
          "line": 3,
          "methodSignature": "<init>()V",
          "hitCount": 0
        },
        {
          "line": 6,
          "methodSignature": "main([Ljava/lang/String;)V",
          "hitCount": 1
        },
        {
          "line": 8,
          "methodSignature": "main([Ljava/lang/String;)V",
          "hitCount": 1
        },
        {
          "line": 9,
          "methodSignature": "main([Ljava/lang/String;)V",
          "hitCount": 1
        },
        {
          "line": 11,
          "methodSignature": "main([Ljava/lang/String;)V",
          "hitCount": 1
        },
        {
          "line": 14,
          "methodSignature": "bla(Ljava/lang/String;)V",
          "hitCount": 2
        },
        {
          "line": 15,
          "methodSignature": "bla(Ljava/lang/String;)V",
          "hitCount": 2
        }
      ]
    }
  ]
}
```



## What's left ?!

So far this implementation solely bothers to collect line coverage information. For branch coverage we would need to add some special handling around if statements and switch statements/expressions. Tracking the if branch itself should be straight forward. However we'd need to take care of missing else branches, so we also collect information how often an if branch wasn't entered. Yet we've already seen all the means necessary to do so in the last article. If the else branch is missing, we'd just need to add one more `goto` and create a stack frame entry of our own. Even the latter should be easy, given that there already must be a stack frame entry for the jump target, that skips the if branch ... so we could just duplicate that one.

Furthermore a "real" coverage tracker likely shouldn't pull Jackson into the classpath 😅

And JaCoCo moves itself into a dedicated random package name, so running code cannot make assumptions on it. And having the package randomized would also allow us to instrument ourselves.

Last but not least, [obviously we need an IntelliJ Plugin]({{< ref "/pages/Writing an IntelliJ Plugin" >}}).

... and very likely I'm missing out on some obvious points, and likely also this implementation is still buggy & incomplete 😈
