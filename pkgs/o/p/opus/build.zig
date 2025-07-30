const std = @import("std");

pub fn build(b: *std.Build) void {
    const upstream = b.dependency("upstream", .{}).path("");

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

    const config = b.addConfigHeader(.{}, .{
        .HAVE_LRINTF = true,
        .HAVE_LRINT = true,
        .HAVE_STDINT_H = true,
        .VAR_ARRAYS = true,
        .FIXED_POINT = if (fixed_point) true else null,
        .DISABLE_FLOAT_API = if (float_api) null else true,
        .FLOAT_APPROX = if (float_approx) true else null,
        .ENABLE_HARDENING = if (hardening) true else null,
        .CUSTOM_MODES = if (custom_modes) true else null,
    });

    const mod = b.createModule(.{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .pic = b.option(bool, "pic", "use position independent code (pic)"),
        .link_libc = true,
    });
    mod.addCMacro("OPUS_BUILD", "1");
    mod.addCMacro("HAVE_CONFIG_H", "1");
    mod.addConfigHeader(config);

    const include = upstream.path(b, "include");
    const silk = upstream.path(b, "silk");
    const silk_fixed = silk.path(b, "fixed");
    const silk_float = silk.path(b, "float");
    const celt = upstream.path(b, "celt");
    mod.addIncludePath(include);
    mod.addIncludePath(celt);
    mod.addIncludePath(silk);
    mod.addIncludePath(silk_fixed);
    mod.addIncludePath(silk_float);

    const src = upstream.path(b, "src");
    mod.addCSourceFiles(.{
        .root = src,
        .files = source,
    });
    mod.addCSourceFiles(.{
        .root = silk,
        .files = source_silk,
    });
    mod.addCSourceFiles(.{
        .root = celt,
        .files = source_celt,
    });
    if (float_api) mod.addCSourceFiles(.{
        .root = src,
        .files = source_float,
    });
    if (fixed_point) mod.addCSourceFiles(.{
        .root = silk_fixed,
        .files = source_silk_fixed,
    }) else mod.addCSourceFiles(.{
        .root = silk_float,
        .files = source_silk_float,
    });

    const lib = b.addLibrary(.{
        .name = "opus",
        .linkage = .static,
        .root_module = mod,
    });
    lib.installHeadersDirectory(include, "opus", .{});

    b.installArtifact(lib);
}

const source = &[_][]const u8{
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

const source_float = &[_][]const u8{
    "analysis.c",
    "mlp.c",
    "mlp_data.c",
};

const source_silk = &[_][]const u8{
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

const source_silk_fixed = &[_][]const u8{
    "LTP_analysis_filter_FIX.c",
    "LTP_scale_ctrl_FIX.c",
    "corrMatrix_FIX.c",
    "encode_frame_FIX.c",
    "find_LPC_FIX.c",
    "find_LTP_FIX.c",
    "find_pitch_lags_FIX.c",
    "find_pred_coefs_FIX.c",
    "noise_shape_analysis_FIX.c",
    "process_gains_FIX.c",
    "regularize_correlations_FIX.c",
    "residual_energy16_FIX.c",
    "residual_energy_FIX.c",
    "warped_autocorrelation_FIX.c",
    "apply_sine_window_FIX.c",
    "autocorr_FIX.c",
    "burg_modified_FIX.c",
    "k2a_FIX.c",
    "k2a_Q16_FIX.c",
    "pitch_analysis_core_FIX.c",
    "vector_ops_FIX.c",
    "schur64_FIX.c",
    "schur_FIX.c",
};

const source_silk_float = &[_][]const u8{
    "apply_sine_window_FLP.c",
    "corrMatrix_FLP.c",
    "encode_frame_FLP.c",
    "find_LPC_FLP.c",
    "find_LTP_FLP.c",
    "find_pitch_lags_FLP.c",
    "find_pred_coefs_FLP.c",
    "LPC_analysis_filter_FLP.c",
    "LTP_analysis_filter_FLP.c",
    "LTP_scale_ctrl_FLP.c",
    "noise_shape_analysis_FLP.c",
    "process_gains_FLP.c",
    "regularize_correlations_FLP.c",
    "residual_energy_FLP.c",
    "warped_autocorrelation_FLP.c",
    "wrappers_FLP.c",
    "autocorrelation_FLP.c",
    "burg_modified_FLP.c",
    "bwexpander_FLP.c",
    "energy_FLP.c",
    "inner_product_FLP.c",
    "k2a_FLP.c",
    "LPC_inv_pred_gain_FLP.c",
    "pitch_analysis_core_FLP.c",
    "scale_copy_vector_FLP.c",
    "scale_vector_FLP.c",
    "schur_FLP.c",
    "sort_FLP.c",
};

const source_celt = &[_][]const u8{
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
