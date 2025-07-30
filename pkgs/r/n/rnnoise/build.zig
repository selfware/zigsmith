const std = @import("std");

pub fn build(b: *std.Build) void {
    const upstream = b.dependency("upstream", .{}).path("");
    const data = b.dependency("data", .{}).path("src");

    const target = b.standardTargetOptions(.{});

    const little = b.option(
        bool,
        "little",
        "use little rnnoise data",
    ) orelse false;

    const mod = b.createModule(.{
        .target = target,
        .optimize = b.standardOptimizeOption(.{}),
        .pic = b.option(bool, "pic", "use position independent code (pic)"),
        .link_libc = true,
    });
    mod.addCMacro("RNNOISE_BUILD", "1");
    mod.addCMacro("DISABLE_DEBUG_FLOAT", "1");

    const include = upstream.path(b, "include");
    const rnnoise = upstream.path(b, "src");
    mod.addIncludePath(include);
    mod.addIncludePath(rnnoise);
    mod.addIncludePath(data);

    mod.addCSourceFiles(.{
        .root = rnnoise,
        .files = rnnoise_src.base,
    });
    mod.addCSourceFiles(.{
        .root = data,
        .files = if (little)
            rnnoise_src.data_little
        else
            rnnoise_src.data,
    });

    const lib = b.addLibrary(.{
        .name = "rnnoise",
        .linkage = .dynamic,
        .root_module = mod,
    });
    lib.installHeadersDirectory(include, "", .{});

    b.installArtifact(lib);
}

const rnnoise_src = struct {
    pub const base = &[_][]const u8{
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

    pub const data = &[_][]const u8{"rnnoise_data.c"};

    pub const data_little = &[_][]const u8{"rnnoise_data_little.c"};
};
