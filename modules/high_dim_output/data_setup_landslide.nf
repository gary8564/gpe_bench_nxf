process data_setup_landslide {
  conda "${workflow.launchDir}/envs/data_setup_landslide.yml"
  tag "${caseStudy}"

  input:
    tuple val(caseStudy), path(raw_figshare, stageAs: 'figshare'), path(raw_github, stageAs: 'github')

  output:
    path "processed_data", emit: processed

  script:
  """
  echo "[data_setup_landslide] Processing high-dim-output data for ${caseStudy}"

  # Build args
  args="--figshare-dir figshare --github-dir github --output-dir processed_data"

  # Quantity of interest: default to hmax if not provided
  qoi="${params.qoi ?: 'hmax'}"
  args="\$args --qoi \$qoi"

  python ${workflow.launchDir}/scripts/high_dim_output/data_setup_landslide.py \$args
  echo "[data_setup_landslide] Successfully processed ${caseStudy} (qoi=\$qoi)"
  """
}


