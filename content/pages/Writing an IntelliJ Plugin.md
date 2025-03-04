---
status: seedling
tags:
- Java
- IntelliJ
- Plugin
date: 2025-03-04
title: Writing an IntelliJ Plugin
categories:
lastMod: 2025-03-04
---
In a way, this is the last part of my journey creating a Java (Line) Coverage Analyzer.

This article concentrates on creating an IntelliJ plugin, that adapts it to show the results collected by the analyzer created in [Let's create a Coverage Analyzer, Part 4]({{< ref "/pages/Let's create a Coverage Analyzer, Part 4" >}}).

To get started, check out JetBrains' [Developing a Plugin](https://plugins.jetbrains.com/docs/intellij/developing-plugins.html) article. With recent IntelliJ versions you need to install the [Plugin DevKit](https://plugins.jetbrains.com/plugin/22851-plugin-devkit) first, then create a new Project and select the _IDE Plugin_ Generator.

The result is a Plugin scaffold, by default based on Kotlin. Since I don't (yet) know about Kotlin I went on adding Java files. In the end it's not much anyways. I have next to no experience with Gradle, therefore I also struggled a bit with that one, but found my way through.



## Providing a coverageRunner Extension

Effectively the only thing you have to do to provide a custom Java Coverage runner, is creating a class extending `JavaCoverageRunner` and declaring it in the `plugin.xml` file.

```java
public class UndercoveredRunner extends JavaCoverageRunner {
	@Override
	public @NotNull @NonNls String getPresentableName() {
		return "Undercover Runner";
	}

	@Override
	public @NotNull @NonNls String getId() {
		return "undercover";
	}

	@Override
	public @NotNull @NonNls String getDataFileExtension() {
		return "undercover.json";
	}

	@Override
	public boolean isBranchInfoAvailable(final boolean branchCoverage) {
		return false;
	}
}
```

and

```xml
<idea-plugin>
    <!-- Product and plugin compatibility requirements.
           Read more: https://plugins.jetbrains.com/docs/intellij/plugin-compatibility.html -->
  <depends>com.intellij.modules.platform</depends>
  <depends>com.intellij.java</depends>
  <depends>com.intellij.modules.coverage</depends>
  <depends>Coverage</depends>

  <!-- Extension points defined by the plugin.
           Read more: https://plugins.jetbrains.com/docs/intellij/plugin-extension-points.html -->
  <extensions defaultExtensionNs="com.intellij">
    <coverageRunner implementation="de.brokenpipe.dojo.undercovered.plugin.UndercoveredRunner"/>
  </extensions>
</idea-plugin>
```

... one thing, that really cost me a long time to figure out is the `<depends>Coverage</depends>` part. Since the other plugins have this package-style name, I was trying it with prefixes first, and also didn't try with a capital letter "C" first. In the end, close to desperation, I literaly tried the pluginId ... and it worked 🤦

To be honest I wasn't aware how much of the IntelliJ ecosystem actually is available as open source software. For example the [plugin.xml file of the Coverage Plugin](https://github.com/JetBrains/intellij-community/blob/master/plugins/coverage/resources/META-INF/plugin.xml) can be found on GitHub here (along with the implementation obviously). There's also [JaCoCoCoverageRunner.java](https://github.com/JetBrains/intellij-community/blob/master/plugins/coverage/src/com/intellij/coverage/JaCoCoCoverageRunner.java), which happens to be pretty similar to my implementation 😏

To get started, just run the `runIde` Gradle task. First time it takes a while, since it downloads a full IntelliJ installation as dependency, then builds a while and finally starts another IDE instance ... which runs with a Debugger attached to the "outer" IDE. So you can happily set breakpoints in the "outer" IDE, which obviously will block the "inner" one.

The above couple of lines are already enough, that the Coverage Runner shows up in the settings dialog 🥳

![Screenshot from IntelliJ coverage settings, showing the "Choose coverage runner" select with "Undercover Runner" selected](/assets/image_1741116607962_0.png)

In the end it boils down to reading the JSON file, the analyzer creates, and map it to the class structure that IntelliJ expects (`ProjectData` & `LineData` classes):

```java
	@Override
	public @Nullable ProjectData loadCoverageData(@NotNull final File sessionDataFile,
			@Nullable final CoverageSuite baseCoverageSuite) {
		final CoverageDataDTO coverageData = readCoverageFile(sessionDataFile);
		return processCoverageData(coverageData);
	}

	private @NotNull ProjectData processCoverageData(final CoverageDataDTO coverageData) {
		final ProjectData data = new ProjectData();
		coverageData.getClasses().forEach(clazz -> {
			final var maxLine = clazz.getLines().stream().mapToInt(LineCoverageDataDTO::getLine).max();

			if (maxLine.isEmpty()) {
				return;
			}

			final var cd = data.getOrCreateClassData(convertInternalClassName(clazz.getClassName()));
			final LineData[] lines = new LineData[maxLine.getAsInt() + 1];

			clazz.getLines().forEach(line -> {
				lines[line.getLine()] = new LineData(line.getLine(), line.getMethodSignature());
				lines[line.getLine()].setHits(line.getHitCount());
			});

			cd.setLines(lines);
		});
		return data;
	}
```



## Configuring the build

The `depends` declarations in the `plugin.xml` file have a runtime effect only (after all they seem to control the ClassLoader IntelliJ creates for the plugin). To build properly, you also need to declare the same plugins in `build.gradle.kts` file like so:

```kotlin
intellij {
    version.set("2024.1.7")
    type.set("IC") // Target IDE Platform

    plugins.set(listOf("java", "Coverage"))
}
```

... in that file I also declared further dependencies (Jackson for JSON parsing, and also I relied on Lombok)

```kotlin
dependencies {
    compileOnly("org.projectlombok:lombok:1.18.36")
    annotationProcessor("org.projectlombok:lombok:1.18.36")
    implementation("com.fasterxml.jackson.core:jackson-databind:2.15.2")
}
```

I packaged the agent.jar in `src/main/resources/undercovered-agent.jar`, hence need to copy it to the build assets. Turns out the Gradle way to do that is

```kotlin
tasks.register<Copy>("copyAgentJar") {
    from("src/main/resources/undercovered-agent.jar")
    into(layout.buildDirectory.dir("resources/main"))
}

tasks.named("instrumentedJar") {
    dependsOn("copyAgentJar")
}

tasks.named("jar") {
    dependsOn("copyAgentJar")
}
```



And that's already all that is to it.

{{< logseq/orgNOTE >}}The full source code of the plugin is available from [stesie/undercovered-plugin GitHub repository](https://github.com/stesie/undercovered-plugin). Feel free to try it out & play around with it.

But please refrain from using it in production 😅
{{< / logseq/orgNOTE >}}
