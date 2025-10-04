process fetch_from_github {
  tag "${caseStudy}"

  input:
    val caseStudy

  output:
    tuple val(caseStudy), path("raw_data/${caseStudy}"), emit: raw

  script:
  def dataset_config = params.datasets[caseStudy]

  """
  # Download emulator inputs/background from GitHub into raw_data/${caseStudy}
  mkdir -p raw_data/${caseStudy}
  cd raw_data/${caseStudy}

  echo "[fetch_from_github] Downloading GitHub files for ${caseStudy}"

  ${dataset_config?.github?.files ? dataset_config.github.files.collect { f ->
    // Build raw GitHub URL from a blob URL
    def m = (f.url =~ /https:\\/\\/github\\.com\\/([^\\/]+)\\/([^\\/]+)\\/blob\\/([^\\/]+)\\/(.*)/)
    def rawUrl = m ? "https://raw.githubusercontent.com/${m[0][1]}/${m[0][2]}/${m[0][3]}/${m[0][4]}" : f.url
    def dest = f.dest
    def filename = rawUrl.tokenize('/')[-1]
    return """
  mkdir -p "${dest}"
  echo "Downloading ${filename} -> ${dest}"
  curl -L --fail --retry 3 --retry-delay 2 -o "${dest}/${filename}" "${rawUrl}"
    """}.join('\n') : "echo 'No GitHub files configured for ${caseStudy}'"}

  echo "[fetch_from_github] completed!"
  """
}


