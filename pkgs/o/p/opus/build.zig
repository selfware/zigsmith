const std = @import("std");

pub fn build(b: *std.Build) void {
    const opus = b.dependency("opus", .{});

    const lib = b.addStaticLibrary(.{
        .name = "opus",
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .link_libc = true,
    });
    lib.addCSourceFiles(.{
        .root = opus.path("src"),
        .files = opus_sources ++ opus_sources_float,
    });
    lib.addCSourceFiles(.{
        .root = opus.path("silk"),
        .files = silk_sources ++ silk_sources_float,
    });
    lib.addCSourceFiles(.{
        .root = opus.path("celt"),
        .files = celt_sources,
    });
    lib.installHeadersDirectory(
        opus.path("include"),
        "opus",
        .{ .include_extensions = &.{".h"} },
    );
    lib.root_module.addCMacro("OPUS_BUILD", "1");
    lib.root_module.addCMacro("VAR_ARRAYS", "1");
    lib.root_module.addCMacro("HAVE_LRINTF", "1");
    lib.addIncludePath(opus.path("include"));
    lib.addIncludePath(opus.path("silk"));
    lib.addIncludePath(opus.path("silk/float"));
    lib.addIncludePath(opus.path("celt"));

    b.installArtifact(lib);
}

const opus_sources = &[_][]const u8{
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

const opus_sources_float = &[_][]const u8{
    "analysis.c",
    "mlp.c",
    "mlp_data.c",
};

const silk_sources = &[_][]const u8{
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

const silk_sources_float = &[_][]const u8{
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

const celt_sources = &[_][]const u8{
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
