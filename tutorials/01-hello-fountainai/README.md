# 01 – Hello FountainAI

Follow these steps to spin up a minimal FountainAI app.

## 1. Check your environment
Run the monorepo's self-check script to ensure Swift builds and tests succeed:

```bash
Scripts/selfcheck.sh
```

## 2. Scaffold the app
Generate a starter SwiftUI target:

```bash
Scripts/new-gui-app.sh HelloFountainAI
```

## 3. Build and run
Build the project and launch it locally:

```bash
Scripts/build-local.sh
scripts/start-local.sh HelloFountainAI
```

## Script references
- [selfcheck.sh](https://github.com/Fountain-Coach/the-fountainai/blob/main/Scripts/selfcheck.sh)
- [new-gui-app.sh](https://github.com/Fountain-Coach/the-fountainai/blob/main/Scripts/new-gui-app.sh)
- [build-local.sh](https://github.com/Fountain-Coach/the-fountainai/blob/main/Scripts/build-local.sh)
- [start-local.sh](https://github.com/Fountain-Coach/the-fountainai/blob/main/scripts/start-local.sh)
