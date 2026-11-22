# diaPASEF reconstruction

For **Bruker diaPASEF `.d` acquisitions**, diaTracer reconstructs precursor-associated pseudo-MS/MS spectra for database searching. This step replaces ordinary file conversion for the Bruker route.

## How it works

1. Copy each `.d` acquisition into its task directory so reconstruction can write its working files without changing the source data.
2. Run diaTracer once per acquisition, linking precursor and fragment features by retention time, ion mobility, and signal correlation.
3. Publish the reconstructed mzML and its SHA-512 checksum.
4. Send the reconstructed spectra to [database search](search.md), while retaining the original `.d` acquisitions for [DIA-NN quantitation](quantitation.md) and acquisition QC.

## Inputs and outputs

The acquisition CSV supplies the sample name, fraction identifier, and `.d` directory. Set the shared `diatracer_executable` and `bruker_lib_dir` paths as described in [Installation](../installation.md#additional-files-for-bruker-diapasef-data). SpectroMesa-DIA passes them to this step automatically.

The output is one pseudo-MS/MS mzML per acquisition, named from its sample and fraction, plus a checksum. Reconstruction uses the separately configured Nextflow runtime; `reconstruct_nextflow_version` already defaults to `25.10.5`.

!!! note "Allow space for the acquisition copies"
    Each active reconstruction task needs room for a copy of its `.d` directory, the reconstructed mzML, and working files. `diatracer_write_inter` already defaults to `0`, which avoids retaining optional diaTracer intermediates.

## Parameter reference

Use the `reconstruct_ProteomicMSMS` block inside `params` in your run configuration. Values below describe this step as used by SpectroMesa-DIA. Settings marked automatically supplied do not need to be repeated.

### Analysis settings

| Parameter | Type | Default / supplied value | Meaning |
| --- | --- | --- | --- |
| `diatracer_write_inter` | Number | 0 | Write diaTracer intermediate files: 0 disables them; 1 enables them. Leave 0 to reduce disk use. |
| `diatracer_delta_apex_im` | Number | 0.01 | Maximum ion-mobility apex difference for linking precursor and fragment features. |
| `diatracer_delta_apex_rt` | Number | 3 | Apex-scan matching range for linking precursor and fragment features. |
| `diatracer_ms1_ms2_corr` | Number | 0.3 | Minimum correlation between precursor and fragment chromatographic signals. |
| `diatracer_mass_defect_filter` | Number | 1 | Apply the mass-defect filter: 1 enables it; 0 disables it. |
| `diatracer_mass_defect_offset` | Number | 0.1 | Offset used by the mass-defect filter. |
| `diatracer_rf_max` | Number | 500 | Maximum number of peaks retained in each reconstructed spectrum. |

### Software and containers

These defaults record the software environment. When replacing an image, check its compatibility with the workflow; a version label alone does not guarantee the required tools are installed.

| Parameter | Type | Default / supplied value | Meaning |
| --- | --- | --- | --- |
| `fragpipe_docker_repo` | Text | fcyucn/fragpipe | FragPipe Docker repository without a version tag |
| `fragpipe_version` | Text | 24.0 | FragPipe Docker image version tag |
| `docker_image_fragpipe` | Text | fcyucn/fragpipe:24.0 | Container image used for fragpipe. Change only when using a compatible replacement image. |

### Automatically supplied settings

| Parameter | Type | Default / supplied value | Meaning |
| --- | --- | --- | --- |
| `dataset_id` | Text | Shared dataset_id | Analysis name used to organize and name outputs. |
| `input_csv` | Path | Generated Bruker acquisition manifest | CSV with sample_name,fraction_id,path columns and one Bruker .d directory per row |
| `diatracer_executable` | Path | Shared diatracer_executable | Path to a separately obtained diaTracer JAR |
| `bruker_lib_dir` | Path | Shared bruker_lib_dir | Path to the MSFragger ext/bruker directory with libtimsdata-2-21-0-4.so |
| `output_dir` | Path | Assigned within the analysis output | Destination for this step. Set the shared output_dir for the complete analysis. |

### Computing and temporary files

The [shared parameter reference](../parameters.md#computing-and-temporary-files) describes CPU, memory, work-directory, and container-cache settings. This pipeline declares: `work_dir`, `base_resource_update`, `max_cpus`, `max_memory`, `min_cpus`, `min_memory`, `resource_allocation_profile_tag`.

The tables were checked against the [individual pipeline configuration](https://github.com/TheBoutrosLab/pipeline-reconstruct-ProteomicMSMS/tree/7317624cf464a05480ee1eb6f4c58c0296eb88c1/config) and the SpectroMesa-DIA settings that select this workflow. See the [diaTracer option descriptions](https://github.com/Nesvilab/diaTracer#standalone-usage-in-command-line-interface) for the reconstruction controls.

## Related steps

[Overview](../overview.md) · [Shared parameters](../parameters.md) · [Configuring an analysis](../configuration.md)

## References

- [diaTracer enables spectrum-centric analysis of diaPASEF proteomics data (2025)](https://doi.org/10.1038/s41467-024-55448-8).
