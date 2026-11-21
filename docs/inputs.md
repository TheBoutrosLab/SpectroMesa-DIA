# Preparing inputs

SpectroMesa-DIA requires two main inputs: an **input CSV** listing your mass spectrometry acquisitions and their sample and fraction assignments, and a **target-decoy protein sequence database** in FASTA format. The CSV is valid only when its acquisition paths point to existing files or directories accessible to the pipeline. This guide walks through preparing the CSV and database. Software requirements, including MSFragger and the additional tools for Bruker data, are covered in [Installation](installation.md).

## Input CSV

Create a CSV with one row per acquisition. Save it somewhere accessible to the machine running the pipeline, and use its path for `input_csv` in your run configuration.

### Columns

| Column | What to enter |
| --- | --- |
| `sample_name` | The sample identifier used to group acquisitions for analysis. Repeat it for all fractions of the same sample, but give each biological or technical replicate a unique name. |
| `fraction_id` | A fraction identifier. For unfractionated data, use the same value, such as `1`, for every sample. |
| `annotation_id` | Usually the species name, such as `human` or `mouse`. This field is not currently used, but please include it. |
| `path` | The path to the acquisition file, or to the complete Bruker `.d` directory. |
| `scan` | Required for SCIEX `.wiff` acquisitions: the path to the companion `.wiff.scan` file. Leave it empty for other formats, or omit the column if there are no WIFF files. |

The first four columns are required, and their values must not be empty. Additional columns are allowed but ignored.

!!! warning "Give technical replicates unique sample names"
    **Files with the same `sample_name` are treated as one sample.** Their search results are combined, false discovery rate (FDR) control is performed at the sample level, and the final quantitation matrix contains one column per sample. For technical replicates, use unique names such as `sample_01_rep1` and `sample_01_rep2` so that they remain separate samples in the analysis and output. For a fractionated technical replicate, use its unique name for all of its fractions.

### Unfractionated experiments

Use one row per sample, with a shared fraction identifier:

```csv
sample_name,fraction_id,annotation_id,path
sample_01,1,human,/data/sample_01.raw
sample_02,1,human,/data/sample_02.raw
```

### Fractionated experiments

Repeat each sample name across its fractions, and use consistent identifiers for corresponding fractions across samples:

```csv
sample_name,fraction_id,annotation_id,path
sample_01,1,human,/data/sample_01_fraction_1.mzML
sample_01,2,human,/data/sample_01_fraction_2.mzML
sample_02,1,human,/data/sample_02_fraction_1.mzML
sample_02,2,human,/data/sample_02_fraction_2.mzML
```

Each sample/fraction pair must be unique. The pipeline detects fractionation when the table contains more than one distinct fraction identifier. It uses these assignments during analysis and combines the fraction-level quantitative results into sample-level outputs. Give biological and technical replicates different sample names; fraction identifiers should describe fractions of the same sample.

### Acquisition paths and filenames

You can use absolute paths, as in the examples above, or paths relative to the directory containing the CSV. For example, if the CSV is `/project/inputs/acquisitions.csv`, a `path` value of `../data/sample_01.raw` refers to `/project/data/sample_01.raw`. All listed files and directories must exist and be accessible during the run. List each acquisition path only once.

For identifiers, use letters, numbers, underscores, and hyphens, starting with a letter or number. This convention works for both file inputs and Bruker data.

For acquisition files, avoid extra dots before the extension: `sample_01.raw` is valid, but `sample.01.raw` is rejected. Use distinct filenames across samples, even when the files live in different directories. File names may repeat across fractions of the same sample; the conversion stage adds fraction suffixes when needed. Bruker `.d` directory names must be unique across all acquisitions. Giving every acquisition a distinct name is the simplest approach.

Use either acquisition files or Bruker `.d` directories throughout one CSV; the pipeline does not accept a mixture of these two input paths in one run. File-format support depends on the selected conversion tool.

### SCIEX WIFF files

Supply both the `.wiff` file and its companion `.wiff.scan` file:

```csv
sample_name,fraction_id,annotation_id,path,scan
sample_01,1,human,/data/sample_01.wiff,/data/sample_01.wiff.scan
sample_02,1,human,/data/sample_02.wiff,/data/sample_02.wiff.scan
```

The companion must have the same filename as the acquisition with `.scan` appended. Its path can also be relative to the CSV directory.

### Bruker diaPASEF acquisitions

Point to the complete `.d` directory, keeping its contents together:

```csv
sample_name,fraction_id,annotation_id,path
sample_01,1,human,/data/sample_01.d
sample_02,1,human,/data/sample_02.d
```

The pipeline reconstructs spectra for identification and library generation, while DIA-NN uses the original `.d` acquisitions for quantitation. Keep those directories available throughout the analysis.

## Protein sequence database

### Choose a reference proteome

For a typical experiment, start with the **gene-centric UniProt reference proteome** for the species you are studying. Use the canonical protein FASTA. For human and mouse, expect **about 20,000 proteins** before adding contaminants and decoys. UniProt distributes additional isoform sequences separately in files ending in `_additional.fasta.gz`. See the [UniProt reference proteome file descriptions](https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/README).

| Species | Reference proteome | Canonical protein FASTA |
| --- | --- | --- |
| Human | `UP000005640` | [UP000005640_9606.fasta.gz](https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000005640/UP000005640_9606.fasta.gz) |
| Mouse | `UP000000589` | [UP000000589_10090.fasta.gz](https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000000589/UP000000589_10090.fasta.gz) |

For example, download and decompress the human reference proteome:

```bash
curl -fL -o UP000005640_9606.fasta.gz \
    https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/Eukaryota/UP000005640/UP000005640_9606.fasta.gz
gunzip UP000005640_9606.fasta.gz
```

Keep a record of the UniProt release and download date so you can identify the exact database used in your analysis. Choose or extend the target sequence set to match your experiment if it includes multiple species or proteins absent from the reference proteome.

### Add contaminants and generate decoys

The pipeline requires a **combined target-decoy FASTA**, containing both the proteins you want to identify and decoy sequences used to estimate false discoveries. We also recommend adding common contaminant sequences so that peptides from laboratory contaminants can be assigned to those proteins.

[MSPtools](https://github.com/TheBoutrosLab/package-MSPtools) can prepare this database in one step.

!!! tip "No separate cRAP download needed"
    MSPtools bundles the cRAP contaminant sequences. Use `--include-crap` to add them and generate their decoys along with the reference-protein decoys.

After installing MSPtools, run:

```bash
msptools FASTA CreateDecoyDatabase \
    --input-path UP000005640_9606.fasta \
    --output-path UP000005640_9606-decoy_contam.fasta \
    --include-crap \
    --decoy-prefix DECOY_ \
    --contam-prefix CONTAM_
```

Start from a target-only FASTA. The resulting `UP000005640_9606-decoy_contam.fasta` contains the reference proteins, contaminants, and decoys for both. By default, MSPtools reverses protein sequences while preserving an initial methionine. The command shows its default prefixes, `DECOY_` and `CONTAM_`, explicitly. The pipeline defaults to `CONTAMINANT_` for contaminants, so update that setting as shown below.

### Match the database markers in your run configuration

Set `decoy_database` to the generated FASTA and check all four marker settings. For the command above, keep the default `decoy_string`, `decoy_position`, and `contam_position`, and change `contam_string` to `CONTAM_`. The matching configuration is:

```groovy
params {
    decoy_database = '/path/to/UP000005640_9606-decoy_contam.fasta'
    decoy_string = 'DECOY_'
    decoy_position = 'prefix'
    contam_string = 'CONTAM_'
    contam_position = 'prefix'
}
```

| Setting | Meaning |
| --- | --- |
| `decoy_string` | The text marking decoy accessions, such as `DECOY_`. |
| `decoy_position` | Where the decoy marker occurs. The current MSFragger workflow requires `prefix`. |
| `contam_string` | The text marking contaminant accessions. The pipeline defaults to `CONTAMINANT_`; use `CONTAM_` for the example above. |
| `contam_position` | Where the contaminant marker occurs: `prefix` or `suffix`. Use `prefix` for the MSPtools command above. |

!!! warning "Match the markers in your FASTA"
    **These settings must match the markers in your FASTA accessions.** A prefix appears at the beginning of the accession; a suffix appears at the end. With the example above, a contaminant accession begins with `CONTAM_`, and its decoy begins with `DECOY_CONTAM_`. Changing a pipeline setting does not rewrite the FASTA headers.

Edit the matching settings in your copy of the pipeline's template, keeping its existing `includeConfig` statements and final `methods.setup()` call.

## Before you run

- Check that every acquisition and any required WIFF companion file is accessible from the execution environment.
- Check that each sample/fraction pair and acquisition path appears only once, and that annotations agree across fractions of a sample.
- Point `input_csv` to the completed CSV and `decoy_database` to the combined target-decoy FASTA.
- Confirm that the decoy and contaminant marker strings and positions match the database you generated.
