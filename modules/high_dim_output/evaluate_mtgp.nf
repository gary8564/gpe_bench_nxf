process evaluate_mtgp {
  tag "MTGP"
  accelerator 1 

  input:
    path tensors

  output:
    path "results_mtgp", emit: mtgp

  script:
  """
  # macOS-specific environment variable to avoid OpenMP error
  [[ "\$(uname)" == "Darwin" ]] && export KMP_DUPLICATE_LIB_OK=TRUE
  
  python ${workflow.launchDir}/scripts/high_dim_output/evaluate_mtgp.py \
    --input-dir ${tensors} \
    --output-dir results_mtgp \
    --threshold ${params.threshold} \
    ${params.useGPU ? '--device cuda' : '--device cpu'}
  """
}


