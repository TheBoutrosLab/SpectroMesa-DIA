process call_spectral_library {
    publishDir "${params.final_output_dir}", mode: 'copy', pattern: 'generate-ProteomicSpectralLibrary-*'
    input:
        tuple val(records), path(idxmlCsv), path(mzmlCsv), path(psmTsv), path(peptideTsv), path(configJson), path(resourceConfig)
    output:
        tuple val(records), path('generate-ProteomicSpectralLibrary-*'), emit: result
    script:
        def fractionated = records.collect { it[1] }.toSet().size() > 1
        """
        set -euo pipefail
        NXF_WORK=\$(pwd)/child-work nextflow run \
            ${projectDir}/external/generate-ProteomicSpectralLibrary/main.nf \
            -c ${projectDir}/external/generate-ProteomicSpectralLibrary/config/template.config \
            -c ${resourceConfig} \
            -profile ${params.child_profile} \
            -params-file ${configJson} \
            --idxml_csv \$(realpath ${idxmlCsv}) \
            --mzml_csv \$(realpath ${mzmlCsv}) \
            --psm_tsv \$(realpath ${psmTsv}) \
            --peptide_tsv \$(realpath ${peptideTsv}) \
            --dataset_id ${params.dataset_id} \
            --fractionated ${fractionated} \
            --output_dir \$(pwd)
        """
}
