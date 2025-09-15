#!/usr/bin/env bash
# Usage: ./setup.sh [BundleID]
../../Scripts/setup-tutorial.sh HelloCsound "$@"

# Ensure the Csound file is present in the generated package
mkdir -p Sources/HelloCsound
cp hello.csd Sources/HelloCsound/hello.csd
