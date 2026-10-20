# Changelog

All notable changes to metapipeline-ProteomicDIA are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-10-20

### Added
- DIA metapipeline chaining `search-ProteomicDIA` (MSFragger), `validate-ProteomicPSM` (MSBooster, Percolator, ProtLoom), `generate-ProteomicSpectralLibrary` (EasyPQP), and `quantitate-ProteomicDIA` (DIA-NN). Each child pipeline is launched by its own Nextflow process in `module/`.
- Nextflow processes and CSV handoffs for search idXML, unfiltered ProtLoom idXML, cohort PSM and peptide reports, the spectral library TSV, and mzML inputs.
- Input CSV with `sample_name,fraction_id,path`; environment variable expansion for test inputs; template configuration, `.env-template`, and an NFTest integration case for the complete workflow.
- Child pipeline Git submodules and an SVG workflow schematic in `docs/pipeline-flow.svg`.

### Changed
- Child pipeline parameters use the `search_ProteomicDIA`, `validate_ProteomicPSM`, `generate_ProteomicSpectralLibrary`, and `quantitate_ProteomicDIA` namespaces.
- Input validation and output/log directory setup run through `config/methods.config`.
- The current workflow uses `sample_name` as the run name and accepts one mzML per sample. `fraction_id` remains in the input and handoff CSVs for future multi-fraction support.
- NFTest runs from `/scratch/$SLURM_JOB_ID/<test-case>` and accepts a test-case argument, following the proteomic metapipeline convention.
- Versioned child pipeline directories publish directly under `params.final_output_dir`; handoff CSVs publish under its `manifests/` directory.
- Shared database and decoy/contaminant markers are configured at the root parameter level; `methods.setup()` derives child-specific database and decoy parameters and checks ProtLoom YAML markers for consistency.

### Removed
- Starter BAM inputs, example modules, and template pipeline documentation and test files that do not apply to DIA.
