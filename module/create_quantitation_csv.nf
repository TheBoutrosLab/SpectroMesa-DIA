process create_quantitation_csv {
    publishDir "${params.final_output_dir}/manifests", mode: 'copy', pattern: 'quantitation.csv'

    input:
        tuple val(records), path(libraryDir)

    output:
        tuple path('quantitation.csv'), path('library.tsv'), emit: input

    script:
        def library = "${libraryDir}/${params.dataset_id}/output/EasyPQP/${params.dataset_id}_library.tsv"
        def mzmlRows = records.collect { sample, fraction, mzml ->
            "printf '%s,%s\\n' '${sample}' '${mzml}' >> quantitation.csv"
        }.join('\n')
        """
        set -euo pipefail
        test -f '${library}' || { echo 'Missing spectral library: ${library}' >&2; exit 1; }
        printf 'sample_name,mzML\\n' > quantitation.csv
        ${mzmlRows}
        cp '${library}' library.tsv
        """
}
