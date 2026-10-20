process call_validate_psm {
    publishDir "${params.final_output_dir}", mode: 'copy', pattern: 'validate-ProteomicPSM-*'
    input:
        tuple val(records), path(inputCsv), path(mzmlCsv), path(configJson)
        path decoyDatabase
    output:
        tuple val(records), path('validate-ProteomicPSM-*'), emit: result
    script:
        """
        set -euo pipefail
        NXF_WORK=\$(pwd)/child-work nextflow run \
            ${projectDir}/external/validate-ProteomicPSM/main.nf \
            -c ${projectDir}/external/validate-ProteomicPSM/config/template.config \
            -profile ${params.child_profile} \
            -params-file ${configJson} \
            --input_csv \$(realpath ${inputCsv}) \
            --input_mzml_csv \$(realpath ${mzmlCsv}) \
            --decoy_database \$(realpath ${decoyDatabase}) \
            --dataset_id ${params.dataset_id} \
            --run_percolator true \
            --percolator_workflow msbooster \
            --run_protloom true \
            --export_easypqp_reports true \
            --merge_consensus false \
            --fractionated false \
            --output_dir \$(pwd)
        """
}
