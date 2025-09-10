# FountainAI Tutorial Series

This repository accompanies the [FountainAI Comprehensive Tutorial Series (Beginner to Expert)](./FountainAI%20Comprehensive%20Tutorial%20Series%20(Beginner%20to%20Expert).pdf). Each tutorial includes a `setup.sh` script that pulls the [FountainAI template](https://github.com/Fountain-Coach/the-fountainai) and produces a runnable SwiftUI app. The guides follow a template-first approach so you can focus on customizing the core FountainAI stack.

## Tutorial Workflow

1. Clone this repository.
2. Choose a tutorial and change into its directory.
3. Run `./setup.sh` to fetch the latest template from the-fountainai.
4. Build and launch the app with `swift build` and `swift run`.

## What You CAN Do

- Run `tutorials/<name>/setup.sh` to scaffold a tutorial project.
- Compile the generated app with `swift build`.
- Launch the app from the command line using `swift run`.

## Limitations

- GUI tests and other macOS-only features require running on macOS.

## Prerequisites

- macOS 14+ with Swift 6.1+
- Basic familiarity with Swift and SwiftUI
- Optional: OpenAI API key for AI features

## Tutorials

- [01 – Hello FountainAI](tutorials/01-hello-fountainai/README.md)
- [02 – Basic UI with Teatro](tutorials/02-basic-ui-teatro/README.md)
- [03 – Data Persistence with FountainStore](tutorials/03-data-persistence-fountainstore/README.md)
- [04 – Multimedia with MIDI2](tutorials/04-multimedia-midi2/README.md)
- [05 – AI Integration with OpenAPI](tutorials/05-ai-integration-openapi/README.md)
- [06 – Screenplay Editor Capstone](tutorials/06-screenplay-editor-capstone/README.md)

