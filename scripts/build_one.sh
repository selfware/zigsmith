#!/usr/bin/env bash

set -exo pipefail

pkg_dir="$1"
out_file="$2"

# TODO: stop transforming, follow ziglang/zig#23152
tar \
  --owner=root --group=root \
  --transform 's|^\./||' \
  -C "$pkg_dir" -c . \
  | xz -9e > "$out_file"
