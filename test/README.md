# Integration tests

The three NFTest cases run the complete search, validation, library, quantitation, and QC workflow with ProtLoom, ProteinProphet, or Epifany as the validation route. ProteinProphet and Epifany also run ProteoVault and publish `<dataset_id>.proteovault.duckdb` directly under the versioned metapipeline output directory. The ProtLoom case skips ProteoVault. All cases publish the cohort QC metric table and per-sample MS1 plots under the versioned `qc-ProteomicDIA-1.1.1` result directory.

From the repository root, create `.env` from `.env-template`, set `TEST_DATA_DIR`, and run a case inside a Slurm job:

```bash
zsh test/run-nftest.sh test_integration_MSFragger_ProtLoom_DIANN
zsh test/run-nftest.sh test_integration_MSFragger_ProteinProphet_DIANN
zsh test/run-nftest.sh test_integration_MSFragger_Epifany_DIANN
```

The runner uses `/scratch/$SLURM_JOB_ID/<test-case>` for work and output. The input CSVs and ProtLoom YAML resolve `$TEST_DATA_DIR` through `csv_environment_expander.groovy`.
