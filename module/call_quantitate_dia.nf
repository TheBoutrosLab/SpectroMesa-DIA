process call_quantitate_dia {
    publishDir "${params.final_output_dir}", mode: 'copy', pattern: 'quantitate-ProteomicDIA-*'
    input:
        tuple path(inputCsv), path(libraryTsv), path(configJson)
    output:
        path('quantitate-ProteomicDIA-*'), emit: result
    script:
        """
        set -euo pipefail
        NXF_WORK=\$(pwd)/child-work nextflow run \
            ${projectDir}/external/quantitate-ProteomicDIA/main.nf \
            -c ${projectDir}/external/quantitate-ProteomicDIA/config/template.config \
            -profile ${params.child_profile} \
            -params-file ${configJson} \
            --input_csv \$(realpath ${inputCsv}) \
            --library_tsv \$(realpath ${libraryTsv}) \
            --dataset_id ${params.dataset_id} \
            --output_dir \$(pwd)
        """
}
