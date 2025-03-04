---
status: budding
tags:
- Java
- Java Agents
- Byte Code
date: 2025-03-01T11:00:00Z
title: Let's create a Coverage Analyzer, Part 3
categories:
lastMod: 2025-03-01
---
This is part three of my journey creating a Java (Line) Coverage Analyzer.

This time around we'll look into improving the [very naive implementation created in part two]({{< ref "/pages/Let's create a Coverage Analyzer, Part 2" >}}). That one ended in a `VerifyError` and the message
> Expecting a stackmap frame at branch target 41

So what is this branch target, and the stackmap frame that it's suddenly missing? To have an easier time inspecting the Byte Code, let's first create a little CLI version of our instrumentation code. It shall just receive two file/path names, an input class file and a output location. Given the design of our _Instrumenter_ class that's very easy to do:

```java
public class Coverista {
	public static void main(final String[] argv) {
		if (argv.length != 2) {
			System.err.println("expected two command arguments, path to input file + path to output file");
			System.exit(1);
		}

		final var result = new Instrumenter().instrumentClass(argv[0]);

		try (final var outputStream = new FileOutputStream(argv[1])) {
			outputStream.write(result);
		} catch (final IOException ex) {
			throw new RuntimeException("unable to write to file: " + argv[1], ex);
		}
	}
}
```

Next we can just run that tool:

```console
$ java -cp coverista/target/classes:$HOME/.m2/repository/org/ow2/asm/asm/9.6/asm-9.6.jar de.brokenpipe.dojo.undercovered.coverista.Coverista demo/target/classes/de/brokenpipe/dojo/undercovered/demo/Demo2.class Demo2.instrumented.class
```

With the instrumented byte code now stored to _Demo2.instrumented.class_, we can now call _javap_ and check what was generated: `javap -v Demo2.instrumented.class`. That should output (among much other stuff):

```
  public static void main(java.lang.String[]);
    Code:
        17: iconst_0
        18: istore_2
        19: iload_2
        20: iconst_3
        21: if_icmpge     41
[...]
        32: invokestatic  #17                 // Method de/brokenpipe/dojo/undercovered/coverista/Tracker.track:()V
        35: iinc          2, 1
        38: goto          19
        41: invokestatic  #17                 // Method de/brokenpipe/dojo/undercovered/coverista/Tracker.track:()V
        44: invokedynamic #52,  0             // InvokeDynamic #0:get:()Ljava/util/function/Supplier;
        49: astore_2
[...]
      StackMapTable: number_of_entries = 2
        frame_type = 253 /* append */
          offset_delta = 19
          locals = [ class java/lang/String, int ]
        frame_type = 250 /* chop */
          offset_delta = 24
```

At byte code locations 17 & 18 we see the initialization of our for-loop. The compiler obviously assigned variable slot 2 to our `i` variable, then first pushes the constant int 0 to the stack, before saving it to that slot. At locations 19, 20 and 21 we find the condition part of the for-loop. It first loads variable slot 2, then also pushes the upper bound value (3) and finally uses the `if_icmpge` instruction to conditionally jump to location 41, if the loop's condition no longer holds. Last but not least in location 35 it's incrementing the variable by one, prior to the unconditional branch (goto instruction) to location 19 ... where it would re-evaluate the loop's condition.

{{< logseq/orgIMPORTANT >}}### Stack Map Tables

[See the spec for more details](https://docs.oracle.com/javase/specs/jvms/se23/html/jvms-4.html#jvms-4.7.4). But in short it's mandatory, that for each and every jump destination (be it conditional or unconditional branches, be it catch blocks) there must be an entry in the `StackMapTable`, that the Byte Code Verifier can use to verify proper condition of the stack.

The `offset_delta` property of the entries is defined interestingly: In order to make sure, that the entries are properly ordered, and there are no duplicate entries for the same location, they defined `offset_delta` to be relative. The value of the first frame is absolute after all. The second frame applies to the location of the first frame plus given `offset_delta` **plus one**.
{{< / logseq/orgIMPORTANT >}}

So in our case,

  + the first entry targets offset 19

  + the second entry targets offset 19 + 24 + 1 = 44

However at location 44 there is the `invokedynamik` opcode, and it's clearly not the branch target of the `if_icmpge`, ... which goes to 41. Let's briefly compare this to the not instrumented Byte Code.

```console
$ javap -v demo/target/classes/de/brokenpipe/dojo/undercovered/demo/Demo2.class
  public static void main(java.lang.String[]);
[...]
         8: iconst_0
         9: istore_2
        10: iload_2
        11: iconst_3
        12: if_icmpge     26
[...
        20: iinc          2, 1
        23: goto          10
        26: invokedynamic #17,  0             // InvokeDynamic #0:get:()Ljava/util/function/Supplier;
        31: astore_2
[...
      StackMapTable: number_of_entries = 2
        frame_type = 253 /* append */
          offset_delta = 10
          locals = [ class java/lang/String, int ]
        frame_type = 250 /* chop */
          offset_delta = 15
```

Here the stack map table targets

  + first entry offset = 10

  + second entry offset = 10 + 15 + 1 = 26

... which perfectly matches the target locations of both branch opcodes. So to put it differently: the way we currently instrument the code using ASM breaks the stack map table 😿

For the byte code location in question (i.e. the `invokedynamic` opcode at location 26) ASM triggers the visitor three times (in order)

  + visitLineNumber

  + visitFrame

  + visitInvokeDynamicInsn

... genereally, the `visitLineNumber` is invoked on every line number label. The `visitFrame` is only called if there is a stack map frame associated with that location (at location 26 that's the case). And afterward one of the various instruction visitor methods is invoked (but there are many).

If `visitFrame` is invoked (and delegated to the writer), it writes a stack map table entry for the current offset. And since we currently (unconditionally) write our tracker invocation from the `visitLineNumber` method, the offset will increment prior to the `visitFrame`. Which is why we observe `visitFrame` writing the wrong offset.

The problem is, that when `visitLineNumber` is called, we do not yet know whether `visitFrame` will be called, and there's no way for us to find out. But we mustn't write the new instruction in `visitLineNumber` if a frame must exist for that location. So we have two options:

  + either we process the file in two passes: first time we "learn" which line numbers have a frame, next time around we know whether we must instrument from `visitLineNumber` or from `visitFrame`

  + alternatively we couldn't instrument from neither `visitLineNumber` nor `visitFrame`, but from each and every of the other visitor methods (but then don't need a second pass)

If this wouldn't be a learning project the decision would be simple: why a second pass, if we can do without it? However since this is a learning project and I strive for a clear implementation I go with option 1. Let's do two passes, and conditionally instrument from either `visitLineNumber` or `visitFrame`.

So let's create two `MethodVisitor` implementations. The first one just walking the class and telling a simple collector class, which line numbers have a stack map table entry:

```java
public class LabelCollectingMethodVisitor extends MethodVisitor {

	private final JumpLabelCollector jumpLabelCollector;
	private Integer lastLineNumber = null;
//...
	@Override
	public void visitLineNumber(final int line, final Label start) {
		super.visitLineNumber(line, start);
		lastLineNumber = Integer.valueOf(line);
	}

	@Override
	public void visitFrame(final int type, final int numLocal, final Object[] local, final int numStack, final Object[] stack) {
		super.visitFrame(type, numLocal, local, numStack, stack);
		jumpLabelCollector.accept(lastLineNumber);
	}
}
```

... in `visitLineNumber` we just keep the number. And in `visitFrame` we potentially pass it to the collector class.

The second `MethodVisitor` could then look like this:

```java
public class InstrumentingMethodVisitor extends MethodVisitor {

	private final Set<Integer> jumpLabels;
	private Integer currentLineNumber = null;

	@Override
	public void visitLineNumber(final int line, final Label start) {
		currentLineNumber = Integer.valueOf(line);
		super.visitLineNumber(line, start);

		if (!jumpLabels.contains(currentLineNumber)) {
			instrument(currentLineNumber);
		}
	}

	@Override
	public void visitFrame(final int type, final int numLocal, final Object[] local, final int numStack,
			final Object[] stack) {
		super.visitFrame(type, numLocal, local, numStack, stack);

		if (jumpLabels.contains(currentLineNumber)) {
			instrument(currentLineNumber);
		}
	}
}
```



{{< logseq/orgNOTE >}}If you'd like to follow along, [the undercovered GitHub repository has all the source code](https://github.com/stesie/undercovered).
{{< / logseq/orgNOTE >}}



## Optimizing the Tracker

My first naive implementation of `Tracker` just relied on `Thread.currentThread().getStackTrace()` calls to extract the name of the calling class as well as the current line number. Obviously that works, but is very inefficient. Especially given that we now have the `currentLineNumber` variable anyways ... and the name of the class is known as well.

Therefore let's change the signature of `Tracker#track` to:

```java
public class Tracker {
	public static void track(final String callingClass, final int line) {
		log.finer("hit " + callingClass + ":" + line);
	}
}
```

... obviously we have to adapt our instrumentation code accordingly. So far we set the descriptor to `()V`, which means no arguments and returning void. The updated descriptor is `(Ljava/lang/String;I)V`. First argument is an object (`L`) of `java.lang.String` type, next argument is of `int` (`I`) type. Return type is still void (`V`).

And prior to our `invokestatic` opcode we now have to push two frames onto the stack. First the class name (a string constant), using the `ldc` opcode. For the line number we have multiple options. For line numbers in the byte range (<= 127) we can use the `bipush` opcode. For line numbers in the short range (<= 32767) we can use the `sipush` opcode. Above that we need to resort back to constants (`ldc` again). But let's hope that this never happens...

So our `instrument` method now looks like this:

```java
public class InstrumentingMethodVisitor extends MethodVisitor {

	private final String className;

	private void instrument(final Integer line) {
		log.finer("instrument line: " + line);
		super.visitLdcInsn(className);
		push(line);
		super.visitMethodInsn(Opcodes.INVOKESTATIC, "de/brokenpipe/dojo/undercovered/coverista/tracking/Tracker",
				"track", "(Ljava/lang/String;I)V", false);
	}

	private void push(final Integer value) {
		if (value.intValue() <= Byte.MAX_VALUE) {
			super.visitIntInsn(Opcodes.BIPUSH, value.intValue());
		} else if (value.intValue() <= Short.MAX_VALUE) {
			super.visitIntInsn(Opcodes.SIPUSH, value.intValue());
		} else {
			super.visitLdcInsn(value);
		}
	}
}
```



### Again: VerifyError

Our beloved `VerifyError` is back 😡

```
Error: Unable to initialize main class de.brokenpipe.dojo.undercovered.demo.Demo
Caused by: java.lang.VerifyError: Operand stack overflow
Exception Details:
  Location:
    de/brokenpipe/dojo/undercovered/demo/Demo.<init>()V @2: bipush
  Reason:
    Exceeded max stack size.
  Current Frame:
    bci: @2
    flags: { flagThisUninit }
    locals: { uninitializedThis }
    stack: { 'java/lang/String' }
  Bytecode:
    0000000: 1208 1003 b800 0e2a b700 10b1          
```

... this time with a different message. And the reason is pretty clear: _Exceeded max stack size._

Checking back on the `javap -v` output:

```
  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: (0x0009) ACC_PUBLIC, ACC_STATIC
    Code:
      stack=1, locals=2, args_size=1
```

... it says that the maximum stack size is 1. Obviously that already is in contrast to the two values we push to the stack. To fix this, we actually have two options

  + we can ask ASM to calculate the maximum stack size and update it accordingly (to do so, we would just have to instantiate the class writer with `COMPUTE_MAX` flag like this: `new ClassWriter(ClassWriter.COMPUTE_MAXS)`)

  + we can modify the number on our own, and (in this simple case) just add 2

For real projects the former option would definitely be nicer. Especially since the second option easily leads to some waste. Our `track` calls likely don't happen with the stack at its maximum size. But let's neglect the couple of bytes potentially wasted, and override the `visitMaxs` method as well:

```java
	@Override
	public void visitMaxs(final int maxStack, final int maxLocals) {
		super.visitMaxs(maxStack + 2, maxLocals);
	}
```

... with that fixed, do we finally have the code necessary to track and that's not immediately crashing after some first simple examples?



[Let's create a Coverage Analyzer, Part 4]({{< ref "/pages/Let's create a Coverage Analyzer, Part 4" >}}) follows up on this implementation.
