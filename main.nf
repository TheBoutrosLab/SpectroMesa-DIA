#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { create_config_json } from './module/create_config_json.nf'
include { create_search_csv } from './module/create_search_csv.nf'
include { call_search_dia } from './module/call_search_dia.nf'
include { create_validation_csv } from './module/create_validation_csv.nf'
include { create_protloom_project } from './module/create_protloom_project.nf'
include { call_validate_psm } from './module/call_validate_psm.nf'
include { create_library_csv } from './module/create_library_csv.nf'
include { call_spectral_library } from './module/call_spectral_library.nf'
include { create_quantitation_csv } from './module/create_quantitation_csv.nf'
include { call_quantitate_dia } from './module/call_quantitate_dia.nf'

// Current child pipelines accept one mzML per sample. Retain fraction_id and
// annotation_id in the records for downstream validation and future fractions.
def readMzMLCsv(String inputCsv) {
    def csv = file(inputCsv)
    if (!csv.isFile()) error "Input CSV does not exist: ${csv}"
    if (csv.readLines().findAll { it.trim() }.size() < 2) {
        error "Input CSV has no data rows: ${csv}"
    }

    return Channel.fromPath(csv).splitCsv(header: true).toList().map { records ->
        if (!records || records[0].keySet() != (['sample_name', 'fraction_id', 'annotation_id', 'path'] as Set)) {
            error 'Input CSV must have exactly sample_name,fraction_id,annotation_id,path columns and at least one row'
        }
        def seenSamples = [] as Set
        def seenNames = [] as Set
        def seenPaths = [] as Set
        records.collect { row ->
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
            if (!raw) error "Missing mzML path for ${sample}"
            def mzml = file(raw.startsWith('/') ? raw : "${csv.parent}/${raw}")
            if (!mzml.isFile() || !mzml.name.toLowerCase().endsWith('.mzml')) {
                error "Missing or invalid mzML for ${sample}: ${mzml}"
            }
            if (mzml.baseName.contains('.') || !seenNames.add(mzml.name.toLowerCase()) ||
                !seenPaths.add(mzml.toRealPath().toString())) {
                error "mzML basenames and paths must be unique, with no dots before .mzML: ${mzml}"
            }
            tuple(sample, fraction, mzml.toRealPath().toString(), annotation)
        }
    }
}

workflow {
    def database = file(params.decoy_database)
    def msfragger = file(params.msfragger_executable)

    samples = readMzMLCsv(params.input_csv)
    configOptions = Channel.of(
        ['search_ProteomicDIA', params.search_ProteomicDIA, params.child_processes_without_memory.search_ProteomicDIA ?: []],
        ['validate_ProteomicPSM', params.validate_ProteomicPSM, params.child_processes_without_memory.validate_ProteomicPSM ?: []],
        ['generate_ProteomicSpectralLibrary', params.generate_ProteomicSpectralLibrary, params.child_processes_without_memory.generate_ProteomicSpectralLibrary ?: []],
        ['quantitate_ProteomicDIA', params.quantitate_ProteomicDIA, params.child_processes_without_memory.quantitate_ProteomicDIA ?: []]
    )
    create_config_json(configOptions)
    searchConfig = create_config_json.out.config.filter { name, config, resources -> name == 'search_ProteomicDIA' }.map { name, config, resources -> [config, resources] }
    validateConfig = create_config_json.out.config.filter { name, config, resources -> name == 'validate_ProteomicPSM' }.map { name, config, resources -> [config, resources] }
    libraryConfig = create_config_json.out.config.filter { name, config, resources -> name == 'generate_ProteomicSpectralLibrary' }.map { name, config, resources -> [config, resources] }
    quantConfig = create_config_json.out.config.filter { name, config, resources -> name == 'quantitate_ProteomicDIA' }.map { name, config, resources -> [config, resources] }

    create_search_csv(samples)
    searchInput = create_search_csv.out.input.combine(searchConfig)
        .map { csv, records, config, resources -> [csv, records, config, resources] }
    call_search_dia(searchInput, database, msfragger)

    create_validation_csv(call_search_dia.out.result)
    validationBase = create_validation_csv.out.input.combine(validateConfig)
    if (params.validate_ProteomicPSM.run_protloom) {
        create_protloom_project(samples, params.validate_ProteomicPSM.protloom_project_yaml)
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

    create_quantitation_csv(call_spectral_library.out.result)
    quantInput = create_quantitation_csv.out.input.combine(quantConfig)
        .map { inputCsv, libraryTsv, config, resources -> [inputCsv, libraryTsv, config, resources] }
    call_quantitate_dia(quantInput)
}
