process create_protloom_project {
    publishDir "${params.final_output_dir}/manifests", mode: 'copy',
        pattern: 'protloom-project.generated.yaml'

    input:
        val records
        val sourceYaml

    output:
        path('protloom-project.generated.yaml'), emit: project

    exec:
        def source = new File(sourceYaml.toString()).canonicalFile
        if (!source.isFile()) {
            error "ProtLoom project YAML does not exist: ${source}"
        }
        def yaml = new org.yaml.snakeyaml.Yaml()
        def project = yaml.load(source.text)
        if (!(project instanceof Map) || project.schema_version != 1 ||
            !(project.database instanceof Map) || !(project.annotations instanceof List) ||
            !project.annotations) {
            error 'ProtLoom project YAML requires schema_version: 1, database, and annotations'
        }

        def resolvePath = { value, label, required ->
            if (!value?.toString()?.trim()) {
                if (required) error "ProtLoom project YAML is missing ${label}"
                return value
            }
            def candidate = new File(value.toString())
            def resolved = (candidate.isAbsolute() ? candidate :
                new File(source.parentFile, value.toString())).canonicalFile
            if (required && !resolved.isFile()) {
                error "ProtLoom ${label} does not exist: ${resolved}"
            }
            resolved.toString()
        }

        project.database.output_fasta = resolvePath.call(
            project.database.output_fasta, 'database.output_fasta', true)
        project.database.output_entries_tsv = resolvePath.call(
            project.database.output_entries_tsv, 'database.output_entries_tsv', true)
        def annotationIds = [] as Set
        project.annotations.eachWithIndex { row, index ->
            def id = row?.annotation_id?.toString()?.trim()
            if (!id || !annotationIds.add(id)) {
                error "ProtLoom annotations[${index}] needs a unique annotation_id"
            }
            row.gtf_path = resolvePath.call(row.gtf_path,
                "annotations[${index}].gtf_path", true)
            if (row.idmapping_path) {
                row.idmapping_path = resolvePath.call(row.idmapping_path,
                    "annotations[${index}].idmapping_path", false)
            }
        }
        if (project.fasta_sources instanceof List) {
            project.fasta_sources.eachWithIndex { row, index ->
                if (row?.fasta_path) {
                    row.fasta_path = resolvePath.call(row.fasta_path,
                        "fasta_sources[${index}].fasta_path", false)
                }
            }
        }
        project.samples = records.collect { it }.unique { it[0] }.collect { sample, fraction, mzml, annotation, scan ->
            if (!annotationIds.contains(annotation)) {
                error "Sample '${sample}' has annotation_id '${annotation}' absent from the ProtLoom project YAML"
            }
            [sample_id: sample, annotation_id: annotation]
        }
        file("${task.workDir}/protloom-project.generated.yaml").text = yaml.dump(project)
}
