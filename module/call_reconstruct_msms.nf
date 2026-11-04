process call_reconstruct_msms {
    publishDir "${params.final_output_dir}", mode: 'copy', pattern: 'reconstruct-ProteomicMSMS-*'

    input:
        tuple path(inputCsv), val(records), path(configJson), path(resourceConfig)
        path diatracerJar
        path brukerLibDir

    output:
        tuple val(records), path('reconstruct-ProteomicMSMS-*'), emit: result

    script:
        """
        set -euo pipefail
        NXF_VER=${params.reconstruct_nextflow_version} NXF_SYNTAX_PARSER=v1 NXF_WORK=\$(pwd)/child-work nextflow run \
            ${projectDir}/external/reconstruct-ProteomicMSMS/main.nf \
            -c ${projectDir}/external/reconstruct-ProteomicMSMS/config/template.config \
            -c ${resourceConfig} \
            -c ${projectDir}/config/reconstruct_runtime.config \
            -profile ${params.child_profile} \
            -params-file ${configJson} \
            --input_csv \$(realpath ${inputCsv}) \
            --diatracer_executable \$(realpath ${diatracerJar}) \
            --bruker_lib_dir \$(realpath ${brukerLibDir}) \
            --dataset_id ${params.dataset_id} \
            --output_dir \$(pwd)
        """
}
