# Running the tests

The integration tests run SpectroMesa-DIA on small reference datasets to check that the analysis completes in your computing environment. You will need the installed pipeline, the public test data, the required search software, and **UCLA NFTest**. Start with one case before trying the other acquisition and protein-grouping routes.

## Install the test tools

Complete the [pipeline installation](installation.md), including its submodules, Java, Nextflow, and the container runtime you will use. The test launcher also needs Python 3.8 or newer and [UCLA NFTest (`uclahs-cds/tool-NFTest`)](https://github.com/uclahs-cds/tool-NFTest).

You can keep the Python tools in a dedicated environment:

```bash
python3 -m venv "$HOME/.venvs/spectromesa-tests"
source "$HOME/.venvs/spectromesa-tests/bin/activate"
python3 -m pip install \
    "git+https://github.com/uclahs-cds/tool-NFTest.git" \
    PyYAML python-dotenv
python3 -m nftest --help
```

Activate this environment whenever you run a test, including inside a cluster job. The launcher uses NFTest from the same Python environment as `python3`.

Use the tested Nextflow settings:

```bash
export NXF_VER=24.10.6
export NXF_SYNTAX_PARSER=v1
```

The Bruker reconstruction step selects its own Nextflow runtime automatically, as explained in [Installation](installation.md#set-up-nextflow).

## Download the test data

The Boutros Lab public S3 location is `s3://boutroslab-public/test-data/`. SpectroMesa fixtures are under `spectromesa/`. Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) if `aws` is not already available.

Choose a data directory outside the pipeline installation. The following commands download the database and E. coli DIA fixtures needed for the E. coli cases:

```bash
export TEST_DATA_DIR=/project/test-data/spectromesa
mkdir -p "$TEST_DATA_DIR"

aws s3 sync \
    s3://boutroslab-public/test-data/spectromesa/database/ \
    "$TEST_DATA_DIR/database/" --no-sign-request

aws s3 sync \
    s3://boutroslab-public/test-data/spectromesa/ecoli_dia/ \
    "$TEST_DATA_DIR/ecoli_dia/" --no-sign-request
```

For the diaPASEF case, also download:

```bash
aws s3 sync \
    s3://boutroslab-public/test-data/spectromesa/hela_diapasef/ \
    "$TEST_DATA_DIR/hela_diapasef/" --no-sign-request
```

`--no-sign-request` allows these public downloads without AWS credentials. You can rerun the [sync commands](https://docs.aws.amazon.com/cli/latest/reference/s3/sync.html) to retrieve missing or updated files. Keep the folder names and the contents of each Bruker `.d` directory intact.

Set `TEST_DATA_DIR` to the directory containing `database/`, `ecoli_dia/`, and, when downloaded, `hela_diapasef/`. Do not point it to the directory above `spectromesa/`.

## Add the required software and database settings

Obtain MSFragger and diaTracer separately, following the links in [Installation](installation.md). The test configurations expect these paths:

| File or directory under `TEST_DATA_DIR` | Needed for |
| --- | --- |
| `MSFragger-4.4.1.jar` | Every case listed below |
| `diaTracer-2.2.1.jar` | The diaPASEF case |
| `MSFragger-4.4.1/ext/bruker/` | The diaPASEF case; must contain `libtimsdata-2-21-0-4.so` |

The public data download does not install these tools. Place the separately obtained files at the expected paths, or update the corresponding paths in the test configuration you plan to use.

!!! important "Use the public E. coli database"
    The current E. coli test configurations name an older FASTA that is not in the public download. Before running an E. coli case, update its `test/<test-case>/test.config` to use the published database and matching markers below. The diaPASEF case already points to its published human database.

Replace the database settings inside the existing `params` block of each E. coli case you intend to run:

```groovy
decoy_database = "${TEST_DATA_DIR}/database/UP000000625_83333-FragPipe/2026-11-12-decoys-contam-input.fasta.fas"
decoy_string = 'DECOY_'
decoy_position = 'prefix'
contam_string = 'contam_'
contam_position = 'prefix'
```

The case configuration already reads `TEST_DATA_DIR` from the environment. Keep its setup statements and final `methods.setup()` call. Changing the database path alone is insufficient: its decoy marker must also match.

## Configure the test environment

The test launcher reads `.env` and `nftest.yml` from the pipeline installation directory. Run the test commands from that directory, while keeping the downloaded data and generated results elsewhere. Normal analyses can continue to use the [separate analysis-directory layout](execution.md#start-an-analysis).

If the installation does not already have a `.env` file, create one from the template:

```bash
cd /path/to/SpectroMesa-DIA
cp .env-template .env
```

Edit the existing file if you have already configured it. For the bundled AWS test setup, use:

```dotenv
NXF_VER=24.10.6
NXF_SYNTAX_PARSER=v1
TEST_DATA_DIR=/project/test-data/spectromesa
NFT_CLUSTER=boutroslab_aws
NFT_RUN_ROOT=/scratch/your_user/spectromesa-tests
```

Use full paths accessible from the compute node. The launcher loads `.env` with precedence over exported shell values, so update this file when changing the data path or cluster selection.

| `NFT_CLUSTER` | Runtime and resource plan | Location of test runs |
| --- | --- | --- |
| `boutroslab_aws` | Docker; 32 CPUs and 128 GB memory | `NFT_RUN_ROOT/<SLURM_JOB_ID>/`; requires an active Slurm job |
| `pines` | Apptainer; 64 CPUs and 500 GB memory | `NFT_RUN_ROOT/` |
| Empty | Docker with the AWS resource plan | `NFT_RUN_ROOT/`; no Slurm job-ID requirement |

These are the supplied test configurations, not resource reservations. For another environment, adapt the case's runtime and resource settings using the [configuration guide](configuration.md#computing-resources).

!!! important "Launch inside your compute allocation"
    On a cluster, obtain an allocation matching the selected resource plan before running the test. The launcher does not submit a job for you. `NFT_CLUSTER=boutroslab_aws` checks for `SLURM_JOB_ID` and stops if it is absent.

For Apptainer, you can also set the image-cache variables described in [Installation](installation.md#check-the-container-runtime) in `.env` to reuse downloaded images between tests.

## Run a test case

With the Python environment active and your compute allocation ready, start with the E. coli mzML case:

```bash
cd /path/to/SpectroMesa-DIA
python3 test/run-nftest.py test_integration_MSFragger_ProteinProphet_DIANN
```

Choose another case by replacing the final argument:

| Test case | What it exercises |
| --- | --- |
| `test_integration_MSFragger_ProteinProphet_DIANN` | E. coli mzML input, MSFragger, ProteinProphet grouping, and DIA-NN quantitation |
| `test_integration_MSFragger_Epifany_DIANN` | The E. coli mzML workflow with EPIFANY grouping |
| `test_integration_MSFragger_ProteinProphet_DIANN_multifraction` | Two E. coli samples with three fractions each, including fraction-aware library generation and quantitation aggregation |
| `test_integration_MSConvert_MSFragger_ProteinProphet_DIANN` | Two E. coli Thermo RAW files, including conversion before searching |
| `test_integration_diaTracer_MSFragger_ProteinProphet_DIANN` | A HeLa Bruker diaPASEF acquisition, including reconstruction for search and quantitation from the original `.d` data |

All cases listed here also run QC and build the ProteoVault results database. These are integration runs using the actual analysis tools, so they take longer than a configuration check. The current cases check pipeline execution; they do not define numerical assertions for expected identification counts or intensities.

## Check results and investigate failures

The launcher prints the selected case, work directory, and output root before NFTest starts. Check its completion message and exit status, then inspect the published outputs using [Understanding results](results.md).

The resolved run root is `NFT_RUN_ROOT`, with the Slurm job-ID directory added for `boutroslab_aws`:

```text
<run-root>/
  <test-case>/                 Published analysis results
  .nftest-temp/<case-id>/      Test launch files and temporary work
```

Temporary files are retained by the supplied test settings. If a case fails, keep them while inspecting the NFTest log, `.nextflow.log`, and the failed task's command logs. Common setup problems are a mismatched `TEST_DATA_DIR`, a missing JAR, a database path or marker that does not match the downloaded FASTA, or a container runtime unavailable on the compute node.

The test launcher does not add `-resume`. Rerunning a case should not be assumed to resume the failed analysis; see the [resume guide](execution.md#resume-an-interrupted-run) for the separate analysis workflow.
