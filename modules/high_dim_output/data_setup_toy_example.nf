process data_setup_toy_example {
  tag "${caseStudy}"

  input:
    val caseStudy

  output:
    path "processed_data", emit: processed

  script:
  def dataset_config = params.datasets[caseStudy]
  """
  echo "[data_setup_toy_example] Generating high-dim-output toy example for ${caseStudy}"

  # Build arguments - only add parameters that are configured
  args="--output-dir processed_data"

  # Add n_samples if specified in config
  ${dataset_config?.parameters?.n_samples != null ? """
  args=\"\$args --n-samples ${dataset_config.parameters.n_samples}\"
  """ : ""}
  
  # Add seed if specified in config
  ${dataset_config?.parameters?.seed != null ? """
  args=\"\$args --seed ${dataset_config.parameters.seed}\"
  """ : ""}

  python ${workflow.launchDir}/scripts/high_dim_output/data_setup_toy_example.py \$args

  echo "[data_setup_toy_example] Successfully generated synthetic toy example for ${caseStudy}"
  """
}


