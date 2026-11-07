process call_convert_msdata {
    publishDir "${params.final_output_dir}", mode: 'copy', pattern: 'convert-MSData-*'

    input:
        tuple path(inputCsv), val(records), path(configJson), path(resourceConfig)

    output:
        tuple val(records), path('convert-MSData-*'), emit: result

    script:
        """
        set -euo pipefail
        NXF_WORK=\$(pwd)/child-work nextflow run \
            ${projectDir}/external/convert-MSData/main.nf \
            -c ${projectDir}/external/convert-MSData/config/template_pwiz.config \
            -c ${resourceConfig} \
            -c ${projectDir}/config/convert_runtime.config \
            -profile ${params.child_profile} \
            -params-file ${configJson} \
            --input_csv \$(realpath ${inputCsv}) \
            --output_dir \$(pwd)
        """
}
