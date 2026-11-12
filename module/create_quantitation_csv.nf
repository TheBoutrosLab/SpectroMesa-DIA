process create_quantitation_csv {
    publishDir "${params.final_output_dir}/manifests", mode: 'copy', pattern: 'quantitation.csv'

    input:
        tuple val(records), path(libraryDir)
        val(rawRecords)

    output:
        tuple path('quantitation.csv'), path('library.tsv'), emit: input

    script:
        def fractionated = records.collect { it[1] }.toSet().size() > 1
        def libraryPairs = records.collect { [it[0], it[1]] } as Set
        def acquisitionPairs = rawRecords.collect { [it[0], it[1]] } as Set
        if (libraryPairs != acquisitionPairs || rawRecords.size() != records.size()) {
            error "Library and quantitation acquisitions have different sample/fraction pairs"
        }
        def library = "${libraryDir}/${params.dataset_id}/output/EasyPQP/${params.dataset_id}_library.tsv"
        def mzmlRows = rawRecords.collect { sample, fraction, mzml, annotation, scan ->
            fractionated ?
                "printf '%s,%s,%s\\n' '${sample}' '${fraction}' '${mzml}' >> quantitation.csv" :
                "printf '%s,%s\\n' '${sample}' '${mzml}' >> quantitation.csv"
        }.join('\n')
        """
        set -euo pipefail
        test -f '${library}' || { echo 'Missing spectral library: ${library}' >&2; exit 1; }
        printf '${fractionated ? 'sample_name,fraction_id,path' : 'sample_name,path'}\\n' > quantitation.csv
        ${mzmlRows}
        cp '${library}' library.tsv
        """
}
