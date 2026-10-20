import groovy.json.JsonOutput

process create_config_json {
    input:
        tuple val(name), val(options)
    output:
        tuple val(name), path("${name}.json"), emit: config
    exec:
        file("${task.workDir}/${name}.json").text =
            JsonOutput.prettyPrint(JsonOutput.toJson(
                (options ?: [:]).findAll { key, value -> key != 'subworkflow_cpus' }
            ))
}
