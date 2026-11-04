process create_reconstruction_csv {
    publishDir "${params.final_output_dir}/manifests", mode: 'copy', pattern: 'reconstruction.csv'

    input:
        val(records)

    output:
        tuple path('reconstruction.csv'), val(records), emit: input

    exec:
        def csv = file("${task.workDir}/reconstruction.csv")
        csv.text = 'sample_name,fraction_id,path\n'
        records.each { sample, fraction, acquisition, annotation ->
            csv.append("${sample},${fraction},${acquisition}\n")
        }
}
