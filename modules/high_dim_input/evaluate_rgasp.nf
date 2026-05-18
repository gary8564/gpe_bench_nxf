process evaluate_rgasp {
  conda (params.useLockFiles
    ? "${workflow.launchDir}/locks/${params.lockPlatform}/evaluate_rgasp.txt"
    : "${workflow.launchDir}/envs/evaluate_rgasp.yml")

  tag "RGaSP"
  publishDir "${params.outDir}/${params.caseStudy}", mode: 'copy'
  
  input:
    path tensors

  output:
    path "results_rgasp", emit: rgasp
    
  script:
  """
  # Execute R script for RGaSP evaluation
  echo "R version:"
  Rscript --version
  Rscript ${workflow.launchDir}/scripts/high_dim_input/evaluate_rgasp.R \\
    --input-dir ${tensors} \\
    --output-dir results_rgasp
  """
} 
