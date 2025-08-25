#!/bin/sh

set -ex

temp_path=$(mktemp --suffix=".zig")

cat >"$temp_path" <<EOF
const std = @import("std");

const value = $(cat);

pub fn main() !void {
    var buf: [1024]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&buf);
    const writer = &stdout.interface;

    try writer.print("{s}\n", .{value.version});
    try writer.flush();
}
EOF

zig run "$temp_path" 2>/dev/null
rm "$temp_path"
