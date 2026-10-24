import groovy.json.JsonOutput

process create_config_json {
    input:
        tuple val(name), val(options), val(withoutMemory)
    output:
        tuple val(name), path("${name}.json"), path("${name}-resources.config"), emit: config
    exec:
        file("${task.workDir}/${name}.json").text =
            JsonOutput.prettyPrint(JsonOutput.toJson(
                (options ?: [:])
            ))
        def overrides = withoutMemory.collect { processName ->
            "    withName: '${processName}' { memory = null }"
        }.join('\n')
        file("${task.workDir}/${name}-resources.config").text =
            overrides ? "process {\n${overrides}\n}\n" : '// No memory overrides\n'
}
