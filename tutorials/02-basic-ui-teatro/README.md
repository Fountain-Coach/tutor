# 02 – Basic UI with Teatro

This guide shows how to modify the scaffolded user interface using FountainAI's Teatro domain-specific language (DSL).

## 1. Scaffold the project
Generate a GUI app template:

```bash
Scripts/new-gui-app.sh BasicTeatro
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
Scripts/build-local.sh
scripts/start-local.sh BasicTeatro
```

## Script references
- [new-gui-app.sh](https://github.com/Fountain-Coach/the-fountainai/blob/main/Scripts/new-gui-app.sh)
- [build-local.sh](https://github.com/Fountain-Coach/the-fountainai/blob/main/Scripts/build-local.sh)
- [start-local.sh](https://github.com/Fountain-Coach/the-fountainai/blob/main/scripts/start-local.sh)
