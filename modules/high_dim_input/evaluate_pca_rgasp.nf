process evaluate_pca_rgasp {
  conda "${workflow.launchDir}/envs/evaluate_pca_rgasp.yml"
  tag "PCA-RGaSP"
  publishDir "${params.outDir}/${params.caseStudy}", mode: 'copy'

  input:
    path tensors

  output:
    path "results_pca_rgasp", emit: pca_rgasp

  script:
  """
  # macOS-specific environment variable to avoid OpenMP error
  [[ "\$(uname)" == "Darwin" ]] && export KMP_DUPLICATE_LIB_OK=TRUE

  python ${workflow.launchDir}/scripts/high_dim_input/evaluate_pca_rgasp.py \
    --input-dir ${tensors} \
    --output-dir results_pca_rgasp
  """
}


