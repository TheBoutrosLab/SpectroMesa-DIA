# Shared parameters

Use this page to find a setting and see where it belongs in your run configuration. Each page in the pipeline reference keeps its explanation, inputs and outputs, and parameter tables together, with the original flowchart where available.

| Pipeline | What it does |
| --- | --- |
| [convert-MSData](pipelines/conversion.md) | Prepare vendor files as mzML |
| [reconstruct-ProteomicMSMS](pipelines/reconstruction.md) | Reconstruct search spectra from Bruker `.d` data |
| [search-ProteomicDIA](pipelines/search.md) | Identify candidate peptide-spectrum matches |
| [validate-ProteomicPSM](pipelines/validation.md) | Estimate identification confidence and assign protein groups |
| [generate-ProteomicSpectralLibrary](pipelines/library.md) | Prepare the library for quantitation |
| [quantitate-ProteomicDIA](pipelines/quantitation.md) | Measure peptides and proteins with DIA-NN |
| [qc-ProteomicDIA](pipelines/qc.md) | Summarize acquisitions and analysis results |
| [ProteoVault](pipelines/proteovault.md) | Package the results as a ProteoVault DuckDB database |

## Reading the reference

The tables describe the pipeline settings for the ProteinProphet, Fido, and EPIFANY workflows documented on this site. Defaults are those used by SpectroMesa-DIA, including its overrides of individual pipeline defaults. Explicit differences in the run template are labeled. Automatically supplied values are listed separately: SpectroMesa-DIA creates the intermediate file lists and passes results between steps for you.

Parameters declared by the pipeline configuration and additional OpenMS options forwarded by the validation modules are included. DIA-NN also accepts additional version-specific command options; its page documents all options set by this workflow and explains how to add others. Generated internal paths and inactive development options are not configuration tasks for users.

Start with [Configuring an analysis](configuration.md) for a guided setup. Put shared settings directly inside `params`, and step-specific settings in their corresponding block. For example, this fragment changes the grouping method to Fido:

```groovy
params {
    validate_ProteomicPSM {
        protein_inference_algorithm = 'Fido'
    }
}
```

Add changes to your copied `run.config` before its final `methods.setup()` line. Preserve the setup statements, as described in the configuration guide.

## Inputs and analysis identity

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `input_csv` | Path | Required | Acquisition CSV with sample, fraction, annotation, and existing acquisition paths. See [Preparing inputs](inputs.md). |
| `decoy_database` | Path | Required | Target-decoy FASTA, preferably including contaminant sequences. |
| `msfragger_executable` | Path | Required | Separately obtained MSFragger JAR. |
| `output_dir` | Path | Required | Root directory for published results. Separate from Nextflow's work directory. |
| `dataset_id` | Text | `cohort` | Name used for the analysis directory, reports, and results database. Choose a distinct name for each analysis. |
| `decoy_string` | Text | `DECOY_` | Decoy accession marker; must match the FASTA. Shared with search and validation. |
| `decoy_position` | Text | `prefix` | Position of the decoy marker. The current MSFragger workflow requires `prefix`. |
| `contam_string` | Text | `CONTAMINANT_` | Contaminant accession marker. Record the marker used in your FASTA; the input-guide example uses `CONTAM_`. This setting does not itself remove contaminants from quantitation. |
| `contam_position` | Text | `prefix` | Position of the contaminant marker: `prefix` or `suffix`. |

## Bruker diaPASEF inputs

These shared settings are needed only for the reconstruction route. See [Installation](installation.md#additional-files-for-bruker-diapasef-data) for the files to obtain.

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `diatracer_executable` | Path | Empty; required for `.d` input | Separately obtained diaTracer JAR. |
| `bruker_lib_dir` | Path | Empty; required for `.d` input | MSFragger `ext/bruker` directory containing `libtimsdata-2-21-0-4.so`. |
| `reconstruct_nextflow_version` | Text | `25.10.5` | Nextflow runtime selected automatically for reconstruction. It is separate from the runtime launching the analysis. |

The [reconstruction page](pipelines/reconstruction.md#parameter-reference) lists diaTracer's scientific settings.

## Computing and temporary files

| Parameter | Where to set it | Default | Meaning |
| --- | --- | --- | --- |
| `child_profile` | Shared | `standard` | Container profile for the individual steps. Match the launch profile: normally `docker` or `apptainer`. `standard` uses Docker; `local` requires the software installed on the host. |
| `compute_profile` | Shared | Empty | Named resource plan. Bundled plans are `pines` and `boutroslab_aws`; use one only when it matches the allocated machine. |
| `additional_resource_profile_dir` | Shared | Empty | Colon-separated directories containing custom resource-plan JSON files, searched before bundled profiles. |
| `max_cpus` | Shared or per step | Available CPUs, unless a compute profile sets a limit | CPU limit used when calculating task allocations. This is not a request to a cluster scheduler. |
| `max_memory` | Shared or per step | Available memory, unless a compute profile sets a limit | Memory limit used for task allocations; write values with units, such as `'64 GB'`. |
| `min_cpus` | Per step | `1` | Lower bound for task CPU allocations. |
| `min_memory` | Per step | `1 MB` | Lower bound for task memory allocations. Actual tasks use their process-specific resource settings. |
| `resource_allocation_profile_tag` | Per step | `default` | Process-allocation profile within the individual pipeline. Keep `default`; named machine plans are selected with shared `compute_profile`. |
| `base_resource_update.cpus` | Per step | Not set | List of process selections and CPU multipliers applied to that step's base allocations. |
| `base_resource_update.memory` | Per step | Not set | List of process selections and memory multipliers applied to that step's base allocations. |
| `work_dir` | Per step | A work directory assigned within the analysis task | Optional override of that step's temporary-file directory. Normally manage the overall work location with Nextflow's `-work-dir` launch option. |
| `apptainer_cache` | Per step where declared | Not set | Optional Nextflow Apptainer image-cache directory. |
| `apptainer_library` | Per step where declared | Not set | Optional directory of existing Apptainer images. |
| `singularity_cache` | Per step where declared | Not set | Optional Nextflow Singularity image-cache directory for pipelines supporting that runtime. |
| `singularity_library` | Per step where declared | Not set | Optional directory of existing Singularity images. |
| `ucla_cds` | Shared or per step where declared | `false` | Legacy environment compatibility setting. Leave false for the documented execution setup. |

Each pipeline page lists the common settings it declares. Shared `max_cpus` and `max_memory` do not automatically replace every step's limits unless a compute profile applies them. For manual control, set limits in the relevant step's block as well. A compute profile assigns limits across all steps.

Resource updates use multipliers, not absolute CPU or memory values. For example, this fragment doubles the search task's base memory, subject to `max_memory`:

```groovy
params {
    search_ProteomicDIA {
        base_resource_update {
            memory = [['search_database_MSFragger', 2]]
        }
    }
}
```

Keep the same persistent work directory when resuming an analysis. The [running and resuming guide](execution.md) explains the launch command and the current stage-level resume behavior.

## Results database

`run_proteovault` is already `true`. The [results database reference](pipelines/proteovault.md#parameter-reference) lists this switch and the ProteoVault version and container settings. You do not need a separate input list for database creation.
