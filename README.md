# brainhack-2022-scrubbing
Testing scrubbing parameters on clinical datasets

## Objectives
We started this project because SPINS and SPASD data have strong motion effects that cannot be separated from group effects (SSD vs ASD vs Controls).
This could be due to differences in the clinical populations given their symptoms. To alleviate the effect of motion in the analysis, 
[Power et al. (2014)](https://github.com/TIGRLab/brainhack-2022-scrubbing/files/10169520/Power.2014.motion.and.scrubbing.pdf) suggested ways to 
quality control for motion and introduced **scrubbing** as an additional step before cleaning the data. 
Scrubbing is a procedure that removes the TRs that have a big motion (as indicated by FD values that exceed a certain threshold) and the TRs between two
motion spikes that are too close to each other (the TR section in between two spikes is called the *island* of which the length can be specified).

With SPINS and SPASD in mind, we would like to test if scrubbing is a possible solution to remove the motion effects that confound the group effects.
However, schizophrenia and autism patients all tend to move more compared to healthy controls, so it might be worth checking different scrubbing
arguments to leverage the quality of the data and the amount of usable data that go into the final analysis.

## Data

We use data from SPINS and SPASD with three groups (SSD, ASD, and controls).

## Method

We use the latest version of nilearn (with `pip install git+https://github.com/nilearn/nilearn.git`) with the new function `nilearn.signal.clean` to 
perform scrubbing and cleaning.

The visualization for QC will be done with R. See [tutorial for plotting the figure for QC](https://github.com/TIGRLab/brainhack-2022-scrubbing/blob/main/notebooks/Testing-Visualization.md).

## Before BrainHack

1. Run scrubbing + cleaning on various threshold
2. Extract FC
3. Extract distances

## BrainHack

1. Testing multiple thresholds (decrease from 5 mm) for Mean FD
    1. Check mean FD to check for group differences
    2. Distance-correlation scatter plots for different thresholds x each group (based on diagnostic or motion-alone or both)

> The data quality gained from scrubbing vs. the amount of data/people we lose according to the threshold

2. Decision
    1. Visually QC the plots
    2. Documentation

3. Parameters to test

| FD_threshold (mm) | scrubs (TR) | Note |
| -------- | -------- | -------- |
| 0.5     | 5     | Default; SPINS & SPASD (by groups)    |
| 0.2     | 5     | SPINS & SPASD (by groups)    |
| 0.5     | 10     | SPINS & SPASD (by groups)    |
| 0.2     | 10     | SPINS & SPASD (by groups)    |
| 0.5     | 3     | SPINS & SPASD (by groups)    |
| 0.2     | 3     | SPINS & SPASD  (by groups)   |
| 0     | -    | SPINS & SPASD (by groups)    |

* Optional: add a feature to scrub the TRs after the motion spike

## Setup Guide

If you already have a `.simg` file, feel free to skip this section

### Manual Environment Setup

It is heavily recommended that you use a Python virtual environment when installing the requirements for this project locally. 

```
<enter your python virtualenv>
apt-get install connectome-workbench bc
pip install -r requirements.txt
```

### Docker Image Creation

To create a Docker image of the development environment run the following command:

```
cd /path/to/repository
docker build . -t brainhack-scrubbing:0.0.0 --rm
```

### Create Singularity Image

A singularity image can be created using the `docker2singularity` tool. Note this can only be done if you built the Docker image (previous section) first. The following command can be used:

```
cd <path_to_repository>
docker run -v /var/run/docker.sock:/var/run/docker.sock -v $PWD:/output --privileged -t --rm quay.io/singularity/docker2singularity:v2.6 brainhack-scrubbing:0.0.0
```

## Usage Guide

### Running the full pipeline

The main run script to generate a parcellated distance and connectivity matrix is `scripts/run_container_on_subject.sh`. The usage is as follows:

```
scripts/run_container_on_subject.sh \
	SUBJECT_NAME FMRIPREP_DIR CIFTIFY_DIR \
	TASK_NAME CLEAN_CONFIG_JSON PARCELLATION_DLABEL \
	OUTPUT_DIR WORK_DIRECTORY SINGULARITY_IMAGE \
	FD_THRESHOLD SCRUBBING_WINDOW REPETITION_TIME \
	[USE_FIXED_REGRESSORS (true/false)] \
	[SMOOTHING_FWHM (float value)]
```

All arguments with the exception of the last 2 must be specified to run the full pipeline.

If you'd like to run the pipeline on multiple participants (i.e a full dataset), then take a look at the template in `scripts/submit_to_slurm.sh`. The arguments are identical to `run_container_on_subject` but instead of specifying `SUBJECT_NAME` you give it a `SUBJECT_LIST` filepath. The file specified by `SUBJECT_LIST` must contain 1 subject per line and must correspond to an existing subject in fMRIPrep/Ciftify.

```
SUBJECT_LIST=/path/to/subjectlist.txt
num_subjects=$(wc -l $SUBJECT_LIST | awk '{print $1}'

sbatch --array 0-$num_subjects \
	[--output PATH] \
	[--error PATH] \
	scripts/run_container_on_subject.sh \
	SUBJECT_LIST FMRIPREP_DIR CIFTIFY_DIR \
	TASK_NAME CLEAN_CONFIG_JSON PARCELLATION_DLABEL \
	OUTPUT_DIR WORK_DIRECTORY SINGULARITY_IMAGE \
	FD_THRESHOLD SCRUBBING_WINDOW REPETITION_TIME \
	[USE_FIXED_REGRESSORS (true/false)] \
	[SMOOTHING_FWHM (float value)]
```

You may need to modify `submit_to_slurm` to suit your HPC cluster environment

### Singularity Jupyter Notebook

Singularity or Docker can be used to spin up a development environment containing all the software needed for either Jupyter Notebook prototyping or development.

```
XDG_RUNTME_DIR= singularity exec \
	-B <directory_to_mount>:/<mounted_directory_name> \
	-B <another_directory>:/<another_mount_point> \
	...
	path/to/singularity/image.simg \
	jupyter notebook --port <PORT> --no-browser
```

Once Jupyter has spun up you can navigate to the URL provided in the terminal.

### Interactive Development Environment

If you want to interactively run commands within the container environment you may use the `singularity shell` command:

```
singularity shell \
	-B <directory_to_mount>:/<mounted_directory_name> \
	-B <another_directory>:/<another_mount_point> \
	...
	path/to/singularity/image.simg
```
This shell environment will contain all the software required to run any step of the pipeline.

## References:

**Power's Paper**: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3849338/

**Lindquist Paper**: https://onlinelibrary.wiley.com/doi/epdf/10.1002/hbm.24528

**Benchmark Paper**:
https://www.sciencedirect.com/science/article/pii/S1053811917302288

**PR w/Nilearn Code**: https://github.com/nilearn/nilearn/pull/3385

