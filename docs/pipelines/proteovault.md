# Results database

[ProteoVault](https://github.com/TheBoutrosLab/package-ProteoVault) packages the completed analysis into a DuckDB database. It brings the identification, grouping, quantitation, and QC results together for downstream analysis.

## How it works

1. Collect the published search, validation, library, quantitation, and QC outputs, along with the acquisition manifest and search FASTA.
2. Run `proteovault build` for the DIA workflow.
3. Run `proteovault validate` on the resulting database before publishing it.

Database creation is already enabled by default. It follows QC and does not change the identification or quantitation results.

## Inputs and outputs

SpectroMesa-DIA supplies all inputs automatically. The published database is:

```text
<output_dir>/SpectroMesa-DIA-<version>/<dataset_id>.proteovault.duckdb
```

You can import and analyze this DuckDB database in R with [ProteoVaultR](https://github.com/TheBoutrosLab/package-ProteoVaultR). See [Understanding results](../results.md) for the database's place among the analysis outputs.

## Parameter reference

These settings belong directly inside `params` in your run configuration.

| Parameter | Type | Default | Meaning |
| --- | --- | --- | --- |
| `run_proteovault` | Boolean | `true` | Build and validate the results database. Already enabled; set false only to skip this step. |
| `proteovault_version` | Text | `0.2.5` | Version used to select the default ProteoVault image. |
| `docker_image_proteovault` | Text | `ghcr.io/theboutroslab/proteovault:0.2.5` | Container used to build and validate the database. Follows `proteovault_version` unless you supply a custom image. |

The shared `dataset_id` determines the database filename, `output_dir` determines its destination, and `decoy_database` supplies the FASTA. Configure those once in the [shared settings](../parameters.md#inputs-and-analysis-identity).

## Related steps

[DIA quantitation](quantitation.md) · [Quality control](qc.md) · [Understanding results](../results.md)
