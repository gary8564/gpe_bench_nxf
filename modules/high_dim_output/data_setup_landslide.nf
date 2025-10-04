process data_setup_landslide {
  tag "${caseStudy}"

  input:
    tuple val(caseStudy), path(raw_data)

  output:
    path "processed_data", emit: processed

  script:
  """
  echo "[data_setup_landslide] Processing high-dim-output data for ${caseStudy}"

  # Build args
  args="--input-dir ${raw_data} --output-dir processed_data"

  # Quantity of interest: default to hmax if not provided
  qoi="${params.qoi != null ? params.qoi : 'hmax'}"
  args="\$args --qoi ${qoi}"

  python ${workflow.launchDir}/scripts/high_dim_output/data_setup_landslide.py \$args
  echo "[data_setup_landslide] Successfully processed ${caseStudy} (qoi=${qoi})"
  """
}


