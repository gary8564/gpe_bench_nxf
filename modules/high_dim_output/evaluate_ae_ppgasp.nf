process evaluate_ae_ppgasp {
  conda "${workflow.launchDir}/envs/${params.useGPU ? 'evaluate_ae_ppgasp_cuda.yml' : 'evaluate_ae_ppgasp.yml'}"
  tag "AE-PPGaSP"
  publishDir "${params.outDir}/${params.caseStudy}", mode: 'copy'
  accelerator 1 

  input:
    path tensors

  output:
    path "results_ae_ppgasp", emit: ae_ppgasp

  script:
  """
  # macOS-specific environment variable to avoid OpenMP error
  [[ "\$(uname)" == "Darwin" ]] && export KMP_DUPLICATE_LIB_OK=TRUE
  
  python ${workflow.launchDir}/scripts/high_dim_output/evaluate_ae_ppgasp.py \
    --input-dir ${tensors} \
    --output-dir results_ae_ppgasp \
    --threshold ${params.threshold} \
    --latent-dim ${params.latent_dim} \
    --qoi ${params.qoi} \
    ${params.useGPU ? '--device cuda' : '--device cpu'}
  """
}


