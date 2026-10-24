process create_library_csv {
    publishDir "${params.final_output_dir}/manifests", mode: 'copy', pattern: '*.csv'

    input:
        tuple val(records), path(validationDir)

    output:
        tuple val(records), path('library.csv'), path('library-mzml.csv'),
            path('cohort-psm.tsv'), path('cohort-peptides.tsv'), emit: input

    script:
        def useProtLoom = params.validate_ProteomicPSM.run_protloom
        def version = useProtLoom ?
            (params.validate_ProteomicPSM.get('protloom_version') ?: '0.2.3') :
            (params.validate_ProteomicPSM.get('openms_version') ?: '3.5.0')
        def ids = records.collect { sample, fraction, mzml, annotation ->
            def run = sample
            def id = useProtLoom ?
                "${validationDir}/${run}/ProtLoom-${version}/output/${run}_protloom.idXML" :
                "${validationDir}/${run}/OpenMS-${version}/output/${run}_MSFragger_idswitch_pep.idXML"
            """
            test -f '${id}' || { echo 'Missing unfiltered library idXML: ${id}' >&2; exit 1; }
            printf '%s,%s\\n' '${run}' "\$(realpath '${id}')" >> library.csv
            """.stripIndent()
        }.join('\n')
        def mzmlRows = records.collect { sample, fraction, mzml, annotation ->
            "printf '%s,%s,%s\\n' '${sample}' '${fraction}' '${mzml}' >> library-mzml.csv"
        }.join('\n')
        def reports = useProtLoom ?
            "${validationDir}/${params.dataset_id}/ProtLoom-${version}/output" :
            "${validationDir}/${params.dataset_id}/${params.validate_ProteomicPSM.protein_inference_algorithm}/output"
        """
        set -euo pipefail
        printf 'sample_name,idXML\\n' > library.csv
        printf 'sample_name,fraction_id,mzML\\n' > library-mzml.csv
        ${ids}
        ${mzmlRows}
        test -f '${reports}/${params.dataset_id}-psm.tsv' || { echo 'Missing cohort PSM report' >&2; exit 1; }
        test -f '${reports}/${params.dataset_id}-peptides.tsv' || { echo 'Missing cohort peptide report' >&2; exit 1; }
        cp '${reports}/${params.dataset_id}-psm.tsv' cohort-psm.tsv
        cp '${reports}/${params.dataset_id}-peptides.tsv' cohort-peptides.tsv
        """
}
