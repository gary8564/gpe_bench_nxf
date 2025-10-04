process evaluate_pca_bigp {
  tag "PCA-BiGP"
  accelerator 1 

  input:
    path tensors

  output:
    path "results_pca_bigp", emit: pca_bigp

  script:
  """
  # macOS-specific environment variable to avoid OpenMP error
  [[ "\$(uname)" == "Darwin" ]] && export KMP_DUPLICATE_LIB_OK=TRUE
  
  python ${workflow.launchDir}/scripts/high_dim_output/evaluate_pca_bigp.py \
    --input-dir ${tensors} \
    --output-dir results_pca_bigp \
    --threshold ${params.threshold} \
    ${params.useGPU ? '--device cuda' : '--device cpu'}
  """
}


