process create_search_csv {
    publishDir "${params.final_output_dir}/manifests", mode: 'copy', pattern: 'search.csv'
    input:
        val(records)
    output:
        tuple path('search.csv'), val(records), emit: input
    exec:
        def csv = file("${task.workDir}/search.csv")
        csv.text = 'sample_name,mzML\n'
        records.each { sample, fraction, mzml, annotation ->
            csv.append("${sample},${mzml}\n")
        }
}
