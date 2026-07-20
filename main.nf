cat > main.nf <<'EOF'
#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

workflow {
    log.info """
    ==========================================
    AMR Oxford Nanopore Pipeline
    ==========================================
    Input  : ${params.input}
    Output : ${params.outdir}
    ==========================================
    """

    Channel
        .of('Pipeline initialization successful')
        .view()
}
EOF