# Changelog

All notable changes to SpectroMesa-DIA are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.6.3] - 2026-11-20

### Added

- Rename the pipeline from `metapipeline-ProteomicDIA` to `SpectroMesa-DIA`. New runs publish to `<output_dir>/SpectroMesa-DIA-<version>/`.
- Update ProteoVault to v0.2.5 and select the DIA importer explicitly when building the vault.

### Changed

- Migrate the metapipeline license from GPL to BSD 3-Clause and update license documentation; shared code and third-party tools retain their respective licenses.
- Update `search-ProteomicDIA` from v0.2.2 to v0.2.3, including the BSD 3-Clause license migration.
- Update `validate-ProteomicPSM` from v2.4.1 to v2.4.3, including BSD 3-Clause licensing, isolated OpenMS temporary directories, and environment-variable expansion in ProtLoom paths.
- Update `generate-ProteomicSpectralLibrary` from v1.1.0 to v1.1.1, including the BSD 3-Clause license migration.
- Update `quantitate-ProteomicDIA` from v1.3.1 to v1.3.2, including the BSD 3-Clause license migration.
- Update `qc-ProteomicDIA` from v1.3.1 to v1.3.2, including the BSD 3-Clause license migration.
- Update `reconstruct-ProteomicMSMS` from v1.0.0 to v1.0.1, including the BSD 3-Clause license migration.
- Update `convert-MSData` from v1.1.3 to v1.1.4, including the BSD 3-Clause license migration.

## [1.6.2] - 2026-11-18

### Added

- Update `qc-ProteomicDIA` to v1.3.1 so Nextflow caches Apptainer images before parallel QC tasks start ([#31](https://github.com/TheBoutrosLab/metapipeline-ProteomicDIA/issues/31)).
- Update `quantitate-ProteomicDIA` to v1.3.1 to use staged filenames in the DIA-NN file list ([#29](https://github.com/TheBoutrosLab/metapipeline-ProteomicDIA/issues/29)) and set an inherited unlimited stack limit to 8 MiB before running DIA-NN ([#30](https://github.com/TheBoutrosLab/metapipeline-ProteomicDIA/issues/30)).
- Update `convert-MSData` to v1.1.3 for ProteoWizard Wine setup under the Apptainer profile.
- Add `NFT_RUN_ROOT` and `NFT_CLUSTER` support to the NFTest runner for AWS Slurm and Pines execution.
- Use compact NFTest work directories to shorten paths passed to DIA-NN on Pines.

## [1.6.1] - 2026-11-13

### Added

- Update the ProteoVault image default to v0.2.3.
- Stage the quantitation manifest for ProteoVault so DIA-NN run names map to biological samples.
- Update `qc-ProteomicDIA` to v1.3.0 for standardized acquisition, identification, inference, and quantification metrics.

## [1.6.0] - 2026-11-12

### Added

- Update the ProteoVault image default to v0.2.2.
- Add `run_proteovault` to skip ProteoVault independently of protein inference.
- Update `qc-ProteomicDIA` to v1.2.1 for per-fraction acquisition QC and sample-level metrics from the aggregated DIA-NN report.
- Update child submodules to `search-ProteomicDIA` v0.2.2, `generate-ProteomicSpectralLibrary` v1.1.0, and `quantitate-ProteomicDIA` v1.3.0, including their new process resource profiles.
- Route multiple fractions per sample through search, validation, per-fraction library generation, and DIA-NN quantitation with sample-level aggregation, including converted mzML fraction suffixes when raw basenames repeat.
- Add an NFTest integration case for fractionated E. coli DIA inputs.

### Fixed

- Avoid the Nextflow 24 compilation error in the fractionated QC manifest process by splitting its command builder into acquisition and sample helpers.
- Schedule QC and ProteoVault for fractionated DIA cohorts and pass sample/fraction acquisitions with the final aggregated DIA-NN report to QC.

## [1.5.0] - 2026-11-09

### Added

- Add `convert-MSData` v1.1.1 for MS data files before DIA search, library generation, quantitation, and QC; route its unprefixed mzML files directly to downstream pipelines while Bruker `.d` acquisitions bypass conversion and continue through diaTracer reconstruction.
- Accept an optional input CSV `scan` column and pass required SCIEX `.wiff.scan` companions to conversion.
- Add an NFTest integration case starting from two E. coli Thermo RAW acquisitions.

## [1.4.0] - 2026-11-03

### Added

- Update `qc-ProteomicDIA` to `v1.2.0` and pass original Bruker `.d` acquisition paths for MS1 and acquisition QC; the QC child now matches DIA-NN run names directly.
- Update `generate-ProteomicSpectralLibrary` to `v1.0.2`, which passes single-run PSM and peak files separately to EasyPQP.
- Add a Bruker dia-PASEF NFTest integration case using the `hela_diapasef` fixture.
- Add `reconstruct-ProteomicMSMS` v1.0.0 for Bruker `.d` acquisitions; route its pseudo-MS/MS mzML to search, validation, spectral library generation, and QC while quantifying the original `.d` data.
- Update `validate-ProteomicPSM` to `v2.4.1` and `quantitate-ProteomicDIA` to `v1.2.0`, including Bruker `.d` input support in the quantitation child, EasyPQP library preparation, and updated resource profiles. The metapipeline accepts Bruker `.d` directories through reconstruction.
- Build a ProteoVault 0.1.0 DuckDB database after QC for ProteinProphet, Fido, and Epifany runs with core, search FASTA, QC, and quant-details layers, publishing it at the versioned metapipeline output root.

### Fixed

- Enable `copy_inputs_to_work` in the Bruker integration test under the correct quantitation namespace.

## [1.3.2] - 2026-10-28

### Added

- Update `qc-ProteomicDIA` to `v1.1.1` for MSBooster PSM counts by missed cleavage, enzyme specificity, and precursor charge.

## [1.3.1] - 2026-10-27

### Fixed

- Update `validate-ProteomicPSM` to `v2.3.2` to correct MSBooster calibration scores for MSFragger, Comet, and Sage.

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

[1.0.0]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/releases/tag/v1.0.0
[1.1.0]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.0.0...v1.1.0
[1.1.1]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.1.0...v1.1.1
[1.2.0]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.1.1...v1.2.0
[1.3.0]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.2.0...v1.3.0
[1.3.1]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.3.0...v1.3.1
[1.3.2]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.3.1...v1.3.2
[1.4.0]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.3.2...v1.4.0
[1.5.0]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.4.0...v1.5.0
[1.6.0]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.5.0...v1.6.0
[1.6.1]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.6.0...v1.6.1
[1.6.2]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.6.1...v1.6.2
[1.6.3]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.6.2...v1.6.3
[unreleased]: https://github.com/TheBoutrosLab/SpectroMesa-DIA/compare/v1.6.3...HEAD
