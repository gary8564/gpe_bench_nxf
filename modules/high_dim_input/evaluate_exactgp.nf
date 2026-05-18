process evaluate_exactgp {
  conda (params.useLockFiles
    ? "${workflow.launchDir}/locks/${params.lockPlatform}/${params.useGPU ? 'evaluate_exactgp_cuda' : 'evaluate_exactgp'}.txt"
    : "${workflow.launchDir}/envs/${params.useGPU ? 'evaluate_exactgp_cuda' : 'evaluate_exactgp'}.yml")

  tag "ExactGP"
  publishDir "${params.outDir}/${params.caseStudy}", mode: 'copy'
  accelerator 1 

  input:
    path tensors

  output:
    path "results_exactgp", emit: exactgp

  script:
  """
  # macOS-specific environment variable to avoid OpenMP error
  [[ "\$(uname)" == "Darwin" ]] && export KMP_DUPLICATE_LIB_OK=TRUE

  export PYTHONPATH=${workflow.launchDir}/src:\${PYTHONPATH:-}  
  python ${workflow.launchDir}/scripts/high_dim_input/evaluate_exactgp.py \
    --input-dir  ${tensors} \
    --output-dir results_exactgp \
    ${params.useGPU ? '--device cuda' : '--device cpu'}
  """
}
