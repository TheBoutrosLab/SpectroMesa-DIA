# Changelog

All notable changes to metapipeline-ProteomicDIA are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-10-20

### Added
- DIA metapipeline chaining `search-ProteomicDIA` (MSFragger), `validate-ProteomicPSM` (MSBooster, Percolator, ProtLoom), `generate-ProteomicSpectralLibrary` (EasyPQP), and `quantitate-ProteomicDIA` (DIA-NN). Each child pipeline is launched by its own Nextflow process in `module/`.
- Nextflow processes and CSV handoffs for search idXML, unfiltered ProtLoom idXML, cohort PSM and peptide reports, the spectral library TSV, and mzML inputs.
- Input CSV with `sample_name,fraction_id,path`; environment variable expansion for test inputs; template configuration, `.env-template`, and an NFTest integration case for the complete workflow.
- Child pipeline Git submodules and an SVG workflow schematic in `docs/pipeline-flow.svg`.
- Child pipeline parameter namespaces: `search_ProteomicDIA`, `validate_ProteomicPSM`, `generate_ProteomicSpectralLibrary`, and `quantitate_ProteomicDIA`.
- Input validation and output/log directory setup in `config/methods.config`.
- One-mzML-per-sample run naming with `sample_name`; `fraction_id` remains in input and handoff CSVs for future multi-fraction support.
- An NFTest runner that uses `/scratch/$SLURM_JOB_ID/<test-case>` and accepts a test-case argument, following the proteomic metapipeline convention.
- Versioned child pipeline directories under `params.final_output_dir` and handoff CSVs under its `manifests/` directory.
- Root-level shared database and decoy/contaminant markers, with child-specific values derived by `methods.setup()` and checked against the ProtLoom YAML.
