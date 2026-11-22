# Understanding results

SpectroMesa-DIA produces quantitative tables, quality-control summaries, and identification results. By default, it also assembles a ProteoVault database that you can explore in R. Start by checking the QC summaries, then choose the quantitative table that matches your analysis question.

The main output directory is:

```text
<output_dir>/SpectroMesa-DIA-<version>/<dataset_id>/main_workflow/
```

Within it, results are grouped into versioned directories. The `*` in the paths below stands for the software version recorded in your run.

| To find… | Look under… |
| --- | --- |
| Quantitative reports and matrices | `quantitate-ProteomicDIA-*/<dataset_id>/output/DIA-NN/` |
| QC summaries and plots | `qc-ProteomicDIA-*/<dataset_id>/output/` |
| Validated identifications and protein groups | `validate-ProteomicPSM-*/` |
| Original search results | `search-ProteomicDIA-*/` |

The ProteoVault database is published separately, as shown in [Analyze the results with ProteoVaultR](#analyze-the-results-with-proteovaultr).

## Quantitation tables

### Choose a matrix

For most protein-level comparisons, start with the **protein-group matrix**. Use precursor or peptide tables when your question requires more detail.

| File | Rows represent | Values represent |
| --- | --- | --- |
| `<dataset_id>-report.pg_matrix.tsv` | Protein groups | Protein-group abundance estimates. |
| `<dataset_id>-report.pr_matrix.tsv` | Precursors: a peptide sequence with a particular modification state and charge | Normalized precursor quantities. |
| `<dataset_id>-report.modified_peptide_matrix.tsv` | Modified peptide sequences, with charge states combined | Summed precursor quantities; generated for fractionated analyses. |
| `<dataset_id>-report.stripped_peptide_matrix.tsv` | Peptide sequences, with modifications and charge states combined | Summed precursor quantities; generated for fractionated analyses. |

The identifying columns describe each row; the remaining columns hold quantities for individual samples or runs. Use `acquisitions.tsv` in the same directory to match acquisition names to the `sample_name` values in your input CSV. Fractionated matrices use sample names directly, with one quantity column per sample. Technical replicates remain separate only when you gave them distinct sample names.

These are abundance measurements, not differential-abundance test results or absolute protein concentrations. Blank cells indicate missing quantities. Keep missing values distinct from measured zeros when preparing a matrix for downstream analysis.

!!! important "A protein-group row can represent several proteins"
    Protein groups are assigned upstream by ProteinProphet, Fido, or EPIFANY and retained by DIA-NN under the default configuration. A group quantity does not establish a separate abundance for every member of that group. Preserve the group identifiers when joining results to annotations.

Unfractionated analyses retain DIA-NN's native quantitative outputs. Fractionated analyses produce combined matrices as described below. DIA-NN's [output documentation](https://github.com/vdemichev/DiaNN#output) explains the native report and matrix conventions; the exact output depends on the DIA-NN version and settings used in your run.

### Inspect the detailed report

`<dataset_id>-report.tsv` provides precursor observations and their associated protein groups, quantities, scores, and other measurements. It is useful when you need to investigate an individual peptide, inspect filtering, or build a custom summary.

| Column | How to read it |
| --- | --- |
| `Run` | The acquisition or sample associated with the observation. |
| `Precursor.Id` | The precursor identifier. |
| `Protein.Group` | The assigned protein group. |
| `Modified.Sequence`, `Stripped.Sequence`, `Precursor.Charge` | The peptide's modification state, unmodified sequence, and charge. |
| `Precursor.Quantity`, `Precursor.Normalised` | Precursor quantities before and after normalization. |
| `PG.Quantity`, `PG.Normalised`, `PG.MaxLFQ` | Different protein-group abundance summaries. Use one consistent measure for a comparison. |
| `Q.Value`, `PG.Q.Value` | Precursor and protein-group confidence measures. These describe identification confidence, not differential-abundance significance. |

Protein-group quantities can be repeated on multiple precursor rows. Use the protein-group matrix for group-level comparisons rather than summing those repeated values. A report and its matrices may contain different sets of entries because their filtering rules differ.

## Review quality control

Open `<dataset_id>_QC_metrics.tsv` in the QC output directory for a combined summary. Each row records a metric, its value and unit, and the sample or cohort it describes. `layer` identifies the analysis stage; `sample_name` and `fraction_id` indicate which acquisition or sample the metric belongs to. A blank sample name can indicate a cohort-wide metric.

Before comparing abundances, review:

- **Acquisition quality:** signal distributions, scan counts, and the MS1 plots. Look for acquisitions that differ markedly from otherwise comparable samples or fractions.
- **Identification results:** search and validated identification counts, mass-error summaries, and available PSM feature distributions. Large changes can help identify acquisitions or search settings that need investigation.
- **Quantitation:** quantified precursor and protein-group counts, quantity distributions, and missingness across comparable samples.

Interpret differences alongside the experimental design. Different biological samples or fractions may have different signal and identification counts without indicating a failed run.

!!! note "Unavailable QC values are not zero"
    A metric marked `status=unavailable` could not be calculated from the available information. Do not treat it as a measured zero. Some optional measurements are omitted when their source information is absent.

Interactive MS1 plots are under:

```text
mzML/<sample_name>/<fraction_id>/<sample_name>_<fraction_id>_MS1_landscape.html
```

Open these HTML files in a browser; they work offline. They display a selection of strong MS1 peaks, rather than every recorded peak. Colors show intensity percentiles within each acquisition, so the same color does not indicate the same absolute intensity in different samples.

## Interpret fractionated experiments

For fractionated data, DIA-NN quantifies each fraction separately. The final tables combine the accepted precursor observations across fractions, so the matrices have one quantity column per sample rather than one per fraction.

Repeated precursor quantities are summed across observed fractions. Modified-peptide and stripped-peptide quantities are then summed from those precursor quantities. Protein-group MaxLFQ estimates are recalculated from the combined precursor quantities using the DIA-NN R package; they are not obtained by summing the fraction-level `PG.MaxLFQ` values. No additional intensity scaling is applied between fractions.

Use `<dataset_id>-report.fraction_coverage.tsv` to inspect the observed precursor coverage and signal for each sample/fraction pair. The accompanying `acquisitions.tsv` preserves the mapping back to the original acquisitions. Acquisition QC remains fraction-specific, while the final quantitation QC is sample-level.

!!! important "Some report fields describe one representative fraction"
    The combined report retains scores, retention times, q-values, and other fields that cannot meaningfully be summed from a representative observation with the lowest precursor q-value. `Representative.Fraction.ID` identifies that fraction, and `Uncombined.Fields.Scope` labels these fields. The retained q-values are not newly calculated across fractions.

The fractionated protein-group matrix uses the pipeline's combined MaxLFQ estimates. Keep this distinction in mind when comparing it with native DIA-NN outputs from an unfractionated experiment. Fraction-specific DIA-NN reports remain in the Nextflow work directory; the published report is the combined sample-level result.

## Identification results

Validated identifications are available as filtered idXML and mzTab files under each sample's validation output directory. Use these when inspecting the spectra and PSMs supporting an identification. Unfiltered files are also retained for specific processing steps, so choose the filtered results when you need the final accepted identification set.

The selected protein-grouping method also produces cohort outputs under `<dataset_id>/<method>/output/` within the validation directory. Use its protein-group results to inspect the assignments underlying your quantitation.

## Analyze the results with ProteoVaultR

ProteoVault database assembly is enabled by default. The generated DuckDB file is located at:

```text
<output_dir>/SpectroMesa-DIA-<version>/<dataset_id>.proteovault.duckdb
```

The database brings together the imported quantitative measurements, protein sequences, and QC summaries. [ProteoVaultR](https://github.com/TheBoutrosLab/package-ProteoVaultR) provides read-only access from R, with functions for querying results, extracting matrices, plotting QC, and preparing downstream analyses. Follow its repository instructions to install the package, then open your database:

```r
library(ProteoVaultR)

vault <- open_vault(
    path = "/project/results/SpectroMesa-DIA-<version>/human_dia_cohort.proteovault.duckdb"
)

vault_info(vault)
list_vault_tables(vault)
counts <- summarize_quantified_counts(vault)
protein_abundance <- matrix_protein_abundance(vault)
precursor_abundance <- matrix_precursor_abundance(vault)

close_vault(vault)
```

Replace the example path, including `<version>`, with your database's actual location. The extracted matrices have features in rows and samples in columns. By default, the matrix functions use imported matrix measurements when available; they do not apply an additional normalization or transformation. Missing combinations remain `NA`.

Use the [ProteoVaultR analysis guides](https://github.com/TheBoutrosLab/package-ProteoVaultR#quick-start) for sample metadata, QC plots, and differential-abundance analysis. Keep your experimental design and replicate assignments alongside the quantitative data when preparing comparisons.
