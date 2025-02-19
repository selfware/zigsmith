const std = @import("std");

pub fn create_wrapper(b: *std.Build, library: *std.Build.Step.Compile, root_source_file: std.Build.LazyPath) !void {
    const module = b.addModule(
        std.fmt.allocPrint(b.allocator, "zig-{s}", .{library.name}),
        .{ .root_source_file = root_source_file },
    );
    module.linkLibrary(library);
}
