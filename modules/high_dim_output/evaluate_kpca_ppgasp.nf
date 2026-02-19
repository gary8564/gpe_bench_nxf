process evaluate_kpca_ppgasp {
  conda "${workflow.launchDir}/envs/evaluate_kpca_ppgasp.yml"
  tag "kPCA-PPGaSP"
  publishDir "${params.outDir}/${params.caseStudy}", mode: 'copy'

  input:
    path tensors

  output:
    path "results_kpca_ppgasp", emit: kpca_ppgasp
    
  script:
  """
  python ${workflow.launchDir}/scripts/high_dim_output/evaluate_kpca_ppgasp.py \
    --input-dir ${tensors} \
    --output-dir results_kpca_ppgasp \
    --n-components ${params.n_components} \
    --qoi ${params.qoi} \
    --threshold ${params.threshold}
  """
}


