process preprocessing_high_dim_input {
  conda (params.useLockFiles
    ? "${workflow.launchDir}/locks/${params.lockPlatform}/preprocessing.txt"
    : "${workflow.launchDir}/envs/preprocessing.yml")
  tag "preprocessing_high_dim_input"
  input:
    path processed_data

  output:
    path "data_tensors", emit: tensors


 
  script:
  """
  # macOS-specific environment variable to avoid OpenMP error
  [[ "\$(uname)" == "Darwin" ]] && export KMP_DUPLICATE_LIB_OK=TRUE

  python ${workflow.launchDir}/scripts/high_dim_input/preprocessing.py \
    --input-dir ${processed_data} \
    --output-dir data_tensors
  """
}


