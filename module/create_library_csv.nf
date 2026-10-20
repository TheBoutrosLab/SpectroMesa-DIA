process create_library_csv {
    publishDir "${params.final_output_dir}/manifests", mode: 'copy', pattern: '*.csv'

    input:
        tuple val(records), path(validationDir)

    output:
        tuple val(records), path('library.csv'), path('library-mzml.csv'),
            path('cohort-psm.tsv'), path('cohort-peptides.tsv'), emit: input

    script:
        def version = params.validate_ProteomicPSM.protloom_version ?: '0.2.3'
        def ids = records.collect { sample, fraction, mzml ->
            def run = sample
            def id = "${validationDir}/${run}/ProtLoom-${version}/output/${run}_protloom.idXML"
            """
            test -f '${id}' || { echo 'Missing unfiltered ProtLoom idXML: ${id}' >&2; exit 1; }
            printf '%s,%s\\n' '${run}' "\$(realpath '${id}')" >> library.csv
            """.stripIndent()
        }.join('\n')
        def mzmlRows = records.collect { sample, fraction, mzml ->
            "printf '%s,%s,%s\\n' '${sample}' '${fraction}' '${mzml}' >> library-mzml.csv"
        }.join('\n')
        def reports = "${validationDir}/${params.dataset_id}/ProtLoom-${version}/output"
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
