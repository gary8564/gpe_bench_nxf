process evaluate_ppgasp {
  conda "${workflow.launchDir}/envs/evaluate_ppgasp.yml"
  tag "PPGaSP"
  publishDir "${params.outDir}/${params.caseStudy}", mode: 'copy'

  input:
    path tensors

  output:
    path "results_ppgasp", emit: ppgasp
    
  script:
  """
  python ${workflow.launchDir}/scripts/high_dim_output/evaluate_ppgasp.py \
    --input-dir ${tensors} \
    --output-dir results_ppgasp \
    --threshold ${params.threshold} \
    --qoi ${params.qoi}
  """
}



