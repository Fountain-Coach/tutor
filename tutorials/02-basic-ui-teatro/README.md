# 02 – Basic UI with Teatro

This guide shows how to modify the scaffolded user interface using FountainAI's Teatro domain-specific language (DSL).

## 1. Scaffold the project
Run the setup script, which pulls in the FountainAI app-creation template from the [the-fountainai](https://github.com/Fountain-Coach/the-fountainai) repo:

```bash
./setup.sh
```

The script creates a starter project with a `MainScene.teatro` file that declares the UI.

## 2. Define the interface
Open `MainScene.teatro` and add components. Teatro uses a declarative syntax:

```teatro
Stage {
  Scene {
    Text("Welcome to Teatro")
    Button("Tap Me") { emit("tapped") }
  }
}
```

## 3. Respond to user interaction
Handlers listen for events emitted from the interface:

```teatro
on("tapped") {
  print("Button was tapped")
}
```

When you press the button, the handler runs and prints to the console.

## 4. Build and run
Compile the project and launch the generated SwiftUI app:

```bash
swift build
swift run
```
