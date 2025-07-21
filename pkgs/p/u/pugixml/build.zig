const std = @import("std");

pub fn build(b: *std.Build) void {
    const upstream = b.dependency("pugixml", .{}).path("./src");

    const lib = b.addStaticLibrary(.{
        .name = "pugixml",
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });
    lib.addCSourceFile(.{ .file = upstream.path(b, "pugixml.cpp") });
    lib.installHeadersDirectory(
        upstream,
        ".",
        .{ .include_extensions = &.{".hpp"} },
    );
    lib.linkLibCpp();

    b.installArtifact(lib);
}
