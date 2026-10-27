# metapipeline-ProteomicDIA

This Boutros Lab metapipeline searches DIA mzML files with MSFragger, validates PSMs with MSBooster and Percolator followed by ProtLoom, ProteinProphet, Fido, or Epifany, builds an EasyPQP spectral library, quantifies the cohort with DIA-NN, and summarizes acquisition, identification, library, and quantitation QC.

![DIA metapipeline schematic](docs/pipeline-flow.svg)

## Quick start

1. Initialize the child pipelines and shared Boutros Lab modules:

   ```bash
   git submodule update --init --recursive
   ```

2. Prepare the [mzML input CSV](input/template-mzML.csv), a target-decoy FASTA, and the MSFragger JAR. If selecting ProtLoom, also prepare a [ProtLoom project YAML](config/protloom-project.example.yaml) with the same FASTA and accession markers as the run configuration.
3. Copy [config/template.config](config/template.config) to a run-specific file. Set `input_csv`, `decoy_database`, `msfragger_executable`, `output_dir`, and `dataset_id`. Set `validate_ProteomicPSM.protloom_project_yaml` when using ProtLoom. Review the shared markers and the child-specific settings for your experiment. Keep the template's `includeConfig` lines and final `methods.setup()` call.
4. Run with Nextflow 24.10.6 and its v1 syntax parser. Choose a work directory with enough space for the mzML files and child pipeline work:

   ```bash
   export NXF_VER=24.10.6
   export NXF_SYNTAX_PARSER=v1
   export NXF_WORK=/scratch/$SLURM_JOB_ID/metapipeline-ProteomicDIA-work
   nextflow run main.nf -c /path/to/run.config -profile pines
   ```

The scratch path above is an example for a Slurm job; use another suitable work directory outside Slurm. Select `-profile pines` for a 64 CPU, 500 GB node or `-profile boutroslab_aws` for a 32 CPU, 128 GB node. These profiles set resource budgets, while `child_profile` (`standard` by default) selects the container runtime in each child. Make sure the selected child profile's runtime is available. Nextflow's `-c` option adds the run configuration to the project's configuration; see the [Nextflow configuration documentation](https://www.nextflow.io/docs/latest/config.html).

### Resource profiles

| Profile | Node budget | Parent launch processes | Child allocations |
| --- | --- | --- | --- |
| `pines` | 64 CPUs, 500 GB | 2 CPUs, 4 GB per child launcher | MSFragger search 8 CPUs/64 GB; iProphet 8 CPUs/32 GB; DIA-NN 16 CPUs/96 GB; QC DIA-NN report 2 CPUs/32 GB. |
| `boutroslab_aws` | 32 CPUs, 128 GB | 2 CPUs, 4 GB per child launcher | MSFragger search 8 CPUs/64 GB; iProphet 8 CPUs/32 GB; DIA-NN 16 CPUs/96 GB; QC DIA-NN report 2 CPUs/16 GB. |

Parent CSV, QC manifest, and configuration tasks request 1 CPU and 2 GB in both profiles. Parent child-launch processes request 2 CPUs and 4 GB from [config/resources.json](config/resources.json). Each profile has its own file under [config/resource_profiles](config/resource_profiles), containing its budget and CPU requests for every child process. A process `memory` value is optional: omit it to leave that child's Nextflow memory directive unset. `search_database_MSFragger` is the exception because it uses `task.memory` to size the Java heap. The profile's `max_memory` remains required as a node budget. The parent passes process requests through each child's parameter JSON and a small resource override config, including `qc-ProteomicDIA`. Existing child resource defaults remain in effect when neither profile is selected. A run config can set `base_resource_update` within a child namespace to replace that profile's process requests. These profiles describe node budgets; they do not select a Slurm partition or change the local executor.

For a profile outside the repository, copy [pines.json](config/resource_profiles/pines.json) or [boutroslab_aws.json](config/resource_profiles/boutroslab_aws.json) to a directory you control, rename it `<name>.json`, and edit its budget and allocations. Set these values in your run config:

```groovy
params.compute_profile = 'my_cluster'
params.additional_resource_profile_dir = '/path/to/resource_profiles'
```

Run with `-c /path/to/run.config`; a matching Nextflow `-profile` entry is not required. `additional_resource_profile_dir` can contain multiple directories separated by the operating system's PATH separator (`:` on Linux/macOS). Lookup checks those directories from left to right, then the bundled `config/resource_profiles` directory. Missing directories or missing files in one location are skipped. Relative directories resolve from the launch directory. A profile file found earlier takes precedence over a file of the same name found later. To add a bundled profile, add its name to [config/profiles.config](config/profiles.config) and create `config/resource_profiles/<name>.json`. The shared parent process requests usually do not need to change.

## Inputs

The input CSV has exactly these columns:

```csv
sample_name,fraction_id,annotation_id,path
sample_01,1,reference,/data/sample_01.mzML
sample_02,1,reference,/data/sample_02.mzML
```

| Input | Requirement |
| --- | --- |
| `sample_name` | Unique per row. The current workflow accepts one mzML per sample and uses this name in child pipeline outputs. |
| `fraction_id` | Required nonempty identifier. It is retained in handoff CSVs for future multi-fraction support but is not appended to the sample name. |
| `annotation_id` | Required CSV column. When ProtLoom is enabled, it must match an `annotations[].annotation_id` in its project YAML. |
| `path` | Existing mzML file. Relative paths resolve from the input CSV's directory. mzML paths and basenames must be unique; basenames cannot contain another dot before `.mzML`. |
| `decoy_database` | Existing target-decoy FASTA used by search and validation. |
| `msfragger_executable` | Separately obtained MSFragger JAR. |
| `validate_ProteomicPSM.protloom_project_yaml` | Required only for the ProtLoom route. The metapipeline supplies its `samples` section from the CSV. |

### ProtLoom project YAML

Start from [config/protloom-project.example.yaml](config/protloom-project.example.yaml). Provide `schema_version: 1`, `annotations` with a unique `annotation_id` and existing GTF file for each annotation, and `database.output_fasta` and `database.output_entries_tsv` pointing to existing files. Set the database decoy and contaminant markers to match the root pipeline parameters. Include `fasta_sources` when this YAML also describes the database sources used by ProtLoom `buildDB`; validation uses the built database outputs and annotations.

Do not maintain a `samples` section in this input file. The metapipeline checks each CSV `annotation_id` against `annotations`, writes `protloom-project.generated.yaml` under the output `manifests/` directory, and passes that file to `validate-ProteomicPSM`. If the input YAML contains an older `samples` section, the generated section is replaced with the CSV mapping. Relative database, GTF, and FASTA source paths are resolved against the original YAML location before the generated file is written.

## Parameters

Set shared values once at the root of the run config. `methods.setup()` derives the child-specific database and decoy settings before writing the child parameter JSON files. The ProtLoom project YAML independently supplies its database markers and must agree with the root values.

| Root parameter | Default | Purpose |
| --- | --- | --- |
| `input_csv` | Required | Sample-to-mzML CSV. |
| `decoy_database` | Required | Target-decoy FASTA passed to search and validation. |
| `decoy_string` | `DECOY_` | Decoy accession marker; becomes the MSFragger `decoy_prefix` and validation `decoy_string`. |
| `decoy_position` | `prefix` | Decoy marker position. The current MSFragger search requires `prefix`; validation receives this as `decoy_string_position`. |
| `contam_string` | `CONTAMINANT_` | Contaminant marker; must match `database.contam_string` in the ProtLoom YAML. |
| `contam_position` | `prefix` | Contaminant marker position (`prefix` or `suffix`); must match `database.contam_position` in the ProtLoom YAML. |
| `msfragger_executable` | Required | MSFragger JAR. |
| `output_dir` | Required | Root directory for published results and logs. |
| `dataset_id` | `cohort` | Name of this cohort's result directory. |
| `child_profile` | `standard` | Nextflow profile applied to each child pipeline run. |
| `compute_profile` | Set by `-profile pines` or `-profile boutroslab_aws` | Resource profile name; set directly to select a profile from `additional_resource_profile_dir`. |
| `additional_resource_profile_dir` | None | Optional PATH-style list of directories containing `<compute_profile>.json` files. |

Settings specific to one child belong in its namespace in the run config. The tables below list the parameters relevant to this metapipeline. Values marked **set by metapipeline** are supplied by `methods.setup()` or the child-call process; do not repeat them in a run config. Parent launcher requests are defined in [config/resources.json](config/resources.json), while each child's resource handler controls its internal processes.

### `search_ProteomicDIA` — MSFragger search

The `MSFragger` block uses native `fragger.params` keys. The values below are in [config/template.config](config/template.config); other defaults come from the [search pipeline configuration](external/search-ProteomicDIA/config/default.config).

| `MSFragger` parameter | Template value | Purpose |
| --- | --- | --- |
| `precursor_mass_lower` | `-25` | Lower precursor mass search bound. |
| `precursor_mass_upper` | `25` | Upper precursor mass search bound. |
| `precursor_mass_units` | Child default: `1` | Precursor tolerance units (`1` = ppm). |
| `precursor_true_tolerance` | `4` | Precursor calibration tolerance. |
| `precursor_true_units` | Child default: `1` | Calibration tolerance units (`1` = ppm). |
| `fragment_mass_tolerance` | `50` | Fragment tolerance. |
| `fragment_mass_units` | Child default: `1` | Fragment tolerance units (`1` = ppm). |
| `calibrate_mass` | Child default: `2` | Mass calibration mode. |
| `deisotope` | Child default: `1` | Peak deisotoping mode. |
| `deneutralloss` | Child default: `1` | Neutral-loss peak handling. |
| `isotope_error` | `0/1/2` | Allowed precursor isotope errors. |
| `precursor_mass_mode` | Child default: `selected` | Precursor mass interpretation. |
| `require_precursor` | Child default: `1` | Require precursor evidence. |
| `reuse_dia_fragment_peaks` | Child default: `0` | Whether fragment peaks may match multiple peptides. |
| `fragment_ion_series` | Child default: `b,y` | Fragment ion series. |
| `search_enzyme_name_1` | `stricttrypsin` | Primary enzyme name. |
| `search_enzyme_cut_1` | `KR` | Cleavage residues. |
| `search_enzyme_nocut_1` | Empty | Residues that prevent cleavage. |
| `search_enzyme_sense_1` | `C` | Cleavage terminus. |
| `allowed_missed_cleavage_1` | `2` | Maximum missed cleavages. |
| `num_enzyme_termini` | `2` | Required enzymatic termini. |
| `clip_nTerm_M` | `1` | Permit N-terminal methionine clipping. |
| `variable_mod_01` | `15.9949 M 3` | Methionine oxidation. |
| `variable_mod_02` | `42.0106 [^ 1` | Protein N-terminal acetylation. |
| `allow_multiple_variable_mods_on_residue` | `0` | Multiple variable modifications on one residue. |
| `max_variable_mods_per_peptide` | `3` | Maximum variable modifications per peptide. |
| `output_format` | Child fixed value: `pepXML_pin` | pepXML and PIN needed downstream. |
| `output_report_topN` | `5` | Top PSMs reported per spectrum. |
| `output_max_expect` | Child default: `50` | Maximum expectation value for reported PSMs. |
| `digest_min_length` | `7` | Minimum digested peptide length. |
| `digest_max_length` | `50` | Maximum digested peptide length. |
| `digest_mass_range` | `500.0 5000.0` | Digested peptide mass range in Da. |
| `max_fragment_charge` | `2` | Maximum theoretical fragment charge. |
| `minimum_peaks` | `15` | Minimum spectrum peak count. |
| `use_topN_peaks` | `150` | Maximum experimental peaks retained per spectrum. |
| `min_matched_fragments` | `4` | Minimum matched fragments for a PSM. |
| `add_C_cysteine` | `57.02146` | Fixed cysteine carbamidomethylation mass. |

The child [MSFragger schema](external/search-ProteomicDIA/config/schema.yaml) gives allowed values and validation rules.

### `validate_ProteomicPSM` — MSBooster, Percolator, and protein inference

| Parameter | Template value or source | Purpose |
| --- | --- | --- |
| `run_percolator` | Fixed: `true` | Run MSBooster then Percolator. |
| `percolator_workflow` | Fixed: `msbooster` | Run MSBooster then Percolator. |
| `run_protloom` | Default: `false` | Use ProteinProphet by default; set true for ProtLoom. |
| `protein_inference_algorithm` | Default: `ProteinProphet` | Non-ProtLoom grouping: `ProteinProphet`, `Fido`, or `Epifany` (`Epiphany` alias). |
| `fido_min_probability` | Child default: `0.01` | Minimum Fido group posterior probability for EasyPQP export. |
| `epifany_min_probability` | Child default: `0.01` | Minimum Epifany group posterior probability for EasyPQP export. |
| `epifany_greedy_group_resolution` | Child default: `none` | Optional Epifany shared-peptide resolution: `none`, `remove_associations_only`, or `remove_proteins_wo_evidence`. |
| `docker_image_fido` | Child default: `ghcr.io/theboutroslab/fido:1.0` | Standalone Fido container image. |
| `export_easypqp_reports` | Fixed: `true` | Export cohort PSM and peptide TSVs from the selected route. |
| `merge_consensus` | Fixed: `false` | One search engine and one mzML per sample. |
| `fractionated` | Fixed: `false` | One search engine and one mzML per sample. |
| `protloom_project_yaml` | Required with ProtLoom | Base project YAML with database files, annotation GTFs, and marker settings; samples are generated from the input CSV. |
| `protloom_pc_order` | `proteotypic` | Peptide-class and protein-tier priorities. |
| `protloom_pt_order` | `canonical` | Peptide-class and protein-tier priorities. |
| `protloom_enzyme` | `trypsin` | ProtLoom cleavage rule. |
| `easypqp_psm_qvalue` | `0.01` | Maximum PSM q-value for EasyPQP export in every inference route. |
| `protloom_easypqp_group_qvalue` | `0.01` | Maximum ProtLoom protein-group q-value for EasyPQP export. |
| `protloom_idxml_primary_score` | `pep` | Primary score in unfiltered ProtLoom idXML. |
| `protloom_idxml_unmatched_psms` | `remove` | Handling of PSMs without a ProtLoom match. |
| `protloom_version` | Child default: `0.2.3` | ProtLoom version and container. |
| `docker_image_protloom` | Child default: matching image | ProtLoom version and container. |
| `enzyme` | Child default: `Trypsin` | Enzyme used by peptide indexing and Percolator. |
| `skip_peptide_indexing` | Child default: `false` | Skip OpenMS PeptideIndexer when idXMLs are already indexed. |
| `index_peptides_unmatched_action` | Metapipeline default: `remove` | Handling of peptides absent from the FASTA. |
| `index_peptides_aaa_max` | Metapipeline default: `0` | Maximum ambiguous amino acids for peptide indexing. |
| `index_peptides_missing_decoy_action` | Child/OpenMS defaults | Additional peptide-indexing controls. |
| `index_peptides_mismatches_max` | Child/OpenMS defaults | Additional peptide-indexing controls. |
| `index_peptides_IL_equivalent` | Child/OpenMS defaults | Additional peptide-indexing controls. |
| `msbooster_params` | Child bundled file | MSBooster prediction configuration. |
| `percolator_decoy_pattern` | Defaults to `decoy_string` | Decoy protein pattern used for direct Percolator execution. |
| `percolator_post_processing_tdc` | Child default: `true` | Percolator target-decoy competition after rescoring. |
| `filter_psm_score_peptide` | Child default: `0.01` | Final PSM q-value cutoff. |
| `filter_psm_remove_decoys` | Child default: `true` | Exclude decoys from filtered outputs. |
| `filter_psm_keep_unreferenced_protein_hits` | Child default: `false` | Retain or remove unreferenced hits. |
| `filter_psm_delete_unreferenced_peptide_hits` | Child default: `true` | Retain or remove unreferenced hits. |
| `filter_psm_whitelist_proteins` | Child default: no file | Restrict retained protein or peptide hits. |
| `filter_psm_whitelist_peptides` | Child default: no file | Restrict retained protein or peptide hits. |
| `filter_psm_blacklist_proteins` | Child default: no file | Exclude selected protein or peptide hits. |
| `filter_psm_blacklist_peptides` | Child default: no file | Exclude selected protein or peptide hits. |
| `filter_psm_in_silico_digestion` | Child default: no file | FASTA for digestion-based filtering. |

See the [validation pipeline parameters](external/validate-ProteomicPSM/README.md#config) and [OpenMS option mapping](external/validate-ProteomicPSM/docs/params.rst) for the remaining advanced indexing, filtering, and resource controls.

### `generate_ProteomicSpectralLibrary` — EasyPQP library

| Parameter | Template value or source | Purpose |
| --- | --- | --- |
| `fractionated` | Fixed: `false` | Current workflow accepts one mzML per sample. |
| `idxml_score_type` | `ProtLoom PEP`, or `Posterior Error Probability` when ProtLoom is disabled | Score read from each unfiltered validation idXML hit. |
| `easypqp_score_type` | Metapipeline default: `PEP` | Meaning of the selected score. |
| `easypqp_version` | Child default: `0.1.59` | EasyPQP version and container. |

See the [library pipeline parameter reference](external/generate-ProteomicSpectralLibrary/README.md#inputs).

### `quantitate_ProteomicDIA` — DIA-NN quantitation

| Parameter | Template value or source | Purpose |
| --- | --- | --- |
| `DIA-NN.qvalue` | `0.01` | Main report precursor q-value cutoff. |
| `DIA-NN.matrix_qvalue` | `0.01` | Quantitation matrix q-value cutoff. |
| `DIA-NN.no_ifs_removal` | `true` | Disable fragment interference correction. |
| `DIA-NN.no_prot_inf` | `true` | Disable protein inference for the generated EasyPQP TSV. |

Set these in `quantitate_ProteomicDIA { 'DIA-NN' { ... } }`. The metapipeline passes the generated EasyPQP TSV as the child's `library` input.

See the [quantitation pipeline parameter reference](external/quantitate-ProteomicDIA/README.md#parameters).

### `qc_ProteomicDIA` — cohort quality control

All `qc_ProteomicDIA` parameters are set automatically by the metapipeline from the input mzMLs and preceding pipeline results.

See [config/template.config](config/template.config) for an editable run configuration and [config/schema.yaml](config/schema.yaml) for root parameter validation.

## Pipeline steps and outputs

1. `search-ProteomicDIA` searches each mzML with MSFragger and produces idXML files.
2. `validate-ProteomicPSM` uses MSBooster and Percolator, then ProteinProphet by default, Fido or Epifany when selected, or ProtLoom when `validate_ProteomicPSM.run_protloom = true`. Its unfiltered idXML files and cohort PSM and peptide reports feed the library stage.
3. `generate-ProteomicSpectralLibrary` uses those identifications and the original mzML files to produce an EasyPQP library TSV.
4. `quantitate-ProteomicDIA` quantifies the original mzML files against that library with DIA-NN.
5. `qc-ProteomicDIA` summarizes mzML, search, filtered identifications, protein groups, library, and DIA-NN results across the cohort.

Versioned child pipeline directories and the handoff CSVs are published at:

```text
<output_dir>/metapipeline-ProteomicDIA-1.1.0/<dataset_id>/
├── main_workflow/
│   ├── search-ProteomicDIA-<version>/
│   ├── validate-ProteomicPSM-<version>/
│   ├── generate-ProteomicSpectralLibrary-<version>/
│   ├── quantitate-ProteomicDIA-<version>/
│   ├── qc-ProteomicDIA-1.1.0/
│   └── manifests/
└── log-metapipeline-ProteomicDIA-1.1.0-<timestamp>/
```

The metapipeline creates each stage's input CSV in `manifests/`, including the QC sample and PSM feature manifests. The combined QC table is in `qc-ProteomicDIA-1.1.0/<dataset_id>/output/<dataset_id>_QC_metrics.tsv`, alongside per-sample metric tables, PSM feature summaries when available, and MS1 HTML plots. The child directories contain the scientific results and their own logs. The timestamped metapipeline log directory contains the parent Nextflow reports and effective parameters.

## Testing

The NFTest cases run all five child pipelines using ProtLoom, ProteinProphet, or Epifany for validation. From the repository root, inside a Slurm job, copy `.env-template` to `.env`, set `TEST_DATA_DIR`, and run:

```bash
zsh test/run-nftest.sh test_integration_MSFragger_ProtLoom_DIANN
zsh test/run-nftest.sh test_integration_MSFragger_ProteinProphet_DIANN
zsh test/run-nftest.sh test_integration_MSFragger_Epifany_DIANN
```

The test runner uses `/scratch/$SLURM_JOB_ID/<test-case>` for its work and output. The test CSV and ProtLoom project YAML expand `$TEST_DATA_DIR` through [test/csv_environment_expander.groovy](test/csv_environment_expander.groovy).

## License

This pipeline is licensed under GNU GPL version 2. See [LICENSE](LICENSE).
