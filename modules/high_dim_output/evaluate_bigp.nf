process evaluate_bigp {
  tag "BiGP"
  accelerator 1 

  input:
    path tensors

  output:
    path "results_bigp", emit: bigp

  script:
  """
  # macOS-specific environment variable to avoid OpenMP error
  [[ "\$(uname)" == "Darwin" ]] && export KMP_DUPLICATE_LIB_OK=TRUE
  
  python ${workflow.launchDir}/scripts/high_dim_output/evaluate_bigp.py \
    --input-dir ${tensors} \
    --output-dir results_bigp \
    --threshold ${params.threshold} \
    ${params.useGPU ? '--device cuda' : '--device cpu'}
  """
}


