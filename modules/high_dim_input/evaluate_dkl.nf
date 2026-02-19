process evaluate_dkl {
  conda "${workflow.launchDir}/envs/${params.useGPU ? 'evaluate_dkl_cuda.yml' : 'evaluate_dkl.yml'}"
  tag "DKL"
  publishDir "${params.outDir}/${params.caseStudy}", mode: 'copy'
  accelerator 1 

  input:
    path tensors

  output:
    path "results_dkl", emit: dkl

  script:
  """
  # macOS-specific environment variable to avoid OpenMP error
  [[ "\$(uname)" == "Darwin" ]] && export KMP_DUPLICATE_LIB_OK=TRUE
  
  python ${workflow.launchDir}/scripts/high_dim_input/evaluate_dkl.py \
    --input-dir ${tensors} \
    --output-dir results_dkl \
    ${params.useGPU ? '--device cuda' : '--device cpu'}
  """
}
