#!/bin/sh

set -ex

temp_path=$(mktemp --suffix=".zig")

cat >"$temp_path" <<EOF
const std = @import("std");

const value = $(cat);

pub fn main() void {
    std.io.getStdOut().writer().print(
        "{s}\n",
        .{@tagName(value.name)},
    ) catch {};
}
EOF

zig run "$temp_path" 2>/dev/null
rm "$temp_path"
