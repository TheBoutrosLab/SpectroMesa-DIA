# Changelog

All notable changes to metapipeline-ProteomicDIA are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-10-27

### Added

- Update `validate-ProteomicPSM` to `v2.3.1`, which publishes Percolator PIN and PSM feature files for downstream QC.
- Update `qc-ProteomicDIA` to `v1.1.0` and pass a generated PSM feature manifest for the new QC metrics.

## [1.2.0] - 2026-10-26

### Added

- Add `qc-ProteomicDIA` v1.0.0 as a fifth child pipeline, with automatic stage manifests, inference-route handoff, resource profiles, and published cohort QC results.

## [1.1.1] - 2026-10-25

### Added

- Update `validate-ProteomicPSM` to `v2.3.0` and allocate resources for its ProteinProphet enzyme-rule extraction and pepXML termini repair processes.

## [1.1.0] - 2026-10-25

### Added

- Set ProteinProphet as the default validation protein-grouping route; ProtLoom remains available by explicit selection.
- Update child pipeline Git submodules: `search-ProteomicDIA` to `v0.1.1`, `validate-ProteomicPSM` to `v2.2.2`, `generate-ProteomicSpectralLibrary` to `v1.0.1`, and `quantitate-ProteomicDIA` to `v1.1.0`.
- Add Fido and Epifany grouping, aligned resource mappings and EasyPQP handoffs, shared PSM and separate ProtLoom group q-value cutoffs, and Epifany shared-peptide resolution.
- Skip ProtLoom project generation when ProtLoom is disabled.
- Add an Epifany end-to-end NFTest case without ProtLoom.
- Input CSV annotation IDs and automatic ProtLoom sample mappings in a published project YAML, with a sample-free example configuration and test-local YAML environment expansion.
- Add support for the quantitation pipeline's `library` input and nested DIA-NN options, and resource entries for validation's ProteinProphet processes.
- Optional per-process memory in custom resource profiles; omitted values leave the child Nextflow memory directive unset.
- A ProteinProphet validation route and end-to-end NFTest case that builds the EasyPQP library without ProtLoom.

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

[1.0.0]: https://github.com/TheBoutrosLab/metapipeline-ProteomicDIA/releases/tag/v1.0.0
[1.1.0]: https://github.com/TheBoutrosLab/metapipeline-ProteomicDIA/compare/v1.0.0...v1.1.0
[1.1.1]: https://github.com/TheBoutrosLab/metapipeline-ProteomicDIA/compare/v1.1.0...v1.1.1
[1.2.0]: https://github.com/TheBoutrosLab/metapipeline-ProteomicDIA/compare/v1.1.1...v1.2.0
[1.3.0]: https://github.com/TheBoutrosLab/metapipeline-ProteomicDIA/compare/v1.2.0...v1.3.0
[unreleased]: https://github.com/TheBoutrosLab/metapipeline-ProteomicDIA/compare/v1.3.0...HEAD
