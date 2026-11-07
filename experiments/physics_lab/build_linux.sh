#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p experiments/physics_lab/build
cc -O2 -std=c99 -fPIC -shared -Wall -Wextra \
  experiments/physics_lab/fpslab.c -o experiments/physics_lab/build/libfpslab.so -lm
echo "Built experiments/physics_lab/build/libfpslab.so (experimental, NOT shipped)"
