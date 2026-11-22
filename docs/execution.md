# Running and resuming an analysis

Once you have [installed SpectroMesa-DIA](installation.md), [prepared your inputs](inputs.md), and [created a run configuration](configuration.md), you can launch the analysis with Nextflow. Start with a small representative subset of your data to check the setup before processing the full cohort.

## Choose a work directory

Nextflow stores intermediate files in a work directory, separate from the results directory specified by `output_dir`. Choose a location with enough space and keep it available until you have finished the analysis and no longer need to resume it.

Use the same work path each time you launch or resume this analysis. In the examples below, replace `/scratch/your_user/human_dia_cohort/work` with a suitable location on your system. All machines running the analysis must be able to access it.

!!! important "Keep a stable work path between jobs"
    Avoid using `$SLURM_JOB_ID` in the work path if you want to resume across cluster jobs: each job has a different ID. Also check your site's scratch retention policy. A stable path is only useful for resuming while its contents remain available.

For initial planning, allow roughly 5–10 times the acquisition data size in additional free storage for intermediate files and published results. This is an estimate, not a measured guarantee; conversion, fractionation, and cohort size affect peak usage. Check storage use during your pilot run.

## Start an analysis

### On a workstation

Use a dedicated directory for each analysis, such as `/project/analyses/human_dia_cohort`. Keep your prepared `run.config` there and launch Nextflow from that directory. Nextflow stores its run history and `.nextflow.log` there, while the pipeline itself can remain in a separate installation directory:

```bash
cd /project/analyses/human_dia_cohort
export NXF_VER=24.10.6
export NXF_SYNTAX_PARSER=v1

nextflow run /path/to/SpectroMesa-DIA/main.nf \
    -c /project/analyses/human_dia_cohort/run.config \
    -profile docker \
    -work-dir /scratch/your_user/human_dia_cohort/work
```

Replace the example paths with your own. This example uses Docker; choose `apptainer` or `singularity` if that is what you installed. Review the [computing resource settings](configuration.md#computing-resources) to make sure the analysis fits your workstation. Keep the terminal session running until Nextflow finishes.

`-c` selects your run configuration, `-profile` selects the execution environment, and `-work-dir` sets the intermediate-file location. The results still go to the `output_dir` in your configuration.

### On a Slurm cluster

Run the analysis inside a compute allocation. For example, the following submission script requests resources matching the bundled `boutroslab_aws` resource profile and uses Apptainer. That profile can be used on a suitably sized node; its name does not require an AWS environment.

Save this as `run-dia.sh` in your analysis directory, replace the paths, and adjust the time limit and any partition or account settings required by your cluster:

```bash
#!/usr/bin/env bash
#SBATCH --job-name=human_dia
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --time=24:00:00
#SBATCH --output=human_dia-%j.log

set -euo pipefail

# Load Java, Nextflow, and Apptainer here if your cluster uses modules.
cd /project/analyses/human_dia_cohort
export NXF_VER=24.10.6
export NXF_SYNTAX_PARSER=v1

nextflow run /path/to/SpectroMesa-DIA/main.nf \
    -c /project/analyses/human_dia_cohort/run.config \
    -profile boutroslab_aws,apptainer \
    -work-dir /scratch/your_user/human_dia_cohort/work
```

Submit it from the same analysis directory:

```bash
cd /project/analyses/human_dia_cohort
sbatch run-dia.sh
```

The 24-hour limit is an example, not an expected runtime. Choose an appropriate limit for your cohort and cluster. The profile sets CPU and memory use; `sbatch` requests the allocation. For a different allocation, use a matching [custom resource profile](configuration.md#computing-resources).

!!! tip "Keep container images available between runs"
    For Apptainer, use persistent image caches as described in [Installation](installation.md#check-the-container-runtime). Export those cache settings in your submission script as well. This avoids downloading and converting the same images repeatedly.

## Monitor progress

Nextflow prints progress and any errors to the terminal. For the Slurm example, this output is saved to `human_dia-<job-id>.log` in the directory from which you submitted the script. The launch directory also contains `.nextflow.log` with more detailed messages.

A stage such as searching or quantitation may take a long time without changing the top-level progress display. Check its logs before assuming that the analysis has stopped.

The pipeline writes execution reports under:

```text
<output_dir>/SpectroMesa-DIA-<version>/<dataset_id>/
  log-SpectroMesa-DIA-<version>-<timestamp>/nextflow-log/
    trace.txt
    timeline.html
    report.html
```

The HTML reports are most useful after the run finishes. They summarize task execution, timing, and resource use. Analysis stages also save their own logs alongside their outputs.

A successful run exits with status `0` and has no failed tasks. On a cluster, check the job's final status as well as the Nextflow log. The presence of some result files alone does not mean the whole analysis completed successfully, because results are written as stages finish.

If the run fails, read the reported error and the failed task's `.command.err` and `.command.out` files in the work directory shown by Nextflow. Correct the cause before trying to resume.

## Resume an interrupted run

Add `-resume` to the original command, using the same launch directory, configuration, profiles, and work path. For the workstation example:

```bash
cd /project/analyses/human_dia_cohort
export NXF_VER=24.10.6
export NXF_SYNTAX_PARSER=v1

nextflow run /path/to/SpectroMesa-DIA/main.nf \
    -c /project/analyses/human_dia_cohort/run.config \
    -profile docker \
    -work-dir /scratch/your_user/human_dia_cohort/work \
    -resume
```

For the Slurm example, add `-resume` to the Nextflow command in `run-dia.sh` and submit the script again after the previous job has stopped.

!!! warning "An interrupted stage starts again"
    Resume currently works at the level of completed analysis stages. Nextflow can reuse a completed stage when its cached results are available and its inputs and settings still match. Work completed inside an unfinished stage is not automatically resumed. For example, if searching stops halfway through the cohort, expect the search stage to run again; completed earlier stages may be reused.

Return to the same analysis directory when resuming, and keep its `.nextflow` folder and the original work directory. Published results alone are not enough to resume. Changing inputs, settings, or pipeline code can cause affected stages to run again. See [Nextflow's resume documentation](https://docs.seqera.io/nextflow/cache-and-resume) for the cache requirements.

Plain `-resume` selects the most recent run. If you have launched another analysis from the same directory, list previous runs with:

```bash
nextflow log
```

Then use `-resume RUN_NAME`, replacing `RUN_NAME` with the name of the intended run. Do not start two attempts to resume the same run at once.

## Find your results

The main analysis outputs are under:

```text
<output_dir>/SpectroMesa-DIA-<version>/<dataset_id>/main_workflow/
```

Look for the versioned `quantitate-ProteomicDIA-*` directory for quantitative reports and matrices, and `qc-ProteomicDIA-*` for QC summaries and plots.

ProteoVault database assembly is enabled by default. When generated, the database is published one level above the dataset directory:

```text
<output_dir>/SpectroMesa-DIA-<version>/<dataset_id>.proteovault.duckdb
```

You can load the generated DuckDB database into R and analyze the results using [ProteoVaultR](https://github.com/TheBoutrosLab/package-ProteoVaultR).

Keep the run configuration and logs with your results. Once the analysis is complete, review the QC summaries before interpreting the quantitative comparisons. Retain the work directory if you expect to resume or investigate individual analysis steps.
