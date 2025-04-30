#!/usr/bin/env bash

set -exo pipefail

mkdir -p zigsmith-out

changed=$(git diff-tree --no-commit-id --name-only -r HEAD pkgs | cut -d "/" -f1-4 | sort -u)
for dir in $changed; do
  script="$dir/build.zig.zon"
  name=$(./scripts/get_name.sh < "$script")
  version=$(./scripts/get_version.sh < "$script")

  temp_path=$(mktemp --suffix=".tar.xz")
  ./scripts/build_one.sh "$dir" "$temp_path"
  hash=$(sha256sum "$temp_path" | cut -d " " -f1)
  mv "$temp_path" "./zigsmith-out/$hash.tar.xz"

  echo "$hash $name $version"
done
