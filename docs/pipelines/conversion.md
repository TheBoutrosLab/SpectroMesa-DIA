# MS data conversion

Raw acquisition files are prepared as mzML for database searching and quantitation. **ProteoWizard msconvert** is the default converter, with vendor peak picking enabled. Bruker diaPASEF acquisitions follow the separate [reconstruction route](reconstruction.md).

![MS data conversion workflow](flowcharts/conversion.svg)

[Open the original flowchart at full size](flowcharts/conversion.svg).

## How it works

1. Read the acquisition manifest and locate each file, including the companion scan file where required.
2. Convert vendor files to mzML with ProteoWizard. The individual pipeline also offers OpenMS FileConverter for formats it supports.
3. Optionally apply OpenMS PeakPickerHiRes and an indexing pass. Both are disabled by default in SpectroMesa-DIA.
4. Pass the resulting mzML files to [database search](search.md) and [quantitation](quantitation.md).

Existing mzML input bypasses conversion in SpectroMesa-DIA. The format options available in the standalone converter do not change the requirement for mzML in this analysis.

## Inputs and outputs

The input is the file list derived from your [acquisition CSV](../inputs.md). You do not need to prepare a separate conversion CSV. The output is a converted mzML for each acquisition, together with process logs.

!!! important "Keep mzML as the output format"
    `output_format` is already `mzML`. SpectroMesa-DIA checks this setting because the following steps require mzML files.

## Parameter reference

Use the `convert_MSData` block inside `params` in your run configuration. Values below describe this step as used by SpectroMesa-DIA. Settings marked automatically supplied do not need to be repeated.

### Analysis settings

| Parameter | Type | Default / supplied value | Meaning |
| --- | --- | --- | --- |
| `save_intermediate_files` | Boolean | false | Publish additional intermediate files for inspection. Final outputs and execution logs are retained independently. |
| `convert_algorithm` | Text | ProteoWizard | The algorithm used for conversion. Must be either 'OpenMS' or 'ProteoWizard'. Defaults to 'ProteoWizard'. |
| `peak_picking_vendor` | Boolean | true | Whether to use vendor peak picking. |
| `peak_picking_openms` | Boolean | false | Whether to run `PeakPickerHiRes` from OpenMS. |
| `pwiz_extra_args` | Text | --64 | Extra arguments to be passed to `MSConvert` (*e.g.* '--zlib', '--zlib --64 --inten64'). |
| `run_index` | Boolean | false | Whether to run the indexing step for the output file using OpenMS' `FileConverter` command to clean up and update file version. |
| `output_format` | Text | mzML | Output mass-spectrometry data format. Choices: `mzML`, `mzXML`, `mgf`, `mz5`, `ms1`, `cms1`, `ms2`, `cms2`, `cachedMzML`, `featureXML`, `consensusXML`, `edta`, `mzData`, `dta2d`, `csv`, `sqmass`. |

### Software and containers

These defaults record the software environment. When replacing an image, check its compatibility with the workflow; a version label alone does not guarantee the required tools are installed.

| Parameter | Type | Default / supplied value | Meaning |
| --- | --- | --- | --- |
| `pwiz_version` | Text | 3.0.21258-ae984af | Version tag used for this tool’s output naming and default container selection. |
| `docker_image_pwiz` | Text | chambm/pwiz-skyline-i-agree-to-the-vendor-licenses:3.0.21258-ae984af | Container image used for pwiz. Change only when using a compatible replacement image. |
| `openms_version` | Text | 3.5.0 | Version tag used for this tool’s output naming and default container selection. |
| `docker_image_openms` | Text | ghcr.io/theboutroslab/openms-thirdparty:3.5.0 | Container image used for openms. Change only when using a compatible replacement image. |

### Automatically supplied settings

| Parameter | Type | Default / supplied value | Meaning |
| --- | --- | --- | --- |
| `input_csv` | Path | Generated from your acquisition CSV | Path to the input CSV file. |
| `output_dir` | Path | Assigned within the analysis output | Destination for this step. Set the shared output_dir for the complete analysis. |

### Computing and temporary files

The [shared parameter reference](../parameters.md#computing-and-temporary-files) describes CPU, memory, work-directory, and container-cache settings. This pipeline declares: `ucla_cds`, `work_dir`, `apptainer_library`, `apptainer_cache`, `singularity_library`, `singularity_cache`, `base_resource_update`, `max_cpus`, `max_memory`, `min_cpus`, `min_memory`, `resource_allocation_profile_tag`.

The tables were checked against the [individual pipeline configuration](https://github.com/TheBoutrosLab/pipeline-convert-MSData/tree/1834209b42f79e849eed02904a18f0250664f5ef/config) and the SpectroMesa-DIA settings that select this workflow.

## Related steps

[Overview](../overview.md) · [Shared parameters](../parameters.md) · [Configuring an analysis](../configuration.md)

## References

- [ProteoWizard: open source software for rapid proteomics tools development (2008)](https://doi.org/10.1093/bioinformatics/btn323).
- [OpenMS 3 enables reproducible analysis of large-scale mass spectrometry data (2024)](https://doi.org/10.1038/s41592-024-02197-7).
