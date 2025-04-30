#!/usr/bin/env bash

set -exo pipefail

pkg_dir="$1"
out_file="$2"

tar -C "$pkg_dir" -cf - . | xz -9e > "$out_file"
