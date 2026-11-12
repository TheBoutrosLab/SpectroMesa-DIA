/** Commands for one search mzML and its matching original acquisition. */
def qcAcquisitionCommands(def record, def acquisition, def validationDir, def featureRoute) {
    def sample = record[0]
    def fraction = record[1]
    def mzml = record[2]

    def featureCommands = ''
    if (featureRoute == 'MSBooster') {
        def featureDir = "${validationDir}/${sample}/MSBooster/output/engine_MSFragger"
        featureCommands = """
            for feature_path in '${featureDir}'/run_*-fraction_${fraction}_edited.pin; do
                if [ -f "\$feature_path" ]; then
                    printf '%s,%s,%s,%s,%s\\n' '${sample}' 'MSFragger' 'MSBooster' '${fraction}' \
                        "\$(realpath "\$feature_path")" >> qc-psm-features.csv
                fi
            done
        """.stripIndent()
    }

    """
        test -f '${mzml}' || { echo 'Missing mzML: ${mzml}' >&2; exit 1; }
        printf '%s,%s,%s,%s\\n' '${sample}' '${fraction}' \
            "\$(realpath '${mzml}')" "\$(realpath '${acquisition}')" >> qc-mzml.csv
        ${featureCommands}
    """.stripIndent()
}

/** Commands for one sample's merged search and filtered identification files. */
def qcSampleCommands(def sample, def searchDir, def validationDir, def dataset,
                     def useProtLoom, def protloomVersion, def openmsVersion, def featureRoute) {
    def searchId = "${searchDir}/${dataset}/output/MSFragger/${sample}_MSFragger.idXML"
    def filteredId = useProtLoom ?
        "${validationDir}/${sample}/ProtLoom-${protloomVersion}/output/${sample}_ProtLoom_filter.idXML" :
        "${validationDir}/${sample}/OpenMS-${openmsVersion}/output/${sample}_MSFragger_filter.idXML"

    def featureCommands = ''
    if (featureRoute == 'PSMFeatureExtractor') {
        def feature = "${validationDir}/${sample}/OpenMS-${openmsVersion}/output/${sample}_MSFragger_featureExtracted.idXML"
        featureCommands = """
            if [ -f '${feature}' ]; then
                printf '%s,%s,%s,%s,%s\\n' '${sample}' 'MSFragger' 'PSMFeatureExtractor' '' \
                    "\$(realpath '${feature}')" >> qc-psm-features.csv
            fi
        """.stripIndent()
    }

    def groupCommands = ''
    if (useProtLoom) {
        def groups = "${validationDir}/${sample}/ProtLoom-${protloomVersion}/output/${sample}_groups.tsv"
        groupCommands = """
            test -f '${groups}' || { echo 'Missing ProtLoom groups: ${groups}' >&2; exit 1; }
            printf '%s,%s\\n' '${sample}' "\$(realpath '${groups}')" >> qc-protein-groups.input
        """.stripIndent()
    }

    """
        test -f '${searchId}' || { echo 'Missing search idXML: ${searchId}' >&2; exit 1; }
        test -f '${filteredId}' || { echo 'Missing filtered idXML: ${filteredId}' >&2; exit 1; }
        printf '%s,%s,%s\\n' '${sample}' 'MSFragger' "\$(realpath '${searchId}')" >> qc-search-idxml.csv
        printf '%s,%s\\n' '${sample}' "\$(realpath '${filteredId}')" >> qc-filtered-idxml.csv
        ${featureCommands}
        ${groupCommands}
    """.stripIndent()
}

/** Assemble the QC handoff: acquisition rows per fraction, identification rows per sample. */
def buildQcInputScript(def records, def rawRecords, def searchDir, def validationDir,
                       def libraryDir, def quantDir, def settings) {
    def dataset = settings.dataset_id
    def validation = settings.validate_ProteomicPSM
    def useProtLoom = validation.run_protloom
    def route = settings.qc_ProteomicDIA.inference_route
    def protloomVersion = validation.get('protloom_version') ?: '0.3.1'
    def openmsVersion = validation.get('openms_version') ?: '3.5.0'
    def featureRoute = null
    if (validation.run_percolator) {
        featureRoute = validation.percolator_workflow == 'msbooster' ?
            'MSBooster' : 'PSMFeatureExtractor'
    }

    // Match by both fields so two fractions of one sample keep their own raw inputs.
    def rawByPair = rawRecords.collectEntries { sample, fraction, acquisition, annotation, scan ->
        [([sample, fraction]): acquisition]
    }
    def searchPairs = records.collect { [it[0], it[1]] }
    if (rawByPair.size() != rawRecords.size() ||
        searchPairs.size() != searchPairs.toSet().size() ||
        searchPairs.toSet() != rawByPair.keySet()) {
        throw new IllegalArgumentException('QC acquisitions do not match search sample/fraction pairs')
    }

    def acquisitionCommands = records.collect { record ->
        qcAcquisitionCommands(record, rawByPair[[record[0], record[1]]], validationDir, featureRoute)
    }.join('\n')
    def sampleCommands = records.collect { it[0] }.unique().collect { sample ->
        qcSampleCommands(sample, searchDir, validationDir, dataset, useProtLoom,
            protloomVersion, openmsVersion, featureRoute)
    }.join('\n')

    def validationOutput = useProtLoom ?
        "${validationDir}/${dataset}/ProtLoom-${protloomVersion}/output" :
        "${validationDir}/${dataset}/${route}/output"
    def groupName = route == 'Fido' ? "${dataset}-Fido-groups.json" : "${dataset}-${route}.idXML"
    def groupCommands = useProtLoom ?
        "printf 'sample_name,groups_tsv\\n' > qc-protein-groups.input" :
        """
            group_file='${validationOutput}/${groupName}'
            test -f "\$group_file" || { echo "Missing protein groups: \$group_file" >&2; exit 1; }
            ln -s "\$(realpath "\$group_file")" qc-protein-groups.input
        """.stripIndent()

    def library = "${libraryDir}/${dataset}/output/EasyPQP/${dataset}_library.tsv"
    def summary = "${validationOutput}/${dataset}-easypqp_export_summary.tsv"
    def report = "${quantDir}/${dataset}/output/DIA-NN/${dataset}-report.tsv"

    """
        set -euo pipefail
        printf 'sample_name,fraction_id,path,acquisition_path\\n' > qc-mzml.csv
        printf 'sample_name,search_engine,idXML\\n' > qc-search-idxml.csv
        printf 'sample_name,idXML\\n' > qc-filtered-idxml.csv
        printf 'sample_name,search_engine,route,fraction_id,path\\n' > qc-psm-features.csv
        ${groupCommands}
        ${acquisitionCommands}
        ${sampleCommands}
        test -f '${library}' || { echo 'Missing EasyPQP library: ${library}' >&2; exit 1; }
        test -f '${summary}' || { echo 'Missing EasyPQP export summary: ${summary}' >&2; exit 1; }
        test -f '${report}' || { echo 'Missing DIA-NN report: ${report}' >&2; exit 1; }
        ln -s "\$(realpath '${library}')" qc-library.tsv
        ln -s "\$(realpath '${summary}')" qc-export-summary.tsv
        ln -s "\$(realpath '${report}')" qc-diann-report.tsv
    """
}

process create_qc_inputs {
    publishDir "${params.final_output_dir}/manifests", mode: 'copy', pattern: 'qc-*.csv'

    input:
        tuple val(records), path(searchDir)
        path validationDir
        path libraryDir
        path quantDir
        val(rawRecords)

    output:
        tuple path('qc-mzml.csv'), path('qc-search-idxml.csv'),
            path('qc-filtered-idxml.csv'), path('qc-psm-features.csv'), path('qc-protein-groups.input'),
            path('qc-library.tsv'), path('qc-export-summary.tsv'),
            path('qc-diann-report.tsv'), emit: input

    script:
        buildQcInputScript(records, rawRecords, searchDir, validationDir, libraryDir, quantDir, params)
}
