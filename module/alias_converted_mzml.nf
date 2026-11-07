process alias_converted_mzml {
    input:
        tuple val(records), path(convertDir)

    output:
        tuple val(records), path('aliased-mzml'), emit: result

    exec:
        def aliases = file("${task.workDir}/aliased-mzml")
        aliases.mkdirs()
        records.each { sample, fraction, acquisition, annotation, scan ->
            def basename = file(acquisition).baseName
            def suffix = params.convert_MSData.run_index ? '_indexed' : ''
            if (params.convert_MSData.peak_picking_openms) suffix += '_centroid'
            def software = params.convert_MSData.convert_algorithm == 'OpenMS' ?
                "OpenMS-${params.convert_MSData.openms_version}" :
                "ProteoWizard-${params.convert_MSData.pwiz_version}"
            def mzml = file("${convertDir}/${sample}/${software}/output/${fraction}_${basename}${suffix}.mzML")
            if (!mzml.isFile()) error "Converted mzML is missing for ${sample}: ${mzml}"
            java.nio.file.Files.createSymbolicLink(
                file("${aliases}/${sample}.mzML").toPath(), mzml.toPath().toAbsolutePath()
            )
        }
}
