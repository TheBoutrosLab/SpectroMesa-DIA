process call_qc_dia {
    publishDir "${params.final_output_dir}", mode: 'copy', pattern: 'qc-ProteomicDIA-*'

    input:
        tuple path(mzmlCsv), path(searchCsv), path(filteredCsv), path(proteinGroups),
            path(libraryTsv), path(exportSummary), path(diannReport),
            path(configJson), path(resourceConfig)

    output:
        path('qc-ProteomicDIA-*'), emit: result

    script:
        """
        set -euo pipefail
        NXF_WORK=\$(pwd)/child-work nextflow run \\
            ${projectDir}/external/qc-ProteomicDIA/main.nf \\
            -c ${projectDir}/external/qc-ProteomicDIA/config/template.config \\
            -c ${resourceConfig} \\
            -profile ${params.child_profile} \\
            -params-file ${configJson} \\
            --mzml_csv \$(realpath ${mzmlCsv}) \\
            --search_idxml_csv \$(realpath ${searchCsv}) \\
            --filtered_idxml_csv \$(realpath ${filteredCsv}) \\
            --inference_route ${params.qc_ProteomicDIA.inference_route} \\
            --protein_groups \$(realpath ${proteinGroups}) \\
            --library_tsv \$(realpath ${libraryTsv}) \\
            --export_summary_tsv \$(realpath ${exportSummary}) \\
            --diann_report \$(realpath ${diannReport}) \\
            --dataset_id ${params.dataset_id} \\
            --output_dir \$(pwd)
        """
}
