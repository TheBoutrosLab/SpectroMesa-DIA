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
        def useProtLoom = params.validate_ProteomicPSM.run_protloom
        def route = params.qc_ProteomicDIA.inference_route
        def protloomVersion = params.validate_ProteomicPSM.get('protloom_version') ?: '0.3.1'
        def openmsVersion = params.validate_ProteomicPSM.get('openms_version') ?: '3.5.0'
        def validationOutput = useProtLoom ?
            "${validationDir}/${params.dataset_id}/ProtLoom-${protloomVersion}/output" :
            "${validationDir}/${params.dataset_id}/${route}/output"
        def featureRoute = params.validate_ProteomicPSM.run_percolator ?
            (params.validate_ProteomicPSM.percolator_workflow == 'msbooster' ? 'MSBooster' : 'PSMFeatureExtractor') : null
        def acquisitionBySample = rawRecords.collectEntries { sample, fraction, acquisition, annotation, scan ->
            [(sample): acquisition]
        }
        def rows = records.collect { sample, fraction, mzml, annotation, scan ->
            def acquisition = acquisitionBySample[sample]
            if (!acquisition) error "Missing raw acquisition for ${sample}"
            def searchId = "${searchDir}/${params.dataset_id}/output/MSFragger/${sample}_MSFragger.idXML"
            def filteredId = useProtLoom ?
                "${validationDir}/${sample}/ProtLoom-${protloomVersion}/output/${sample}_ProtLoom_filter.idXML" :
                "${validationDir}/${sample}/OpenMS-${openmsVersion}/output/${sample}_MSFragger_filter.idXML"
            def featurePath = featureRoute == 'MSBooster' ?
                "${validationDir}/${sample}/MSBooster/output/engine_MSFragger/run_01-fraction_${fraction}_edited.pin" :
                "${validationDir}/${sample}/OpenMS-${openmsVersion}/output/${sample}_MSFragger_featureExtracted.idXML"
            def featureRow = featureRoute ?
                "if [ -f '${featurePath}' ]; then printf '%s,%s,%s,%s,%s\\n' '${sample}' 'MSFragger' '${featureRoute}' '${featureRoute == 'MSBooster' ? fraction : ''}' \"\$(realpath '${featurePath}')\" >> qc-psm-features.csv; fi" : ''
            def groupRow = useProtLoom ?
                """
                group_tsv='${validationDir}/${sample}/ProtLoom-${protloomVersion}/output/${sample}_groups.tsv'
                test -f "\$group_tsv" || { echo "Missing ProtLoom groups: \$group_tsv" >&2; exit 1; }
                printf '%s,%s\\n' '${sample}' "\$(realpath "\$group_tsv")" >> qc-protein-groups.input
                """.stripIndent() : ''
            """
            test -f '${mzml}' || { echo 'Missing mzML: ${mzml}' >&2; exit 1; }
            test -f '${searchId}' || { echo 'Missing search idXML: ${searchId}' >&2; exit 1; }
            test -f '${filteredId}' || { echo 'Missing filtered idXML: ${filteredId}' >&2; exit 1; }
            printf '%s,%s,%s,%s\\n' '${sample}' '${fraction}' "\$(realpath '${mzml}')" "\$(realpath '${acquisition}')" >> qc-mzml.csv
            printf '%s,%s,%s\\n' '${sample}' 'MSFragger' "\$(realpath '${searchId}')" >> qc-search-idxml.csv
            printf '%s,%s\\n' '${sample}' "\$(realpath '${filteredId}')" >> qc-filtered-idxml.csv
            ${featureRow}
            ${groupRow}
            """.stripIndent()
        }.join('\n')
        def groupFile = route == 'Fido' ?
            "${validationOutput}/${params.dataset_id}-Fido-groups.json" :
            "${validationOutput}/${params.dataset_id}-${route}.idXML"
        def groupCommand = useProtLoom ?
            "printf 'sample_name,groups_tsv\\n' > qc-protein-groups.input" :
            "test -f '${groupFile}' || { echo 'Missing protein groups: ${groupFile}' >&2; exit 1; }; ln -s \"\$(realpath '${groupFile}')\" qc-protein-groups.input"
        def library = "${libraryDir}/${params.dataset_id}/output/EasyPQP/${params.dataset_id}_library.tsv"
        def summary = "${validationOutput}/${params.dataset_id}-easypqp_export_summary.tsv"
        def report = "${quantDir}/${params.dataset_id}/output/DIA-NN/${params.dataset_id}-report.tsv"
        """
        set -euo pipefail
        printf 'sample_name,fraction_id,path,acquisition_path\\n' > qc-mzml.csv
        printf 'sample_name,search_engine,idXML\\n' > qc-search-idxml.csv
        printf 'sample_name,idXML\\n' > qc-filtered-idxml.csv
        printf 'sample_name,search_engine,route,fraction_id,path\\n' > qc-psm-features.csv
        ${groupCommand}
        ${rows}
        test -f '${library}' || { echo 'Missing EasyPQP library: ${library}' >&2; exit 1; }
        test -f '${summary}' || { echo 'Missing EasyPQP export summary: ${summary}' >&2; exit 1; }
        test -f '${report}' || { echo 'Missing DIA-NN report: ${report}' >&2; exit 1; }
        ln -s "\$(realpath '${library}')" qc-library.tsv
        ln -s "\$(realpath '${summary}')" qc-export-summary.tsv
        ln -s "\$(realpath '${report}')" qc-diann-report.tsv
        """
}
