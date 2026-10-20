process call_search_dia {
    cpus params.search_ProteomicDIA.subworkflow_cpus ?: 1
    publishDir "${params.final_output_dir}", mode: 'copy', pattern: 'search-ProteomicDIA-*'
    input:
        tuple path(inputCsv), val(records), path(configJson)
        path decoyDatabase
        path msfraggerJar
    output:
        tuple val(records), path('search-ProteomicDIA-*'), emit: result
    script:
        """
        set -euo pipefail
        NXF_WORK=\$(pwd)/child-work nextflow run \
            ${projectDir}/external/search-ProteomicDIA/main.nf \
            -c ${projectDir}/external/search-ProteomicDIA/config/template.config \
            -profile ${params.child_profile} \
            -params-file ${configJson} \
            --input_csv \$(realpath ${inputCsv}) \
            --decoy_database \$(realpath ${decoyDatabase}) \
            --msfragger_executable \$(realpath ${msfraggerJar}) \
            --dataset_id ${params.dataset_id} \
            --output_dir \$(pwd)
        """
}
