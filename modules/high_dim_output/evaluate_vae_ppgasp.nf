process evaluate_vae_ppgasp {
  conda "${workflow.launchDir}/envs/${params.useGPU ? 'evaluate_vae_ppgasp_cuda.yml' : 'evaluate_vae_ppgasp.yml'}"
  tag "VAE-PPGaSP"
  publishDir "${params.outDir}/${params.caseStudy}", mode: 'copy'
  accelerator 1 

  input:
    path tensors

  output:
    path "results_vae_ppgasp", emit: vae_ppgasp

  script:
  """
  # macOS-specific environment variable to avoid OpenMP error
  [[ "\$(uname)" == "Darwin" ]] && export KMP_DUPLICATE_LIB_OK=TRUE
  
  python ${workflow.launchDir}/scripts/high_dim_output/evaluate_vae_ppgasp.py \
    --input-dir ${tensors} \
    --output-dir results_vae_ppgasp \
    --threshold ${params.threshold} \
    --latent-dim ${params.latent_dim} \
    --qoi ${params.qoi} \
    ${params.useGPU ? '--device cuda' : '--device cpu'}
  """
}


