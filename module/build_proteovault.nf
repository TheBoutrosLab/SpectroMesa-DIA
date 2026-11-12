process build_proteovault {
    container params.docker_image_proteovault
    publishDir "${params.metapipeline_output_dir}", mode: 'copy', pattern: '*.proteovault.duckdb'

    input:
        path searchDir
        path validationDir
        path libraryDir
        path quantDir
        path qcDir
        path databaseFasta

    output:
        path("${params.dataset_id}.proteovault.duckdb"), emit: database

    script:
        def finalRoot = new File(params.final_output_dir.toString()).parentFile.parentFile.canonicalPath
        def versionDirectory = new File(finalRoot).name
        """
        set -euo pipefail
        source_root="\$PWD/source/${versionDirectory}"
        workflow_root="\$source_root/${params.dataset_id}/main_workflow"
        mkdir -p "\$workflow_root"
        for input_dir in '${searchDir}' '${validationDir}' '${libraryDir}' '${quantDir}' '${qcDir}'; do
            ln -s "\$(realpath "\$input_dir")" "\$workflow_root/\$(basename "\$input_dir")"
        done
        vault="\$PWD/${params.dataset_id}.proteovault.duckdb"
        fasta="\$(realpath '${databaseFasta}')"
        proteovault build --pipeline-output "\$source_root" --fasta "\$fasta" --output "\$vault"
        proteovault validate "\$vault"
        """
}
