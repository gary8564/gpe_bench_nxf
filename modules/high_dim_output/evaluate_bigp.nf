process evaluate_bigp {
  conda "${workflow.launchDir}/envs/${params.useGPU ? 'evaluate_bigp_cuda.yml' : 'evaluate_bigp.yml'}"
  tag "BiGP"  
  publishDir "${params.outDir}/${params.caseStudy}", mode: 'copy'
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
    --qoi ${params.qoi} \
    ${params.useGPU ? '--device cuda' : '--device cpu'}
  """
}


