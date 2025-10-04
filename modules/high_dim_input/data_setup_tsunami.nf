process data_setup_tsunami {
  tag "${caseStudy}"
  
  input:
    tuple val(caseStudy), path(raw_data)
  
  output:
    path "processed_data", emit: processed

  script:
  """
  echo "[data_setup_tsunami] Processing tsunami data for ${caseStudy}"
  
  # Process downloaded tsunami data
  args="--input-dir ${raw_data} --output-dir processed_data"
  python ${workflow.launchDir}/scripts/high_dim_input/data_setup_tsunami.py \$args
  
  echo "[data_setup_tsunami] Successfully processed tsunami data for ${caseStudy}"
  """
}
