process MULTIQC {

  conda "${projectDir}/envs/reporting.yml"

  tag "final_report"

  publishDir (
      path: "${params.outdir}/multiqc", 
      mode: 'copy',
      overwrite:true
)

  input:
  path qc_files

  output:
  path "multiqc_report.html", emit: html
  path "multiqc_report_data", emit: data

  script:
  """
  multiqc . \
    --force \
    --filename multiqc_report.html 
  """
}

