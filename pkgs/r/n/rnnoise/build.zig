const std = @import("std");

pub fn build(b: *std.Build) void {
    const upstream = b.dependency("upstream", .{}).path("");
    const data = b.dependency("data", .{}).path("src");

    const little = b.option(
        bool,
        "little",
        "use little rnnoise data",
    ) orelse false;

    const mod = b.createModule(.{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .pic = b.option(bool, "pic", "use position independent code (pic)"),
        .link_libc = true,
    });
    mod.addCMacro("RNNOISE_BUILD", "1");
    mod.addCMacro("DISABLE_DEBUG_FLOAT", "1");

    const include = upstream.path(b, "include");
    const src = upstream.path(b, "src");
    mod.addIncludePath(include);
    mod.addIncludePath(src);
    mod.addIncludePath(data);

    mod.addCSourceFiles(.{
        .root = src,
        .files = source,
    });
    mod.addCSourceFile(.{
        .file = data.path(b, if (little)
            "rnnoise_data_little.c"
        else
            "rnnoise_data.c"),
    });

    const lib = b.addLibrary(.{
        .name = "rnnoise",
        .linkage = .static,
        .root_module = mod,
    });
    lib.installHeadersDirectory(include, "", .{});

    b.installArtifact(lib);
}

const source = &[_][]const u8{
    "denoise.c",
    "rnn.c",
    "pitch.c",
    "kiss_fft.c",
    "celt_lpc.c",
    "nnet.c",
    "nnet_default.c",
    "parse_lpcnet_weights.c",
    "rnnoise_tables.c",
};
