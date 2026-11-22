# Integration tests

For the setup and public-data download instructions, see [Running the tests](../docs/testing.md).

The six NFTest cases cover conversion for file inputs, then search, validation, library generation, and quantitation with ProtLoom, ProteinProphet, or Epifany as the validation route. All cases run QC after quantitation. The MSConvert case starts from two E. coli Thermo RAW files under `$TEST_DATA_DIR/ecoli_dia/Raw`; the other E. coli cases start from mzML. The diaTracer case uses the `hela_diapasef` Bruker `.d` fixture, reconstructs pseudo-MS/MS mzML for search and library generation, and sends the original `.d` directory to DIA-NN. It sets `quantitate_ProteomicDIA.copy_inputs_to_work = true`, so DIA-NN copies the `.d` directory into its task work directory before quantitation. It requires `$TEST_DATA_DIR/diaTracer-2.2.1.jar`, `$TEST_DATA_DIR/MSFragger-4.4.1.jar`, the MSFragger `ext/bruker` libraries, and the HeLa target-decoy FASTA. The ProteinProphet and Epifany cases also run ProteoVault and publish `<dataset_id>.proteovault.duckdb` directly under the versioned metapipeline output directory. The ProtLoom case skips ProteoVault. The cases publish the cohort QC metric table and per-acquisition MS1 plots under the versioned `qc-ProteomicDIA-1.3.2` result directory.

From the repository root, create `.env` from `.env-template`, set `TEST_DATA_DIR`, `NFT_RUN_ROOT`, and `NFT_CLUSTER`, and run a case (inside a Slurm job for `boutroslab_aws`):

```bash
python3 test/run-nftest.py test_integration_diaTracer_MSFragger_ProteinProphet_DIANN
python3 test/run-nftest.py test_integration_MSFragger_ProtLoom_DIANN
python3 test/run-nftest.py test_integration_MSFragger_ProteinProphet_DIANN
python3 test/run-nftest.py test_integration_MSFragger_ProteinProphet_DIANN_multifraction
python3 test/run-nftest.py test_integration_MSFragger_Epifany_DIANN
python3 test/run-nftest.py test_integration_MSConvert_MSFragger_ProteinProphet_DIANN
```

`NFT_CLUSTER=boutroslab_aws` places runs under `$NFT_RUN_ROOT/$SLURM_JOB_ID` and requires a Slurm job. `NFT_CLUSTER=pines` uses `$NFT_RUN_ROOT` directly and selects the `apptainer,pines` Nextflow profiles. With no cluster selected, the existing Docker runtime and AWS resource requests apply without adding a job directory. Relative `NFT_RUN_ROOT` paths resolve against the repository; an unset root defaults there. Final results go to `<run-root>/<test-case>/` and temporary files to `<run-root>/.nftest-temp/<12-character case ID>/`. The input CSVs and ProtLoom YAML resolve `$TEST_DATA_DIR` through `csv_environment_expander.groovy`.

For Pines tests, you can set the optional [Apptainer cache variables](../docs/installation.md#check-the-container-runtime) in the repository’s `.env` or export them before running the test. NFTest’s launcher passes them to the metapipeline and its child runs. A value in `.env` takes precedence over the same variable in your shell.

The multifraction case assigns two E. coli acquisitions to one biological sample with fractions 1 and 2 to exercise the fraction-aware handoffs and DIA-NN aggregation. The fractionated case also runs QC and ProteoVault with per-fraction acquisition QC and the aggregated DIA-NN report.
