#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { create_config_json } from './module/create_config_json.nf'
include { create_conversion_csv } from './module/create_conversion_csv.nf'
include { call_convert_msdata } from './module/call_convert_msdata.nf'
include { alias_converted_mzml } from './module/alias_converted_mzml.nf'
include { create_reconstruction_csv } from './module/create_reconstruction_csv.nf'
include { call_reconstruct_msms } from './module/call_reconstruct_msms.nf'
include { create_search_csv } from './module/create_search_csv.nf'
include { call_search_dia } from './module/call_search_dia.nf'
include { create_validation_csv } from './module/create_validation_csv.nf'
include { create_protloom_project } from './module/create_protloom_project.nf'
include { call_validate_psm } from './module/call_validate_psm.nf'
include { create_library_csv } from './module/create_library_csv.nf'
include { call_spectral_library } from './module/call_spectral_library.nf'
include { create_quantitation_csv } from './module/create_quantitation_csv.nf'
include { call_quantitate_dia } from './module/call_quantitate_dia.nf'
include { create_qc_inputs } from './module/create_qc_inputs.nf'
include { call_qc_dia } from './module/call_qc_dia.nf'
include { build_proteovault } from './module/build_proteovault.nf'

// Current child pipelines accept one mzML per sample. Retain fraction_id and
// annotation_id in the records for downstream validation and future fractions.
def readAcquisitionCsv(String inputCsv) {
    def csv = file(inputCsv)
    if (!csv.isFile()) error "Input CSV does not exist: ${csv}"
    if (csv.readLines().findAll { it.trim() }.size() < 2) {
        error "Input CSV has no data rows: ${csv}"
    }

    return Channel.fromPath(csv).splitCsv(header: true).toList().map { records ->
        def requiredColumns = ['sample_name', 'fraction_id', 'annotation_id', 'path'] as Set
        if (!records || !records[0].keySet().containsAll(requiredColumns)) {
            error 'Input CSV must contain sample_name,fraction_id,annotation_id,path columns and at least one row'
        }
        def seenSamples = [] as Set
        def seenNames = [] as Set
        def seenPaths = [] as Set
        def parsed = records.collect { row ->
            def sample = row.sample_name?.trim()
            def fraction = row.fraction_id?.trim()
            def annotation = row.annotation_id?.trim()
            if (!(sample ==~ /[A-Za-z0-9][A-Za-z0-9._-]*/) ||
                !(fraction ==~ /[A-Za-z0-9][A-Za-z0-9._-]*/) ||
                !(annotation ==~ /[A-Za-z0-9][A-Za-z0-9._-]*/)) {
                error "Invalid sample_name, fraction_id, or annotation_id: ${row}"
            }
            if (!seenSamples.add(sample)) {
                error "Multiple fractions for sample '${sample}' are not supported yet"
            }
            def raw = row.path?.trim()
            if (!raw) error "Missing acquisition path for ${sample}"
            def acquisition = file(raw.startsWith('/') ? raw : "${csv.parent}/${raw}")
            def isBruker = acquisition.isDirectory() && acquisition.name.toLowerCase().endsWith('.d')
            def isFile = acquisition.isFile()
            if (!isBruker && !isFile) {
                error "Input for ${sample} must be an MS data file or Bruker .d directory: ${acquisition}"
            }
            if (isFile && sample.contains('.')) {
                error "Sample name '${sample}' cannot contain a dot for converted mzML input"
            }
            def scanPath = row.scan?.trim()
            def isWiff = isFile && acquisition.name.toLowerCase().endsWith('.wiff')
            if (isWiff && !scanPath) {
                error "WIFF input for ${sample} requires a scan companion file in the scan column"
            }
            if (scanPath && !isWiff) {
                error "scan is only supported for WIFF input: ${sample}"
            }
            def scan = scanPath ? file(scanPath.startsWith('/') ? scanPath : "${csv.parent}/${scanPath}") : null
            if (scan && !scan.isFile()) {
                error "Missing scan companion file for ${sample}: ${scan}"
            }
            if (scan && !scan.name.equalsIgnoreCase("${acquisition.name}.scan")) {
                error "Scan companion for ${sample} must be named ${acquisition.name}.scan: ${scan}"
            }
            if ((isFile && acquisition.baseName.contains('.')) ||
                (isBruker && (!(sample ==~ /[A-Za-z0-9][A-Za-z0-9_-]*/) ||
                              !(fraction ==~ /[A-Za-z0-9][A-Za-z0-9_-]*/))) ||
                !seenNames.add(acquisition.name.toLowerCase()) ||
                !seenPaths.add(acquisition.toRealPath().toString())) {
                error "Invalid or duplicate acquisition name/path for ${sample}: ${acquisition}"
            }
            tuple(sample, fraction, acquisition.toRealPath().toString(), annotation,
                scan ? scan.toRealPath().toString() : '')
        }
        if (parsed*.getAt(2).collect { it.toLowerCase().endsWith('.d') }.unique().size() != 1) {
            error 'Input CSV must contain either Bruker .d directories or MS data files, not both'
        }
        parsed
    }
}

workflow {
    def database = file(params.decoy_database)
    def msfragger = file(params.msfragger_executable)

    samples = readAcquisitionCsv(params.input_csv)
    acquisitions = samples.branch {
        bruker: new File(it[0][2]).isDirectory()
        files: true
    }
    configOptions = Channel.of(
        ['convert_MSData', params.convert_MSData, params.child_processes_without_memory.convert_MSData ?: []],
        ['reconstruct_ProteomicMSMS', params.reconstruct_ProteomicMSMS, params.child_processes_without_memory.reconstruct_ProteomicMSMS ?: []],
        ['search_ProteomicDIA', params.search_ProteomicDIA, params.child_processes_without_memory.search_ProteomicDIA ?: []],
        ['validate_ProteomicPSM', params.validate_ProteomicPSM, params.child_processes_without_memory.validate_ProteomicPSM ?: []],
        ['generate_ProteomicSpectralLibrary', params.generate_ProteomicSpectralLibrary, params.child_processes_without_memory.generate_ProteomicSpectralLibrary ?: []],
        ['quantitate_ProteomicDIA', params.quantitate_ProteomicDIA, params.child_processes_without_memory.quantitate_ProteomicDIA ?: []],
        ['qc_ProteomicDIA', params.qc_ProteomicDIA, params.child_processes_without_memory.qc_ProteomicDIA ?: []]
    )
    create_config_json(configOptions)
    convertConfig = create_config_json.out.config.filter { name, config, resources -> name == 'convert_MSData' }.map { name, config, resources -> [config, resources] }
    reconstructConfig = create_config_json.out.config.filter { name, config, resources -> name == 'reconstruct_ProteomicMSMS' }.map { name, config, resources -> [config, resources] }
    searchConfig = create_config_json.out.config.filter { name, config, resources -> name == 'search_ProteomicDIA' }.map { name, config, resources -> [config, resources] }
    validateConfig = create_config_json.out.config.filter { name, config, resources -> name == 'validate_ProteomicPSM' }.map { name, config, resources -> [config, resources] }
    libraryConfig = create_config_json.out.config.filter { name, config, resources -> name == 'generate_ProteomicSpectralLibrary' }.map { name, config, resources -> [config, resources] }
    quantConfig = create_config_json.out.config.filter { name, config, resources -> name == 'quantitate_ProteomicDIA' }.map { name, config, resources -> [config, resources] }
    qcConfig = create_config_json.out.config.filter { name, config, resources -> name == 'qc_ProteomicDIA' }.map { name, config, resources -> [config, resources] }

    create_reconstruction_csv(acquisitions.bruker)
    reconstructInput = create_reconstruction_csv.out.input.combine(reconstructConfig)
        .map { csv, records, config, resources -> [csv, records, config, resources] }
    call_reconstruct_msms(
        reconstructInput,
        file(params.diatracer_executable ?: params.msfragger_executable),
        file(params.bruker_lib_dir ?: projectDir)
    )
    reconstructed = call_reconstruct_msms.out.result.map { records, directory ->
        records.collect { sample, fraction, acquisition, annotation, scan ->
            def mzml = file("${directory}/${params.dataset_id}/output/diaTracer/${sample}_${fraction}_diatracer.mzML")
            tuple(sample, fraction, mzml.toString(), annotation, '')
        }
    }
    create_conversion_csv(acquisitions.files)
    convertInput = create_conversion_csv.out.input.combine(convertConfig)
        .map { csv, records, config, resources -> [csv, records, config, resources] }
    call_convert_msdata(convertInput)
    alias_converted_mzml(call_convert_msdata.out.result)
    converted = alias_converted_mzml.out.result.map { records, directory ->
        records.collect { sample, fraction, acquisition, annotation, scan ->
            def mzml = file("${directory}/${sample}.mzML")
            tuple(sample, fraction, mzml.toString(), annotation, '')
        }
    }
    searchSamples = converted.mix(reconstructed)
    create_search_csv(searchSamples)
    searchInput = create_search_csv.out.input.combine(searchConfig)
        .map { csv, records, config, resources -> [csv, records, config, resources] }
    call_search_dia(searchInput, database, msfragger)

    create_validation_csv(call_search_dia.out.result)
    validationBase = create_validation_csv.out.input.combine(validateConfig)
    if (params.validate_ProteomicPSM.run_protloom) {
        create_protloom_project(searchSamples, params.validate_ProteomicPSM.protloom_project_yaml)
        validationInput = validationBase.combine(create_protloom_project.out.project)
            .map { records, inputCsv, mzmlCsv, config, resources, projectYaml ->
                [records, inputCsv, mzmlCsv, config, resources, projectYaml]
            }
    } else {
        validationInput = validationBase.map { records, inputCsv, mzmlCsv, config, resources ->
            [records, inputCsv, mzmlCsv, config, resources, []]
        }
    }
    call_validate_psm(validationInput, database)

    create_library_csv(call_validate_psm.out.result)
    libraryInput = create_library_csv.out.input.combine(libraryConfig)
        .map { records, idxmlCsv, mzmlCsv, psmTsv, peptideTsv, config, resources ->
            [records, idxmlCsv, mzmlCsv, psmTsv, peptideTsv, config, resources]
        }
    call_spectral_library(libraryInput)

    quantSamples = acquisitions.bruker.mix(converted)
    create_quantitation_csv(call_spectral_library.out.result, quantSamples)
    quantInput = create_quantitation_csv.out.input.combine(quantConfig)
        .map { inputCsv, libraryTsv, config, resources -> [inputCsv, libraryTsv, config, resources] }
    call_quantitate_dia(quantInput)

    create_qc_inputs(
        call_search_dia.out.result,
        call_validate_psm.out.result.map { records, dir -> dir },
        call_spectral_library.out.result.map { records, dir -> dir },
        call_quantitate_dia.out.result,
        quantSamples
    )
    qcInput = create_qc_inputs.out.input.combine(qcConfig)
        .map { mzmlCsv, searchCsv, filteredCsv, featuresCsv, proteinGroups,
               libraryTsv, exportSummary, diannReport, config, resources ->
            [mzmlCsv, searchCsv, filteredCsv, featuresCsv, proteinGroups,
             libraryTsv, exportSummary, diannReport, config, resources]
        }
    call_qc_dia(qcInput)

    if (!params.validate_ProteomicPSM.run_protloom) {
        build_proteovault(
            call_search_dia.out.result.map { records, dir -> dir },
            call_validate_psm.out.result.map { records, dir -> dir },
            call_spectral_library.out.result.map { records, dir -> dir },
            call_quantitate_dia.out.result,
            call_qc_dia.out.result,
            database
        )
    }
}
