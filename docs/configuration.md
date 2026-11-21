# Configuring an analysis

Your run configuration tells SpectroMesa-DIA where to find your inputs, how to analyze them, and where to save the results. Start from the supplied template, fill in your paths, and review the scientific settings for your experiment. This guide focuses on the settings you are most likely to change. For the full parameter tables and an explanation of each step, see the [pipeline reference](parameters.md).

## Create a run configuration

Create a dedicated directory for your analysis and copy the installed pipeline's template into it. Replace these example paths with your own:

```bash
mkdir -p /project/analyses/human_dia_cohort
cd /project/analyses/human_dia_cohort
cp /path/to/SpectroMesa-DIA/config/template.config run.config
```

Use this analysis directory when launching and resuming the run. Nextflow finds the pipeline through the path supplied to `nextflow run`, so you can keep the pipeline installation separate.

Open `run.config` in a text editor. Shared settings, such as `input_csv` and `output_dir`, belong directly inside `params`. The template groups the remaining settings by analysis step. Edit search settings in the `MSFragger` block under `search_ProteomicDIA`, and protein grouping settings under `validate_ProteomicPSM`.

Values in quotes are text, `true` and `false` are switches, and lines beginning with `//` are comments. The template supplies starting analysis settings. The [search reference](pipelines/search.md#search-settings) identifies the peak-count setting that differs from the underlying default. Fill in your paths and change settings where your experiment requires it. The examples below show the matching blocks in your copied file.

!!! important "Keep the template's setup statements"
    Preserve the `includeConfig` statements at the top and the final `methods.setup()` call. They load the defaults and check that your configuration is ready to use. Place your parameter changes before `methods.setup()`.

## Set inputs and outputs

Use full paths for files and directories in the run configuration so their meaning does not depend on where you launch the analysis.

| Setting | What to provide |
| --- | --- |
| `input_csv` | Your acquisition CSV, with valid paths to the mass spectrometry data. |
| `decoy_database` | The combined target-decoy FASTA, including contaminants if you added them. |
| `msfragger_executable` | The full path to the MSFragger JAR. |
| `output_dir` | The directory in which to save published results and logs. |
| `dataset_id` | A name for this analysis, such as `human_dia_cohort`. The default is `cohort`; change it if you want a more descriptive name. |

Check that `decoy_string`, `decoy_position`, `contam_string`, and `contam_position` match your FASTA. The defaults use `DECOY_` and `CONTAMINANT_`, both as prefixes. Change only the values that differ from your database; the input guide uses `CONTAM_`, so that example requires `contam_string = 'CONTAM_'`. The [database preparation guide](inputs.md#match-the-database-markers-in-your-run-configuration) shows a matching MSPtools command and configuration.

For Bruker `.d` input, also set `diatracer_executable` to the diaTracer JAR and `bruker_lib_dir` to the MSFragger `ext/bruker` directory. See [Installation](installation.md#additional-files-for-bruker-diapasef-data) for the required files.

Published analysis results are organized under:

```text
<output_dir>/SpectroMesa-DIA-<version>/<dataset_id>/main_workflow/
```

Execution logs are stored alongside `main_workflow`. Nextflow's work directory holds intermediate task files and is configured separately when launching the analysis; allow space for both work files and published results.

## Configure identification and protein grouping

### Digestion and modifications

Review the `search_ProteomicDIA { MSFragger { ... } }` block against your sample preparation. The supplied template uses the following settings:

| Setting | Template value | Meaning |
| --- | --- | --- |
| `search_enzyme_name_1` | `'stricttrypsin'` | The search enzyme name. |
| `search_enzyme_cut_1` | `'KR'` | Cleavage at lysine or arginine. |
| `search_enzyme_nocut_1` | `''` | No following residue blocks cleavage in this configuration. |
| `search_enzyme_sense_1` | `'C'` | Cleavage on the C-terminal side. |
| `allowed_missed_cleavage_1` | `2` | Allowed missed cleavages. |
| `num_enzyme_termini` | `2` | Require two enzymatic termini. |
| `add_C_cysteine` | `57.02146` | Fixed cysteine carbamidomethylation. |
| `variable_mod_01` | `'15.9949 M 3'` | Variable methionine oxidation. |
| `variable_mod_02` | `'42.0106 [^ 1'` | Variable protein N-terminal acetylation. |
| `max_variable_mods_per_peptide` | `3` | Maximum variable modifications per peptide. |

These are starting settings, not assumptions the pipeline can infer from your data. For example, review the fixed cysteine modification if your preparation used a different alkylation chemistry. If you change the enzyme, review all of its cleavage settings together and set `validate_ProteomicPSM.enzyme` to the corresponding OpenMS enzyme name. Search and validation use different enzyme naming conventions.

### Mass tolerances

The template uses these mass tolerances, all expressed in **parts per million (ppm)**:

| Tolerance | Template value | Settings in the `MSFragger` block |
| --- | --- | --- |
| Precursor search window | −25 to +25 ppm | `precursor_mass_lower`, `precursor_mass_upper` |
| Calibrated precursor tolerance | 4 ppm | `precursor_true_tolerance` |
| Fragment mass tolerance | 50 ppm | `fragment_mass_tolerance` |

Adjust these values in the `MSFragger` block to suit your instrument and acquisition method before running the full cohort.

### Protein grouping and identification thresholds

ProteinProphet is selected by default. To use another method, change `validate_ProteomicPSM.protein_inference_algorithm` to the corresponding value:

| Method | Configuration value |
| --- | --- |
| ProteinProphet, the default | `'ProteinProphet'` |
| Fido | `'Fido'` |
| EPIFANY | `'Epifany'` |

MSBooster and Percolator validate the search results before protein grouping. Accepted identifications are then used to build the spectral library. Two relevant thresholds in `validate_ProteomicPSM` are:

| Setting | Default | Purpose |
| --- | --- | --- |
| `filter_psm_score_peptide` | `0.01` | Filtering threshold for the validated PSM output. |
| `easypqp_psm_qvalue` | `0.01` | Maximum PSM q-value for export to spectral library generation. |

Protein-group export also has a method-specific minimum probability: `proteinprophet_min_probability` defaults to `0.0`, while `fido_min_probability` and `epifany_min_probability` default to `0.01`. Only the setting for the selected method applies.

!!! note "Protein-group probabilities are not FDR thresholds"
    A minimum group probability of `0.01` is not a 1% FDR cutoff. Keep the meaning of each threshold in mind when changing identification filters or comparing protein-grouping methods.

## Configure quantitation and outputs

The following DIA-NN settings are already supplied by default and shown in the template. Review them in the quoted `'DIA-NN'` block inside `quantitate_ProteomicDIA`:

```groovy
quantitate_ProteomicDIA {
    'DIA-NN' {
        qvalue = 0.01
        matrix_qvalue = 0.01
        no_ifs_removal = true
        no_prot_inf = true
    }
}
```

`qvalue` controls the main report precursor q-value cutoff, and `matrix_qvalue` controls the quantitation matrix q-value cutoff. The template also sets `no_ifs_removal = true`, which disables DIA-NN's fragment interference correction. Review that choice if you are changing the quantitation strategy.

!!! important "Retain upstream protein groups"
    `no_prot_inf` defaults to `true`; leave it unchanged. You do not need to add this setting yourself. This keeps DIA-NN protein inference disabled and retains the protein groups assigned by ProteinProphet, Fido, or EPIFANY. Setting it to `false` would allow DIA-NN to infer new protein groups.

Fraction handling is derived from the acquisition CSV. You do not need to set a separate fractionation switch: the pipeline prepares the library and quantitation inputs, runs quantitation by fraction when needed, and produces sample-level quantitative outputs.

QC follows quantitation, and ProteoVault database assembly is enabled by default (`run_proteovault = true`). Leave this unchanged to generate the database. To skip database assembly while retaining the analysis and QC outputs, set `run_proteovault = false` directly inside `params`.

## Choose the execution environment

### Container runtime

Choose the profile matching the container runtime available on your machine:

| Runtime | Nextflow profile option |
| --- | --- |
| Docker | `-profile docker` |
| Apptainer | `-profile apptainer` |
| Singularity | `-profile singularity` |

Select one of these profiles when launching the analysis. Your choice applies to all analysis steps. The `standard` profile uses Docker.

### Computing resources

The bundled resource profiles are configured for machines with the following resources:

| Profile | CPUs | Memory |
| --- | --- | --- |
| `pines` | 64 | 500 GB |
| `boutroslab_aws` | 32 | 128 GB |

Combine a resource profile with a runtime profile, for example `-profile pines,apptainer`. For a smaller workstation or a different cluster allocation, prepare a custom resource profile as described below.

!!! important "Profiles do not reserve a cluster node"
    Request a cluster allocation with enough CPUs and memory before launching the pipeline. The profiles specify how much each analysis step can use; they do not submit a Slurm job for you.

To adapt the resources, copy a bundled JSON file from `config/resource_profiles/` to a directory you control, give it a name such as `my_cluster.json`, and adjust its `max_cpus`, `max_memory`, and the CPU and memory settings for each analysis step. Set:

```groovy
params.compute_profile = 'my_cluster'
params.additional_resource_profile_dir = '/path/to/resource_profiles'
```

Place these assignments before `methods.setup()`, then select your container profile when launching. Keep all entries in the copied JSON file, including the memory setting for `search_database_MSFragger`; edit their values to fit the resources available to you.

## A complete example

This example configures an unfractionated human DIA cohort with ProteinProphet and the database prepared in [Preparing inputs](inputs.md). Replace the paths with your own and review the search settings for your preparation and instrument. Save the file as `run.config` and select the runtime and resource profiles when launching.

```groovy
includeConfig "${projectDir}/config/default.config"
includeConfig "${projectDir}/config/methods.config"
includeConfig "${projectDir}/nextflow.config"
includeConfig "${projectDir}/config/profiles.config"

params {
    // Inputs and tools
    input_csv = '/project/inputs/acquisitions.csv'
    decoy_database = '/project/database/UP000005640_9606-decoy_contam.fasta'
    decoy_string = 'DECOY_'
    decoy_position = 'prefix'
    contam_string = 'CONTAM_' // Matches the database prepared in the inputs guide
    contam_position = 'prefix'
    msfragger_executable = '/tools/MSFragger/MSFragger.jar'

    // Outputs
    output_dir = '/project/results'
    dataset_id = 'human_dia_cohort'
    run_proteovault = true

    search_ProteomicDIA {
        MSFragger {
            precursor_mass_lower = -25 // ppm
            precursor_mass_upper = 25 // ppm
            precursor_true_tolerance = 4 // ppm
            fragment_mass_tolerance = 50 // ppm
            isotope_error = '0/1/2'
            output_report_topN = 5
            search_enzyme_name_1 = 'stricttrypsin'
            search_enzyme_cut_1 = 'KR'
            search_enzyme_nocut_1 = ''
            search_enzyme_sense_1 = 'C'
            allowed_missed_cleavage_1 = 2
            num_enzyme_termini = 2
            clip_nTerm_M = 1
            variable_mod_01 = '15.9949 M 3'
            variable_mod_02 = '42.0106 [^ 1'
            allow_multiple_variable_mods_on_residue = 0
            max_variable_mods_per_peptide = 3
            digest_min_length = 7
            digest_max_length = 50
            digest_mass_range = '500.0 5000.0'
            max_fragment_charge = 2
            minimum_peaks = 15
            use_topN_peaks = 150
            min_matched_fragments = 4
            add_C_cysteine = 57.02146
        }
    }

    validate_ProteomicPSM {
        protein_inference_algorithm = 'ProteinProphet'
        filter_psm_score_peptide = 0.01
        easypqp_psm_qvalue = 0.01
    }

    quantitate_ProteomicDIA {
        'DIA-NN' {
            qvalue = 0.01
            matrix_qvalue = 0.01
            no_ifs_removal = true
            no_prot_inf = true
        }
    }
}

methods.setup()
```

For Bruker diaPASEF data, point the CSV at the original `.d` directories and add these paths inside `params`:

```groovy
diatracer_executable = '/tools/diaTracer/diaTracer.jar'
bruker_lib_dir = '/tools/MSFragger/ext/bruker'
```

Before launching, check that your input and tool paths exist, your FASTA markers match, your search settings reflect the experiment, and your selected resource profile fits the available machine or allocation. Keep the final configuration with your analysis records.
