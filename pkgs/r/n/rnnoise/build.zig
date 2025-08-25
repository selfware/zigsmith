const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("upstream", .{});
    const data = b.dependency("data", .{});

    const linkage = b.option(
        std.builtin.LinkMode,
        "linkage",
        "library linkage",
    ) orelse .dynamic;

    const cpu = target.result.cpu;
    const rtcd = cpu.arch.isX86() and b.option(
        bool,
        "rtcd",
        "enable rtcd",
    ) orelse true;
    const little = b.option(
        bool,
        "little",
        "use the little model",
    ) orelse false;

    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .pic = b.option(bool, "pic", "use pic"),
        .link_libc = true,
    });

    const src = upstream.path("src");
    const data_path = data.path("src");
    mod.addCSourceFiles(.{ .root = src, .files = sources.base });
    mod.addCSourceFile(.{
        .file = data_path.path(b, if (little)
            "rnnoise_data_little.c"
        else
            "rnnoise_data.c"),
    });

    const include = upstream.path("include");
    mod.addIncludePath(include);
    mod.addIncludePath(src);
    mod.addIncludePath(data_path);

    mod.addCMacro("RNNOISE_BUILD", "1");
    mod.addCMacro("DISABLE_DEBUG_FLOAT", "1");

    if (rtcd) {
        const x86 = src.path(b, "x86");
        mod.addCSourceFiles(.{ .root = x86, .files = sources.rtcd.base });
        if (std.Target.Cpu.has(cpu, .x86, .sse4_1))
            mod.addCSourceFiles(.{
                .root = x86,
                .files = sources.rtcd.sse4_1,
            });
        if (std.Target.Cpu.has(cpu, .x86, .avx2))
            mod.addCSourceFiles(.{
                .root = x86,
                .files = sources.rtcd.avx2,
            });

        mod.addCMacro("RNN_ENABLE_X86_RTCD", "1");
        mod.addCMacro("CPU_INFO_BY_ASM", "1");
    }

    const lib = b.addLibrary(.{
        .name = "rnnoise",
        .linkage = linkage,
        .root_module = mod,
    });
    lib.installHeadersDirectory(include, "", .{});

    b.installArtifact(lib);
}

const sources = struct {
    const base = &[_][]const u8{
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

    const rtcd = struct {
        const base = &[_][]const u8{
            "x86_dnn_map.c",
            "x86cpu.c",
        };

        const sse4_1 = &[_][]const u8{"nnet_sse4_1.c"};

        const avx2 = &[_][]const u8{"nnet_avx2.c"};
    };
};
