# 01 – Hello FountainAI

FountainAI is a theatre-themed Swift framework for crafting AI‑powered apps.
In this first lesson you will scaffold a tiny "Hello FountainAI" application
from the template repository. By the end you'll know how to verify your Swift
toolchain, generate the starter project, and compile and launch it locally.

## Prerequisites

To follow this tutorial you'll need:

- **Swift 6.1+** – verify it is available:
  ```bash
  swift --version
  ```
- **Git 2.40+** – check with:
  ```bash
  git --version
  ```
- **OpenAI API key** (optional but enables AI features):
  ```bash
  export OPENAI_API_KEY="sk-..."
  ```
- Make sure the setup script can run:
  ```bash
  chmod +x setup.sh
  ```

Follow these steps to spin up a minimal FountainAI app.

## 1. Check your environment
Verify Swift is installed:

```bash
swift --version
```

## 2. Scaffold the app
Run the provided setup script, which pulls in the FountainAI app-creation template from the [the-fountainai](https://github.com/Fountain-Coach/the-fountainai) repo:

```bash
./setup.sh
```

## 3. Build and run
Build the project and launch it locally:

```bash
swift build
swift run
```
