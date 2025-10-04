process evaluate_pca_ppgasp {
  tag "PCA-PPGaSP"

  input:
    path tensors

  output:
    path "results_pca_ppgasp", emit: pca_ppgasp
    
  script:
  """
  python ${workflow.launchDir}/scripts/high_dim_output/evaluate_pca_ppgasp.py \
    --input-dir ${tensors} \
    --output-dir results_pca_ppgasp \
    --n-components ${params.n_components} \
    --threshold ${params.threshold}
  """
}


