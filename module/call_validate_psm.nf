process call_validate_psm {
    publishDir "${params.final_output_dir}", mode: 'copy', pattern: 'validate-ProteomicPSM-*'
    input:
        tuple val(records), path(inputCsv), path(mzmlCsv), path(configJson), path(resourceConfig), path(projectYaml)
        path decoyDatabase
    output:
        tuple val(records), path('validate-ProteomicPSM-*'), emit: result
    script:
        def fractionated = records.collect { it[1] }.toSet().size() > 1
        def projectArgument = params.validate_ProteomicPSM.run_protloom ?
            "--protloom_project_yaml \$(realpath ${projectYaml})" : ''
        """
        set -euo pipefail
        NXF_WORK=\$(pwd)/child-work nextflow run \
            ${projectDir}/external/validate-ProteomicPSM/main.nf \
            -c ${projectDir}/external/validate-ProteomicPSM/config/template.config \
            -c ${resourceConfig} \
            -profile ${params.child_profile} \
            -params-file ${configJson} \
            ${projectArgument} \
            --input_csv \$(realpath ${inputCsv}) \
            --input_mzml_csv \$(realpath ${mzmlCsv}) \
            --decoy_database \$(realpath ${decoyDatabase}) \
            --dataset_id ${params.dataset_id} \
            --run_percolator true \
            --percolator_workflow msbooster \
            --run_protloom ${params.validate_ProteomicPSM.run_protloom} \
            --export_easypqp_reports true \
            --merge_consensus false \
            --fractionated ${fractionated} \
            --output_dir \$(pwd)
        """
}
