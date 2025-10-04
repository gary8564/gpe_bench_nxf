process fetch_from_figshare {
  tag "${caseStudy}"

  input:
    val caseStudy

  output:
    tuple val(caseStudy), path("raw_data/${caseStudy}"), emit: raw

  script:
  def dataset_config = params.datasets[caseStudy]

  """
  # Download simulator outputs from Figshare into raw_data/${caseStudy}
  mkdir -p raw_data/${caseStudy}
  cd raw_data/${caseStudy}

  echo "[fetch_from_figshare] Downloading Figshare data for ${caseStudy}"

  # Iterate over configured Figshare articles
  ${dataset_config?.figshare?.articles ? dataset_config.figshare.articles.collect { art ->
    def id = art.id
    def dest = art.dest
    return """
  echo "Fetching Figshare article ${id} -> ${dest}"
  mkdir -p "${dest}"
  curl -sS "https://api.figshare.com/v2/articles/${id}" \
    | jq -r '.files[]? | [.download_url, .name] | @tsv' \
    | while IFS=\$'\t' read -r url name; do
        echo "Downloading \$name"
        curl -L --fail --retry 3 --retry-delay 2 -o "${dest}/\$name" "\$url"
        case "\$name" in
          (*.zip|*.ZIP|*.Zip)
            unzip -q -o "${dest}/\$name" -d "${dest}"
            rm -f "${dest}/\$name"
            ;;
        esac
      done
    """}.join('\n') : "echo 'No Figshare articles configured for ${caseStudy}'"}

  echo "[fetch_from_figshare] completed!"
  """
}


