#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { fetch_from_zenodo } from './modules/fetch_from_zenodo.nf'
include { fetch_from_figshare } from './modules/fetch_from_figshare.nf'
include { fetch_from_github } from './modules/fetch_from_github.nf'

// High-dim INPUT modules
include { data_setup_100d_func } from './modules/high_dim_input/data_setup_100d_func.nf'
include { data_setup_tsunami } from './modules/high_dim_input/data_setup_tsunami.nf'
include { preprocessing_high_dim_input as preprocessing_input } from './modules/high_dim_input/preprocessing.nf'
include { evaluate_exactgp } from './modules/high_dim_input/evaluate_exactgp.nf'
include { evaluate_dkl     } from './modules/high_dim_input/evaluate_dkl.nf'
include { evaluate_rgasp   } from './modules/high_dim_input/evaluate_rgasp.nf'
include { evaluate_pca_rgasp } from './modules/high_dim_input/evaluate_pca_rgasp.nf'

// High-dim OUTPUT modules
include { data_setup_landslide } from './modules/high_dim_output/data_setup_landslide.nf'
include { data_setup_env_spill_func } from './modules/high_dim_output/data_setup_env_spill_func.nf'
include { preprocessing_high_dim_output as preprocessing_output } from './modules/high_dim_output/preprocessing.nf'
include { evaluate_ppgasp } from './modules/high_dim_output/evaluate_ppgasp.nf'
include { evaluate_bigp } from './modules/high_dim_output/evaluate_bigp.nf'
include { evaluate_mtgp } from './modules/high_dim_output/evaluate_mtgp.nf'
include { evaluate_pca_bigp } from './modules/high_dim_output/evaluate_pca_bigp.nf'
include { evaluate_pca_ppgasp } from './modules/high_dim_output/evaluate_pca_ppgasp.nf'
include { evaluate_kpca_ppgasp } from './modules/high_dim_output/evaluate_kpca_ppgasp.nf'
include { evaluate_ae_ppgasp } from './modules/high_dim_output/evaluate_ae_ppgasp.nf'
include { evaluate_vae_ppgasp } from './modules/high_dim_output/evaluate_vae_ppgasp.nf'

include { benchmark_metrics } from './modules/benchmark_metrics.nf'

workflow {
    println "▶ Starting pipeline with caseStudy=${params.caseStudy}, problem_type=${params.problem_type}"
    // 0. Determine dataset type and problem type. Based on these, select workflow.
    def dataset_config = params.datasets[params.caseStudy]
    def dataset_source = dataset_config.source
    def data_ch

    if (params.problem_type == 'high_dim_input') {
        if (params.caseStudy == 'synthetic_100d_function') {
            // 1. Data setup: Generate synthetic data directly
            data_ch = data_setup_100d_func(params.caseStudy)

            // 2. Preprocessing: Standardize, split, save to HDF5
            def processed_ch = preprocessing_input(data_ch)

            // 3. Train and inference
            def exactgp_ch   = evaluate_exactgp(processed_ch)
            def dkl_ch       = evaluate_dkl(processed_ch)
            def rgasp_ch     = evaluate_rgasp(processed_ch)
            def pca_rgasp_ch = evaluate_pca_rgasp(processed_ch)

            // 4. Gather metrics and benchmark
            def metrics_list_ch = exactgp_ch.exactgp
                                    .mix(dkl_ch.dkl)
                                    .mix(rgasp_ch.rgasp)
                                    .mix(pca_rgasp_ch.pca_rgasp)
                                    .map { path -> path.toString() }
                                    .collect()
            benchmark_metrics(metrics_list_ch)
        } else if (params.caseStudy == 'tsunami_tokushima') {
            // 1. Data setup: Fetch from Zenodo then process
            def raw_ch = fetch_from_zenodo(params.caseStudy)
            data_ch = data_setup_tsunami(raw_ch)

            // 2. Preprocessing: Standardize, split, save to HDF5
            def processed_ch = preprocessing_input(data_ch)

            // 3. Train and inference: For real-world tsunami data,  RGaSP on ultra-high-dimensional inputs would face numerical instability issues
            // Evaluate ExactGP, DKL and PCA-RGaSP
            def exactgp_ch   = evaluate_exactgp(processed_ch)
            def dkl_ch       = evaluate_dkl(processed_ch)
            def pca_rgasp_ch = evaluate_pca_rgasp(processed_ch)

            // 4. Gather metrics and benchmark
            def metrics_list_ch = exactgp_ch.exactgp
                                        .mix(dkl_ch.dkl)
                                        .mix(pca_rgasp_ch.pca_rgasp)
                                        .map { path -> path.toString() }
                                        .collect()
            benchmark_metrics(metrics_list_ch)
        } else {
            error "NotImplementedError: caseStudy ${params.caseStudy} is not supported for high_dim_input."
        }
    } else if (params.problem_type == 'high_dim_output') {
        if (params.caseStudy == 'environment_spill_function') {
            // 1. Data setup: Generate toy example directly
            data_ch = data_setup_env_spill_func(params.caseStudy)
        } else if (params.caseStudy in ['acheron', 'synthetic_landslide']) {
            // 1. Data setup: Fetch from figshare and github then process
            def raw_figshare = fetch_from_figshare(params.caseStudy)
            def raw_github   = fetch_from_github(params.caseStudy)
            // Ensure both downloads complete: join on caseStudy key, then merge both paths
            def raw_ch = raw_figshare.raw
                              .join(raw_github.raw, by: 0)
                              .map { cs, pathA, pathB -> tuple(cs, pathA, pathB) }
            // Prepare npy arrays from raster stacks and CSV
            data_ch = data_setup_landslide(raw_ch)
        } else {
            error "NotImplementedError: caseStudy ${params.caseStudy} is not supported for high_dim_output."
        }

        // 2. Preprocessing: zero-truncate + standardize + HDF5
        def processed_ch = preprocessing_output(data_ch)

        // 3. Train and inference (subset of models for high-dim output)
        def ppgasp_ch      = evaluate_ppgasp(processed_ch)
        def pca_ppgasp_ch  = evaluate_pca_ppgasp(processed_ch)
        def kpca_ppgasp_ch = evaluate_kpca_ppgasp(processed_ch)
        def ae_ppgasp_ch   = evaluate_ae_ppgasp(processed_ch)
        def vae_ppgasp_ch  = evaluate_vae_ppgasp(processed_ch)
        def bigp_ch        = evaluate_bigp(processed_ch)
        def pca_bigp_ch    = evaluate_pca_bigp(processed_ch)
        def mtgp_ch        = evaluate_mtgp(processed_ch)

        // 4. Gather metrics and benchmark
        def metrics_list_ch = ppgasp_ch.ppgasp
                                .mix(pca_ppgasp_ch.pca_ppgasp)
                                .mix(kpca_ppgasp_ch.kpca_ppgasp)
                                .mix(ae_ppgasp_ch.ae_ppgasp)
                                .mix(vae_ppgasp_ch.vae_ppgasp)
                                .mix(bigp_ch.bigp)
                                .mix(pca_bigp_ch.pca_bigp)
                                .mix(mtgp_ch.mtgp)
                                .map { path -> path.toString() }
                                .collect()
        benchmark_metrics(metrics_list_ch)
    } else {
        error "NotImplementedError: problem_type ${params.problem_type} is not supported."
    }
}