# PSM validation and protein grouping

**MSBooster and Percolator** rescore the search results, and OpenMS estimates PSM q-values for each sample. **ProteinProphet** then groups proteins across the cohort by default; **Fido** and **EPIFANY** are alternatives. Those groups are carried into the spectral library and retained during quantitation.

![PSM validation and protein grouping workflow](flowcharts/validation.svg)

[Open the original flowchart at full size](flowcharts/validation.svg).

The original diagram also includes standalone analysis routes. The steps below describe the route used by SpectroMesa-DIA.

## How it works

1. Match peptide sequences to the target-decoy FASTA with PeptideIndexer, checking their protein associations and target/decoy labels.
2. Export PSM features, add MSBooster prediction-based features, and run Percolator. Import its posterior error probabilities (PEPs) into the identification files.
3. Estimate sample-level PSM q-values and filter the identification output. The default maximum q-value is `0.01`.
4. Use the unfiltered rescored evidence across samples to infer protein groups. ProteinProphet uses an iProphet/ProteinProphet route; Fido and EPIFANY use their respective probabilistic grouping methods.
5. Export accepted PSMs and peptide-to-protein-group assignments for [library generation](library.md). This export has its own PSM q-value cutoff, also `0.01` by default.

The filtered idXML and mzTab outputs help you inspect accepted identifications. The library export combines the q-value-qualified PSM evidence with the selected cohort protein groups; it is not simply a conversion of the filtered idXML file.

## Inputs and outputs

Inputs are sample-level search idXML files, the matching mzML acquisitions, and the same FASTA used for searching. SpectroMesa-DIA prepares their manifests automatically.

Outputs include rescored identification evidence, filtered idXML and mzTab files, cohort protein groups, EasyPQP PSM and peptide reports, and an export summary. See [Understanding results](../results.md) for the files most useful to inspect.

!!! important "A group probability is not an FDR cutoff"
    `proteinprophet_min_probability` is already `0.0`; `fido_min_probability` and `epifany_min_probability` are `0.01`. These are minimum group probabilities for export. A value of `0.01` does **not** mean a 1% protein-group FDR.

## Validation settings

Set parameters inside `validate_ProteomicPSM`. Only the chosen grouping method’s probability settings apply. SpectroMesa-DIA fixes the rescoring route to MSBooster plus Percolator and disables multi-engine consensus. Settings for the standalone OpenMS Percolator or consensus routes are listed separately and have no effect on this workflow.

## Parameter reference

Use the `validate_ProteomicPSM` block inside `params` in your run configuration. Values below describe this step as used by SpectroMesa-DIA. Settings marked automatically supplied do not need to be repeated.

### Analysis settings

| Parameter | Type | Default / supplied value | Meaning |
| --- | --- | --- | --- |
| `skip_peptide_indexing` | Boolean | false | Skip matching peptides to the FASTA. Leave false so protein associations and target/decoy labels are checked. |
| `msbooster_params` | Path | Bundled input/msbooster.params | MSBooster prediction configuration. The bundled file uses DIA-NN predictions to add features for rescoring. |
| `protein_inference_algorithm` | Text | ProteinProphet | Choose ProteinProphet, Fido, or Epifany (EPIFANY). Only the selected method’s probability settings apply. |
| `fido_min_probability` | Number | 0.01 | Minimum Fido group probability retained in the library export. This is a probability, not an FDR cutoff. |
| `epifany_min_probability` | Number | 0.01 | Minimum EPIFANY group probability retained in the library export. This is a probability, not an FDR cutoff. |
| `epifany_greedy_group_resolution` | Text | none | Resolve shared-peptide associations: none, remove_associations_only, or remove_proteins_wo_evidence. Applies only to EPIFANY. |
| `proteinprophet_min_probability` | Number | 0.0 | Minimum ProteinProphet group probability retained in the library export; 0 applies no additional probability cutoff. |
| `easypqp_psm_qvalue` | Number | 0.01 | Maximum PSM q-value admitted to the library export, independently of the filtered identification files. |
| `save_intermediate_files` | Boolean | false | Publish additional intermediate files for inspection. Final outputs and execution logs are retained independently. |
| `enzyme` | Text | Trypsin | OpenMS digestion-enzyme name for validation. Keep its cleavage rule consistent with the search settings. |

### Peptide indexing

| Parameter | Type | Default / supplied value | Meaning |
| --- | --- | --- | --- |
| `index_peptides_enzyme_specifity` | Choice | Not set; tool default | Required enzyme specificity during peptide-to-protein matching. The spelling of this setting follows the pipeline option name. |
| `index_peptides_missing_decoy_action` | Choice | Not set; tool default | Action when no decoy assignments are found: error, warn, or silent. Investigate the database and marker if this occurs. |
| `index_peptides_aaa_max` | Number | 0 | Maximum ambiguous amino acids allowed when matching peptides to the FASTA. Already 0 in SpectroMesa-DIA. |
| `index_peptides_mismatches_max` | Number | Not set; tool default | Maximum amino-acid mismatches allowed during peptide-to-protein matching. Increasing this can substantially increase runtime. |
| `index_peptides_unmatched_action` | Choice | remove | Action for peptides that cannot be matched to the FASTA: error, warn, or remove. SpectroMesa-DIA already selects remove. |
| `allow_nterm_protein_cleavage` | Text | Not set; tool default | Permit protein N-terminal cleavage during peptide indexing; passed to PeptideIndexer. |
| `index_peptides_IL_equivalent` | Boolean | false (flag omitted) | Treat the isobaric amino acids isoleucine ('I') and leucine ('L') as equivalent (indistinguishable). Also occurrences of 'J' will be treated as 'I' thus avoiding ambiguous matching. |
| `index_peptides_write_protein_sequence` | Boolean | false (flag omitted) | If set, the protein sequences are stored as well. |
| `index_peptides_write_protein_description` | Boolean | false (flag omitted) | If set, the protein description is stored as well. |
| `index_peptides_keep_unreferenced_proteins` | Boolean | false (flag omitted) | If set, protein hits which are not referenced by any peptide are kept. |

### PSM q-values and filtering

| Parameter | Type | Default / supplied value | Meaning |
| --- | --- | --- | --- |
| `filter_psm_remove_decoys` | Boolean | true | Remove decoy identifications from the filtered output. |
| `filter_psm_keep_unreferenced_protein_hits` | Boolean | false | Retain protein hits with no remaining peptide evidence in the filtered output. |
| `filter_psm_delete_unreferenced_peptide_hits` | Boolean | true | Remove peptide hits that no longer refer to a retained protein. |
| `fdr_algorithm_no_qvalues` | Boolean | false | Use raw FDR estimates instead of q-values. Leave false for the documented q-value thresholds. |
| `filter_psm_whitelist_proteins` | Path | Disabled | Optional FASTA defining proteins whose matching peptides may be retained. |
| `filter_psm_whitelist_peptides` | Path | Disabled | Optional idXML defining peptide sequences to retain. |
| `filter_psm_blacklist_proteins` | Path | Disabled | Optional FASTA defining proteins whose matching peptides should be removed. |
| `filter_psm_blacklist_peptides` | Path | Disabled | Optional idXML defining peptide sequences to remove. |
| `filter_psm_in_silico_digestion` | Path | Disabled | Optional FASTA for filtering peptide hits against an in-silico digest. |
| `filter_psm_score_peptide` | Number | 0.01 | Maximum PSM q-value for the filtered identification output with the default q-value scoring. Despite its name, this is passed to IDFilter as -score:psm. |
| `fdr_algorithm_conservative` | Choice | Not set; tool default | Select the conservative target-decoy FDR calculation. This value-taking option uses the text true or false. |
| `fdr_algorithm_use_all_hits` | Boolean | false (flag omitted) | If 'true' not only the first hit, but all are used (peptides only) |
| `fdr_algorithm_treat_runs_separately` | Boolean | false (flag omitted) | If 'true' different search runs are treated separately (for peptides of combined target/decoy searches only). |
| `fdr_algorithm_split_charge_variants` | Boolean | false (flag omitted) | If 'true' charge variants are treated separately (for peptides of combined target/decoy searches only). |
| `filter_psm_precursor_rt` | Text | Not set; tool default | Retain PSMs within a retention-time range, written as min:max in seconds; either bound may be omitted. |
| `filter_psm_precursor_mz` | Text | Not set; tool default | Retain PSMs within a precursor m/z range, written as min:max. |
| `filter_psm_precursor_length` | Text | Not set; tool default | Retain peptides within a sequence-length range, written as min:max. |
| `filter_psm_precursor_charge` | Text | Not set; tool default | Retain PSMs within a precursor-charge range, written as min:max. |
| `filter_psm_whitelist_protein_accessions` | Text | Not set; tool default | Space-separated protein accessions; retain peptide hits referencing at least one listed accession. |
| `filter_psm_whitelist_modifications` | Text | Not set; tool default | Space-separated OpenMS modification names; retain peptides containing at least one selected modification. |
| `filter_psm_whitelist_ignore_modifications` | Text | Not set; tool default | Compare whitelist peptides by sequence alone. This value-taking option uses the text true or false. |
| `filter_psm_blacklist_protein_accessions` | Text | Not set; tool default | Space-separated protein accessions; remove peptide hits referencing any listed accession. |
| `filter_psm_blacklist_modifications` | Text | Not set; tool default | Space-separated OpenMS modification names; remove peptides containing any selected modification. |
| `filter_psm_blacklist_ignore_modifications` | Text | Not set; tool default | Compare blacklist peptides by sequence alone. This value-taking option uses the text true or false. |
| `filter_psm_number_of_missed_cleavages` | Text | Not set; tool default | Allowed missed-cleavage range for IDFilter, using the configured validation enzyme. |
| `filter_psm_best_n_spectra` | Integer | Not set; tool default | Keep the specified number of best-scoring spectra; 0 leaves this limit disabled. |
| `filter_psm_best_n_peptide_hits` | Integer | Not set; tool default | Keep at most this many peptide hits per spectrum; 0 leaves this limit disabled. |
| `filter_psm_best_n_protein_hits` | Integer | Not set; tool default | Keep at most this many protein hits; 0 leaves this limit disabled. |
| `filter_psm_best_strict` | Boolean | false (flag omitted) | Keep only the highest-scoring peptide hit. |
| `filter_psm_var_mods` | Boolean | false (flag omitted) | Retain only peptide hits with a variable modification recorded in the search parameters. |
| `filter_psm_remove_shared_peptides` | Boolean | false (flag omitted) | Retain only peptides matching one protein accession; separate isoforms count as separate proteins. |

### Standalone-only options

These options belong to alternate routes in the individual pipeline. SpectroMesa-DIA does not run those routes, so changing these settings here has no effect.

| Parameter | Type | Default / supplied value | Meaning |
| --- | --- | --- | --- |
| `percolator_decoy_pattern` | Text | Not set; tool default | Decoy accession pattern for the standalone OpenMS PercolatorAdapter route. |
| `percolator_peptide_level_fdrs` | Boolean | false (flag omitted) | Calculate peptide-level FDRs in the standalone OpenMS PercolatorAdapter route. |
| `percolator_protein_level_fdrs` | Boolean | false (flag omitted) | Calculate protein-level FDRs in the standalone OpenMS PercolatorAdapter route. |
| `percolator_post_processing_tdc` | Boolean | true | Enable target-decoy competition in the standalone OpenMS Percolator route. Not used by the selected MSBooster route. |
| `consensusid_rt_delta` | Number | Not set; tool default | [idXML input only] Maximum allowed retention time deviation between identifications belonging to the same spectrum. |
| `consensusid_mz_delta` | Number | Not set; tool default | [idXML input only] Maximum allowed precursor m/z deviation between identifications belonging to the same spectrum. |
| `consensusid_considered_hits` | Number | Not set; tool default | The number of top hits in each ID run that are considered for consensus scoring ('0' for all hits). |
| `consensusid_min_support` | Number | Not set; tool default | For each peptide hit from an ID run, the fraction of other ID runs that must support that hit (otherwise it is removed). |
| `consensusid_keep_old_scores` | Boolean | false (flag omitted) | If set, keeps the original scores as user params |
| `consensusid_count_empty` | Boolean | false (flag omitted) | Count empty ID runs (i.e. those containing no peptide hit for the current spectrum) when calculating 'min_support'? |
| `consensusid_algorithm` | Text | Not set | ConsensusID algorithm for standalone multi-engine analyses; automatically PEPMatrix with Percolator or ranks without it. Not used here. |

### Software and containers

These defaults record the software environment. When replacing an image, check its compatibility with the workflow; a version label alone does not guarantee the required tools are installed.

| Parameter | Type | Default / supplied value | Meaning |
| --- | --- | --- | --- |
| `fragpipe_version` | Text | 24.0 | FragPipe image version, default 24.0. |
| `docker_image_fragpipe` | Text | fcyucn/fragpipe:24.0 | Container image used for fragpipe. Change only when using a compatible replacement image. |
| `docker_image_fido` | Text | ghcr.io/theboutroslab/fido:1.0 | Container image used for fido. Change only when using a compatible replacement image. |
| `openms_version` | Text | 3.5.0 | Version tag used for this tool’s output naming and default container selection. |
| `docker_image_openms` | Text | ghcr.io/theboutroslab/openms-thirdparty:3.5.0 | Container image used for openms. Change only when using a compatible replacement image. |
| `pyopenms_version` | Text | 3.5.0 | Version tag used for this tool’s output naming and default container selection. |
| `docker_image_pyopenms` | Text | ghcr.io/theboutroslab/pyopenms:3.5.0 | Container image used for pyopenms. Change only when using a compatible replacement image. |

### Automatically supplied settings

| Parameter | Type | Default / supplied value | Meaning |
| --- | --- | --- | --- |
| `input_csv` | Path | Generated search-result manifest | CSV containing sample_name, search_engine, and idXML columns. |
| `input_mzml_csv` | Path | Generated mzML manifest | CSV containing sample_name, fraction, and mzML columns; required for MSBooster or EasyPQP export. |
| `output_dir` | Path | Assigned within the analysis output | Destination for this step. Set the shared output_dir for the complete analysis. |
| `decoy_database` | Path | Shared decoy_database | Target-decoy FASTA used for peptide indexing. |
| `decoy_string` | Text | Shared decoy_string | Accession prefix identifying decoy proteins in the search database. |
| `merge_consensus` | Boolean | Fixed: false | Combine results from multiple search engines using ConsensusID. Disabled here because this workflow uses MSFragger. |
| `fractionated` | Boolean | Detected from the acquisition manifest | Handle multiple fractions. SpectroMesa-DIA sets this from the fraction identifiers in your input CSV. |
| `run_percolator` | Boolean | Fixed: true | Rescore PSMs with Percolator. SpectroMesa-DIA always enables this step. |
| `percolator_workflow` | Text | Fixed: msbooster | MSBooster supplies features for Percolator. The standalone pipeline also offers openms; the metapipeline selects msbooster. |
| `dataset_id` | Text | Shared dataset_id | Analysis name used to organize and name outputs. |
| `export_easypqp_reports` | Boolean | Fixed: true | Export the accepted PSMs and peptide-to-protein-group assignments needed for library generation. Always enabled here. |
| `decoy_string_position` | Choice | Shared decoy_position | Location of the decoy marker; SpectroMesa-DIA requires prefix decoys. |

### Computing and temporary files

The [shared parameter reference](../parameters.md#computing-and-temporary-files) describes CPU, memory, work-directory, and container-cache settings. This pipeline declares: `ucla_cds`, `work_dir`, `base_resource_update`, `max_cpus`, `max_memory`, `min_cpus`, `min_memory`, `resource_allocation_profile_tag`.

The tables were checked against the [individual pipeline configuration](https://github.com/TheBoutrosLab/pipeline-validate-ProteomicPSM/tree/4b7f25c9f09b4696fdde338e02ec10134b27ffea/config) and the SpectroMesa-DIA settings that select this workflow. Additional OpenMS options listed above are forwarded by the corresponding tool modules; “tool default” means the workflow leaves the value to the installed OpenMS version.

## Related steps

[Overview](../overview.md) · [Shared parameters](../parameters.md) · [Configuring an analysis](../configuration.md)

## References

- [MSBooster (2023)](https://doi.org/10.1038/s41467-023-40129-9).
- [Percolator (2007)](https://doi.org/10.1038/nmeth1113).
- [ProteinProphet (2003)](https://doi.org/10.1021/ac0341261).
- [Fido (2010)](https://doi.org/10.1021/pr100594k).
- [EPIFANY (2020)](https://doi.org/10.1021/acs.jproteome.9b00566).
