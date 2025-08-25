const std = @import("std");

pub fn build(b: *std.Build) void {
    const upstream = b.dependency("upstream", .{});

    const linkage = b.option(
        std.builtin.LinkMode,
        "linkage",
        "library linkage",
    ) orelse .static;

    const wchar = b.option(bool, "wchar", "use wchat_t mode") orelse false;
    const compact = b.option(bool, "compact", "use compact mode") orelse false;
    const xpath = b.option(bool, "xpath", "enable xpath") orelse true;
    const stl = b.option(bool, "stl", "enable c++ stl") orelse true;
    const exceptions = b.option(
        bool,
        "exceptions",
        "enable exceptions",
    ) orelse true;

    const mod = b.createModule(.{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .pic = b.option(bool, "pic", "use pic"),
        .link_libcpp = true,
    });

    const src = upstream.path("src");
    mod.addCSourceFiles(.{ .root = src, .files = sources.base });

    mod.addIncludePath(src);

    if (wchar) mod.addCMacro("PUGIXML_WCHAR_MODE", "1");
    if (compact) mod.addCMacro("PUGIXML_COMPACT", "1");
    if (!xpath) mod.addCMacro("PUGIXML_NO_XPATH", "1");
    if (!stl) mod.addCMacro("PUGIXML_NO_STL", "1");
    if (!exceptions) mod.addCMacro("PUGIXML_NO_EXCEPTIONS", "1");

    const lib = b.addLibrary(.{
        .name = "pugixml",
        .linkage = linkage,
        .root_module = mod,
    });
    lib.installHeadersDirectory(
        src,
        "",
        .{ .include_extensions = &.{".hpp"} },
    );

    b.installArtifact(lib);
}

const sources = struct {
    const base = &[_][]const u8{"pugixml.cpp"};
};
