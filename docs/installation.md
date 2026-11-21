# Installing SpectroMesa-DIA

## Requirements

SpectroMesa-DIA can be run on a Linux workstation or a cluster compute node with an x86-64 processor. Before you begin, make sure you can access your mass spectrometry data and protein sequence database from that machine, and leave about 5-10x free disk or scratch space for the files the pipeline creates along the way.

Install or load the following on the machine that launches the pipeline:

| Software | Requirement |
| --- | --- |
| Nextflow | **24.10.6** with the **v1 syntax parser** is recommended. See below for selecting the version and parser. |
| Container runtime | Docker, Apptainer, or Singularity. Choose the runtime available on your workstation or cluster. |

Most analysis tools, including OpenMS, MSBooster, Percolator, EasyPQP, DIA-NN, and ProteoVault, are supplied through the configured container images. MSFragger must be obtained separately; Bruker data also require diaTracer and the Bruker reader libraries described below.

## Set up Nextflow

We recommend **Nextflow 24.10.6**. If you already have a newer Nextflow launcher installed, you can select the recommended version and syntax parser with these environment variables:

```bash
export NXF_VER=24.10.6
export NXF_SYNTAX_PARSER=v1
```

`NXF_VER` selects the Nextflow version, and `NXF_SYNTAX_PARSER` selects its syntax parser. To use a newer version, set `NXF_VER` to that release and keep `NXF_SYNTAX_PARSER=v1`, provided the release still supports the v1 parser. Version 24.10.6 remains our tested recommendation.

If Nextflow is not installed, use the [official launcher](https://docs.seqera.io/nextflow/install). For a user-local installation, run the following with the environment settings above already exported:

```bash
mkdir -p "$HOME/.local/bin"
curl -fsSL https://get.nextflow.io -o "$HOME/.local/bin/nextflow"
chmod +x "$HOME/.local/bin/nextflow"
export PATH="$HOME/.local/bin:$PATH"
nextflow -version
```

!!! note "Bruker reconstruction selects its own Nextflow version"
    Bruker data reconstruction uses Nextflow 25.10.5, which the pipeline selects automatically. Keep your Nextflow settings as shown above, and allow Nextflow to download this additional version when it is first needed.

## Get the pipeline

### Download a release (recommended)

The easiest way to get started is to [download the latest release with all submodules](https://github.com/TheBoutrosLab/metapipeline-DIA/releases/latest/download/source_code_with_submodules.tar.gz).

To download the latest release from a terminal, use either `wget`:

```bash
wget -O source_code_with_submodules.tar.gz https://github.com/TheBoutrosLab/metapipeline-DIA/releases/latest/download/source_code_with_submodules.tar.gz
```

or `curl`:

```bash
curl -fL -o source_code_with_submodules.tar.gz https://github.com/TheBoutrosLab/metapipeline-DIA/releases/latest/download/source_code_with_submodules.tar.gz
```

From the directory containing your download, extract it into a folder for the pipeline:

```bash
mkdir -p SpectroMesa-DIA
tar -xzf source_code_with_submodules.tar.gz -C SpectroMesa-DIA --strip-components=1
cd SpectroMesa-DIA
```

You can now continue to [check the container runtime](#check-the-container-runtime).

### Clone with Git (alternative)

If you prefer to work from a Git checkout, clone the repository with all nested submodules:

```bash
git clone --recurse-submodules git@github.com:TheBoutrosLab/metapipeline-DIA.git SpectroMesa-DIA
cd SpectroMesa-DIA
```

The repository and its submodules use GitHub SSH URLs, so this command requires working GitHub SSH authentication and access to the repositories. To use HTTPS instead, use this alternative clone command:

```bash
git -c 'url.https://github.com/.insteadOf=git@github.com:' \
    clone --recurse-submodules \
    https://github.com/TheBoutrosLab/metapipeline-DIA.git SpectroMesa-DIA
cd SpectroMesa-DIA
```

For an existing checkout, initialize any missing submodules from its root:

```bash
git submodule update --init --recursive
```

When using HTTPS, apply the same command-scoped URL rewrite:

```bash
git -c 'url.https://github.com/.insteadOf=git@github.com:' \
    submodule update --init --recursive
```

The submodules provide the analysis software and configuration included with this pipeline. Keep their versions matched to the pipeline checkout. Check their status with:

```bash
git submodule status --recursive
```

A leading space indicates the recorded revision is checked out. A leading `-` means a submodule is not initialized; `+` means it differs from the recorded revision.

## Check the container runtime

Choose one runtime and use its matching Nextflow profile when launching an analysis:

| Runtime | Check | Pipeline profile |
| --- | --- | --- |
| Docker | `docker info` | `-profile docker` |
| Apptainer | `apptainer --version` | `-profile apptainer` |
| Singularity | `singularity --version` | `-profile singularity` |

Make sure Docker is running and accessible to your account, or that Apptainer or Singularity is installed on the machines where the analysis will run. The selected profile applies your choice throughout the analysis.

For Apptainer, configure persistent caches before launching a run. Use directories you own that are accessible from the execution nodes:

```bash
export NXF_APPTAINER_CACHEDIR="$HOME/.cache/nextflow/apptainer"
export APPTAINER_CACHEDIR="$HOME/.apptainer/cache"
mkdir -p "$NXF_APPTAINER_CACHEDIR" "$APPTAINER_CACHEDIR"
```

!!! tip "Reuse container images across runs"
    Use shared filesystem paths instead if your home directory is not available on those nodes. Both caches are relevant: some stages use Nextflow-managed images, while others use Apptainer's own image cache.

## Obtain MSFragger

Download MSFragger through its [official download instructions](https://github.com/Nesvilab/MSFragger) under the license appropriate to your use. Keep the extracted distribution in a persistent directory accessible to the analysis tasks. The pipeline requires the path to the JAR, not the containing directory.

In your run configuration, set:

```groovy
params.msfragger_executable = '/path/to/MSFragger/MSFragger.jar'
```

Replace the example with the actual filename, which may include a version number. The pipeline does not download this JAR for you.

## Additional files for Bruker diaPASEF data

For `.d` acquisitions, also obtain the **diaTracer JAR** from its [official repository](https://github.com/Nesvilab/diaTracer#download) and retain the **`ext/bruker` directory** from the compatible MSFragger distribution.

Set both paths in the run configuration:

```groovy
params.diatracer_executable = '/path/to/diaTracer/diaTracer.jar'
params.bruker_lib_dir = '/path/to/MSFragger/ext/bruker'
```

The current reconstruction workflow expects `libtimsdata-2-21-0-4.so` inside that Bruker library directory. Keep the complete directory and use the actual diaTracer JAR filename. These additional files are not required for the file-input conversion route.

## Storage and compute environment

Keep the repository, external tools, input data, and work and output directories accessible to the execution environment. Allow working storage for converted or reconstructed mzML files, copied Bruker acquisitions, intermediate results, and container images. Space requirements depend on the cohort and should not be estimated from final output size alone.

!!! important "Request cluster resources before launching"
    Request a cluster allocation before launching the analysis. The bundled `pines` and `boutroslab_aws` profiles specify CPU and memory settings; they do not submit a Slurm job for you. Combine the resource and container profiles, for example `-profile pines,apptainer`.

## Verify the setup

From the pipeline directory, check:

```bash
export NXF_VER=24.10.6
export NXF_SYNTAX_PARSER=v1
nextflow -version
test -f main.nf
test -f config/template.config
test -f external/search-ProteomicDIA/main.nf
test -f external/validate-ProteomicPSM/main.nf
test -f external/generate-ProteomicSpectralLibrary/main.nf
test -f external/quantitate-ProteomicDIA/main.nf
```

Confirm the expected Nextflow version, a working container runtime, and readable tool files. If you installed through Git, also check the submodule status as described above. The `test` commands produce no output when successful and return a nonzero exit status if a file is missing. These checks verify installation prerequisites; they do not run a proteomics analysis or validate all container images.

Next, prepare the acquisition table and target-decoy FASTA and create a run configuration from the repository's `config/template.config`. Preserve its `includeConfig` statements and final `methods.setup()` call. Input preparation, scientific settings, and analysis execution are separate from installation.
