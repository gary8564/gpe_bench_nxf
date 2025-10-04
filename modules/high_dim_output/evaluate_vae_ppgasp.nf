process evaluate_vae_ppgasp {
  tag "VAE-PPGaSP"
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
    ${params.useGPU ? '--device cuda' : '--device cpu'}
  """
}


