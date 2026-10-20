process create_validation_csv {
    publishDir "${params.final_output_dir}/manifests", mode: 'copy', pattern: '*.csv'

    input:
        tuple val(records), path(searchDir)

    output:
        tuple val(records), path('validation.csv'), path('validation-mzml.csv'), emit: input

    script:
        def ids = records.collect { sample, fraction, mzml ->
            def run = sample
            def id = "${searchDir}/${params.dataset_id}/output/MSFragger/${run}_MSFragger.idXML"
            """
            test -f '${id}' || { echo 'Missing search idXML: ${id}' >&2; exit 1; }
            printf '%s,%s,%s\\n' '${run}' 'MSFragger' "\$(realpath '${id}')" >> validation.csv
            """.stripIndent()
        }.join('\n')
        def mzmlRows = records.collect { sample, fraction, mzml ->
            "printf '%s,%s,%s\\n' '${sample}' '${fraction}' '${mzml}' >> validation-mzml.csv"
        }.join('\n')
        """
        set -euo pipefail
        printf 'sample_name,search_engine,idXML\\n' > validation.csv
        printf 'sample_name,fraction,mzML\\n' > validation-mzml.csv
        ${ids}
        ${mzmlRows}
        """
}
