process create_conversion_csv {
    publishDir "${params.final_output_dir}/manifests", mode: 'copy', pattern: 'conversion.csv'

    input:
        val(records)

    output:
        tuple path('conversion.csv'), val(records), emit: input

    exec:
        def csv = file("${task.workDir}/conversion.csv")
        csv.text = 'sample_name,fraction_id,path,scan\n'
        records.each { sample, fraction, acquisition, annotation, scan ->
            csv.append("${sample},${fraction},${acquisition},${scan}\n")
        }
}
