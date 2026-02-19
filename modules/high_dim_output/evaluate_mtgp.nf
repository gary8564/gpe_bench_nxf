process evaluate_mtgp {
  conda "${workflow.launchDir}/envs/${params.useGPU ? 'evaluate_mtgp_cuda.yml' : 'evaluate_mtgp.yml'}"
  tag "MTGP"
  publishDir "${params.outDir}/${params.caseStudy}", mode: 'copy'
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
    --qoi ${params.qoi} \
    ${params.useGPU ? '--device cuda' : '--device cpu'}
  """
}


