const std = @import("std");

// TODO: add Ne10 and asm
pub fn build(b: *std.Build) void {
    const upstream = b.dependency("upstream", .{}).path("");
    const data = b.dependency("data", .{}).path("");

    const target = b.standardTargetOptions(.{});
    const cpu = target.result.cpu;

    const deep_plc = b.option(
        bool,
        "deep_plc",
        "enable deep packet loss concealment (plc)",
    ) orelse false;
    const dred = b.option(
        bool,
        "dred",
        "enable deep redundancy (dred)",
    ) orelse false;
    const osce = b.option(
        bool,
        "osce",
        "enable opus speech coding enhancement (osce)",
    ) orelse false;

    const fixed_point = b.option(
        bool,
        "fixed_point",
        "compile without floating point",
    ) orelse false;
    const float_api = if (fixed_point)
        b.option(
            bool,
            "float_api",
            "include the floating point api",
        ) orelse true
    else
        true;
    const float_approx = b.option(
        bool,
        "float_approx",
        "enable fast approximations for floating point",
    ) orelse false;
    const hardening = b.option(
        bool,
        "hardening",
        "enable runtime checks for safety",
    ) orelse true;
    const custom_modes = b.option(
        bool,
        "custom_modes",
        "enable non-opus modes",
    ) orelse false;
    const dplc = deep_plc or dred;

    const features = cpu.features;
    const sse =
        cpu.arch.isX86() and std.Target.x86.featureSetHas(features, .sse);
    const sse2 = sse and std.Target.x86.featureSetHas(features, .sse2);
    const sse4_1 = sse2 and std.Target.x86.featureSetHas(features, .sse4_1);
    const avx2 = sse4_1 and std.Target.x86.featureSetHas(features, .avx2);
    const neon =
        cpu.arch.isArm() and std.Target.arm.featureSetHas(features, .neon);
    const aarch64_neon = neon and cpu.arch.isAARCH64();
    const dotprod =
        aarch64_neon and std.Target.aarch64.featureSetHas(features, .dotprod);

    const config = b.addConfigHeader(.{}, .{
        .HAVE_LRINTF = true,
        .HAVE_LRINT = true,
        .HAVE_STDINT_H = true,
        .VAR_ARRAYS = true,
        .DISABLE_DEBUG_FLOAT = true,
        .FIXED_POINT = ton(fixed_point),
        .DISABLE_FLOAT_API = ton(!float_api),
        .FLOAT_APPROX = ton(float_approx),
        .ENABLE_HARDENING = ton(hardening),
        .CUSTOM_MODES = ton(custom_modes),
        .ENABLE_DEEP_PLC = ton(dplc),
        .ENABLE_DRED = ton(dred),
        .ENABLE_OSCE = ton(osce),

        .OPUS_X86_MAY_HAVE_SSE = ton(sse),
        .OPUS_X86_MAY_HAVE_SSE2 = ton(sse2),
        .OPUS_X86_MAY_HAVE_SSE4_1 = ton(sse4_1),
        .OPUS_X86_MAY_HAVE_AVX2 = ton(avx2),
        .OPUS_ARM_MAY_HAVE_NEON_INTR = ton(neon),
        .OPUS_X86_MAY_HAVE_AARCH64_NEON_INTR = ton(aarch64_neon),
        .OPUS_ARM_MAY_HAVE_DOTPROD = ton(dotprod),
        .OPUS_X86_PRESUME_SSE = ton(sse),
        .OPUS_X86_PRESUME_SSE2 = ton(sse2),
        .OPUS_X86_PRESUME_SSE4_1 = ton(sse4_1),
        .OPUS_X86_PRESUME_AVX2 = ton(avx2),
        .OPUS_ARM_PRESUME_NEON_INTR = ton(neon),
        .OPUS_X86_PRESUME_AARCH64_NEON_INTR = ton(aarch64_neon),
        .OPUS_ARM_PRESUME_DOTPROD = ton(dotprod),
    });

    const mod = b.createModule(.{
        .target = target,
        .optimize = b.standardOptimizeOption(.{}),
        .pic = b.option(bool, "pic", "use position independent code (pic)"),
        .link_libc = true,
    });
    mod.addCMacro("OPUS_BUILD", "1");
    mod.addCMacro("HAVE_CONFIG_H", "1");
    mod.addConfigHeader(config);

    const include = upstream.path(b, "include");
    const opus = upstream.path(b, "src");
    const silk = upstream.path(b, "silk");
    const celt = upstream.path(b, "celt");
    const lpcnet = upstream.path(b, "dnn");
    mod.addIncludePath(upstream);
    mod.addIncludePath(data);
    mod.addIncludePath(include);
    mod.addIncludePath(silk);
    mod.addIncludePath(celt);
    mod.addIncludePath(lpcnet);
    mod.addCSourceFiles(.{ .root = opus, .files = opus_src.base });
    mod.addCSourceFiles(.{ .root = silk, .files = silk_src.base });
    mod.addCSourceFiles(.{ .root = celt, .files = celt_src.base });
    if (float_api)
        mod.addCSourceFiles(.{ .root = opus, .files = opus_src.float });
    if (fixed_point) {
        mod.addIncludePath(silk.path(b, "fixed"));
        mod.addCSourceFiles(.{ .root = silk, .files = silk_src.fixed.base });
        if (sse4_1)
            mod.addCSourceFiles(.{
                .root = silk,
                .files = silk_src.fixed.sse4_1,
            });
        if (neon)
            mod.addCSourceFiles(.{
                .root = silk,
                .files = silk_src.fixed.neon,
            });
    } else {
        mod.addIncludePath(silk.path(b, "float"));
        mod.addCSourceFiles(.{ .root = silk, .files = silk_src.float.base });
        if (avx2)
            mod.addCSourceFiles(.{
                .root = silk,
                .files = silk_src.float.avx2,
            });
    }
    if (sse) mod.addCSourceFiles(.{ .root = celt, .files = celt_src.sse });
    if (sse2) {
        mod.addCSourceFiles(.{ .root = celt, .files = celt_src.sse2 });
        mod.addCSourceFiles(.{ .root = lpcnet, .files = lpcnet_src.sse2 });
    }
    if (sse4_1) {
        mod.addCSourceFiles(.{ .root = silk, .files = silk_src.sse4_1 });
        mod.addCSourceFiles(.{ .root = celt, .files = celt_src.sse4_1 });
        mod.addCSourceFiles(.{ .root = lpcnet, .files = lpcnet_src.sse4_1 });
    }
    if (avx2) {
        mod.addCSourceFiles(.{ .root = silk, .files = silk_src.avx2 });
        mod.addCSourceFiles(.{ .root = celt, .files = celt_src.avx2 });
        mod.addCSourceFiles(.{ .root = lpcnet, .files = lpcnet_src.avx2 });
    }
    if (neon) {
        mod.addCSourceFiles(.{ .root = silk, .files = silk_src.neon });
        mod.addCSourceFiles(.{ .root = celt, .files = celt_src.neon });
        mod.addCSourceFiles(.{ .root = lpcnet, .files = lpcnet_src.neon });
    }
    if (dotprod)
        mod.addCSourceFiles(.{ .root = lpcnet, .files = lpcnet_src.dotprod });
    if (dplc) {
        mod.addCSourceFiles(.{
            .root = lpcnet,
            .files = lpcnet_src.deep_plc.base,
        });
        mod.addCSourceFiles(.{
            .root = data,
            .files = lpcnet_src.deep_plc.data,
        });
    }
    if (dred) {
        mod.addCSourceFiles(.{
            .root = lpcnet,
            .files = lpcnet_src.dred.base,
        });
        mod.addCSourceFiles(.{
            .root = data,
            .files = lpcnet_src.dred.data,
        });
    }
    if (osce) {
        mod.addCSourceFiles(.{
            .root = lpcnet,
            .files = lpcnet_src.osce.base,
        });
        mod.addCSourceFiles(.{
            .root = data,
            .files = lpcnet_src.osce.data,
        });
    }

    const lib = b.addLibrary(.{
        .name = "opus",
        .linkage = .static,
        .root_module = mod,
    });
    lib.installHeadersDirectory(include, "opus", .{});

    b.installArtifact(lib);
}

fn ton(value: bool) ?bool {
    return if (value) true else null;
}

const opus_src = struct {
    pub const base = &[_][]const u8{
        "opus.c",
        "opus_decoder.c",
        "opus_encoder.c",
        "extensions.c",
        "opus_multistream.c",
        "opus_multistream_encoder.c",
        "opus_multistream_decoder.c",
        "repacketizer.c",
        "opus_projection_encoder.c",
        "opus_projection_decoder.c",
        "mapping_matrix.c",
    };

    pub const float = &[_][]const u8{
        "analysis.c",
        "mlp.c",
        "mlp_data.c",
    };
};

const silk_src = struct {
    pub const base = &[_][]const u8{
        "CNG.c",
        "code_signs.c",
        "init_decoder.c",
        "decode_core.c",
        "decode_frame.c",
        "decode_parameters.c",
        "decode_indices.c",
        "decode_pulses.c",
        "decoder_set_fs.c",
        "dec_API.c",
        "enc_API.c",
        "encode_indices.c",
        "encode_pulses.c",
        "gain_quant.c",
        "interpolate.c",
        "LP_variable_cutoff.c",
        "NLSF_decode.c",
        "NSQ.c",
        "NSQ_del_dec.c",
        "PLC.c",
        "shell_coder.c",
        "tables_gain.c",
        "tables_LTP.c",
        "tables_NLSF_CB_NB_MB.c",
        "tables_NLSF_CB_WB.c",
        "tables_other.c",
        "tables_pitch_lag.c",
        "tables_pulses_per_block.c",
        "VAD.c",
        "control_audio_bandwidth.c",
        "quant_LTP_gains.c",
        "VQ_WMat_EC.c",
        "HP_variable_cutoff.c",
        "NLSF_encode.c",
        "NLSF_VQ.c",
        "NLSF_unpack.c",
        "NLSF_del_dec_quant.c",
        "process_NLSFs.c",
        "stereo_LR_to_MS.c",
        "stereo_MS_to_LR.c",
        "check_control_input.c",
        "control_SNR.c",
        "init_encoder.c",
        "control_codec.c",
        "A2NLSF.c",
        "ana_filt_bank_1.c",
        "biquad_alt.c",
        "bwexpander_32.c",
        "bwexpander.c",
        "debug.c",
        "decode_pitch.c",
        "inner_prod_aligned.c",
        "lin2log.c",
        "log2lin.c",
        "LPC_analysis_filter.c",
        "LPC_inv_pred_gain.c",
        "table_LSF_cos.c",
        "NLSF2A.c",
        "NLSF_stabilize.c",
        "NLSF_VQ_weights_laroia.c",
        "pitch_est_tables.c",
        "resampler.c",
        "resampler_down2_3.c",
        "resampler_down2.c",
        "resampler_private_AR2.c",
        "resampler_private_down_FIR.c",
        "resampler_private_IIR_FIR.c",
        "resampler_private_up2_HQ.c",
        "resampler_rom.c",
        "sigm_Q15.c",
        "sort.c",
        "sum_sqr_shift.c",
        "stereo_decode_pred.c",
        "stereo_encode_pred.c",
        "stereo_find_predictor.c",
        "stereo_quant_pred.c",
        "LPC_fit.c",
    };

    pub const sse4_1 = &[_][]const u8{
        "x86/NSQ_sse4_1.c",
        "x86/NSQ_del_dec_sse4_1.c",
        "x86/VAD_sse4_1.c",
        "x86/VQ_WMat_EC_sse4_1.c",
    };

    pub const avx2 = &[_][]const u8{"x86/NSQ_del_dec_avx2.c"};

    pub const neon = &[_][]const u8{
        "arm/biquad_alt_neon_intr.c",
        "arm/LPC_inv_pred_gain_neon_intr.c",
        "arm/NSQ_del_dec_neon_intr.c",
        "arm/NSQ_neon.c",
    };

    pub const fixed = struct {
        pub const base = &[_][]const u8{
            "fixed/LTP_analysis_filter_FIX.c",
            "fixed/LTP_scale_ctrl_FIX.c",
            "fixed/corrMatrix_FIX.c",
            "fixed/encode_frame_FIX.c",
            "fixed/find_LPC_FIX.c",
            "fixed/find_LTP_FIX.c",
            "fixed/find_pitch_lags_FIX.c",
            "fixed/find_pred_coefs_FIX.c",
            "fixed/noise_shape_analysis_FIX.c",
            "fixed/process_gains_FIX.c",
            "fixed/regularize_correlations_FIX.c",
            "fixed/residual_energy16_FIX.c",
            "fixed/residual_energy_FIX.c",
            "fixed/warped_autocorrelation_FIX.c",
            "fixed/apply_sine_window_FIX.c",
            "fixed/autocorr_FIX.c",
            "fixed/burg_modified_FIX.c",
            "fixed/k2a_FIX.c",
            "fixed/k2a_Q16_FIX.c",
            "fixed/pitch_analysis_core_FIX.c",
            "fixed/vector_ops_FIX.c",
            "fixed/schur64_FIX.c",
            "fixed/schur_FIX.c",
        };

        pub const sse4_1 = &[_][]const u8{
            "fixed/x86/vector_ops_FIX_sse4_1.c",
            "fixed/x86/burg_modified_FIX_sse4_1.c",
        };

        pub const neon = &[_][]const u8{"fixed/arm/warped_autocorrelation_FIX_neon_intr.c"};
    };

    pub const float = struct {
        pub const base = &[_][]const u8{
            "float/apply_sine_window_FLP.c",
            "float/corrMatrix_FLP.c",
            "float/encode_frame_FLP.c",
            "float/find_LPC_FLP.c",
            "float/find_LTP_FLP.c",
            "float/find_pitch_lags_FLP.c",
            "float/find_pred_coefs_FLP.c",
            "float/LPC_analysis_filter_FLP.c",
            "float/LTP_analysis_filter_FLP.c",
            "float/LTP_scale_ctrl_FLP.c",
            "float/noise_shape_analysis_FLP.c",
            "float/process_gains_FLP.c",
            "float/regularize_correlations_FLP.c",
            "float/residual_energy_FLP.c",
            "float/warped_autocorrelation_FLP.c",
            "float/wrappers_FLP.c",
            "float/autocorrelation_FLP.c",
            "float/burg_modified_FLP.c",
            "float/bwexpander_FLP.c",
            "float/energy_FLP.c",
            "float/inner_product_FLP.c",
            "float/k2a_FLP.c",
            "float/LPC_inv_pred_gain_FLP.c",
            "float/pitch_analysis_core_FLP.c",
            "float/scale_copy_vector_FLP.c",
            "float/scale_vector_FLP.c",
            "float/schur_FLP.c",
            "float/sort_FLP.c",
        };

        pub const avx2 = &[_][]const u8{"float/x86/inner_product_FLP_avx2.c"};
    };
};

const celt_src = struct {
    pub const base = &[_][]const u8{
        "bands.c",
        "celt.c",
        "celt_encoder.c",
        "celt_decoder.c",
        "cwrs.c",
        "entcode.c",
        "entdec.c",
        "entenc.c",
        "kiss_fft.c",
        "laplace.c",
        "mathops.c",
        "mdct.c",
        "modes.c",
        "pitch.c",
        "celt_lpc.c",
        "quant_bands.c",
        "rate.c",
        "vq.c",
    };

    pub const sse = &[_][]const u8{"x86/pitch_sse.c"};

    pub const sse2 = &[_][]const u8{
        "x86/pitch_sse2.c",
        "x86/vq_sse2.c",
    };

    pub const sse4_1 = &[_][]const u8{
        "x86/celt_lpc_sse4_1.c",
        "x86/pitch_sse4_1.c",
    };

    pub const avx2 = &[_][]const u8{"x86/pitch_avx.c"};

    pub const neon = &[_][]const u8{
        "arm/celt_neon_intr.c",
        "arm/pitch_neon_intr.c",
    };
};

const lpcnet_src = struct {
    pub const deep_plc = struct {
        pub const base = &[_][]const u8{
            "burg.c",
            "freq.c",
            "fargan.c",
            "lpcnet_enc.c",
            "lpcnet_plc.c",
            "lpcnet_tables.c",
            "nnet.c",
            "nnet_default.c",
            "parse_lpcnet_weights.c",
            "pitchdnn.c",
        };

        pub const data = &[_][]const u8{
            "fargan_data.c",
            "plc_data.c",
            "pitchdnn_data.c",
        };
    };

    pub const dred = struct {
        pub const base = &[_][]const u8{
            "dred_rdovae_enc.c",
            "dred_rdovae_dec.c",
            "dred_encoder.c",
            "dred_coding.c",
            "dred_decoder.c",
        };

        pub const data = &[_][]const u8{
            "dred_rdovae_enc_data.c",
            "dred_rdovae_dec_data.c",
            "dred_rdovae_stats_data.c",
        };
    };

    pub const osce = struct {
        pub const base = &[_][]const u8{
            "osce.c",
            "osce_features.c",
            "nndsp.c",
        };

        pub const data = &[_][]const u8{
            "lace_data.c",
            "nolace_data.c",
        };
    };

    pub const sse2 = &[_][]const u8{"x86/nnet_sse2.c"};

    pub const sse4_1 = &[_][]const u8{"x86/nnet_sse4_1.c"};

    pub const avx2 = &[_][]const u8{"x86/nnet_avx2.c"};

    pub const neon = &[_][]const u8{"arm/nnet_neon.c"};

    pub const dotprod = &[_][]const u8{"arm/nnet_dotprod.c"};
};
