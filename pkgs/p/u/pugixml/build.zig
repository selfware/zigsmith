const std = @import("std");

pub fn build(b: *std.Build) void {
    const upstream = b.dependency("upstream", .{}).path("src");

    const mod = b.createModule(.{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .pic = b.option(bool, "pic", "use position independent code (pic)"),
        .link_libcpp = true,
    });

    mod.addCSourceFiles(.{ .root = upstream, .files = pugixml_src });

    const lib = b.addLibrary(.{
        .name = "pugixml",
        .linkage = .static,
        .root_module = mod,
    });
    lib.installHeadersDirectory(
        upstream,
        "",
        .{ .include_extensions = &.{".hpp"} },
    );

    b.installArtifact(lib);
}

const pugixml_src = &[_][]const u8{"pugixml.cpp"};
