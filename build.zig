const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const httpz = b.dependency("httpz", .{
        .target = target,
        .optimize = optimize,
    });
    const sqlite = b.dependency("sqlite", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "www",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("www/main.zig"),
            .imports = &.{
                .{ .name = "httpz", .module = httpz.module("httpz") },
                .{ .name = "sqlite", .module = sqlite.module("sqlite") },
            },
        }),
    });

    b.installArtifact(exe);
}
