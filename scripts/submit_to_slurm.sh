#!/bin/bash

#SBATCH --partition=high-moby
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=2G

## Array option should be fed in via commandline (i.e sbatch --array X-Y)

SUBJECTLIST=($(cat $1))
FMRIPREP_DIR=$2
CIFTIFY_DIR=$3
TASK_NAME=$4
CLEAN_CONFIG=$5
PARCELLATION=$6
OUTPUT_DIR=$7
WORK_DIR=$8
SIMG=$9
FD_THRESHOLD=${10}
SCRUBBING_WINDOW=${11}
USE_FIXED_REGRESSORS=${12}
REPETITION_TIME=${13}
SMOOTHING_FWHM=${14:-false}

SUBJECT="${SUBJECTLIST[SLURM_ARRAY_TASK_ID]}"

/projects/jjeyachandra/brainhack-project-2022/scripts/run_container_on_subject.sh \
	${SUBJECT} \
	${FMRIPREP_DIR} ${CIFTIFY_DIR} \
	${TASK_NAME} ${CLEAN_CONFIG} ${PARCELLATION} \
	${OUTPUT_DIR}  ${WORK_DIR} \
	${SIMG} \
	${FD_THRESHOLD} ${SCRUBBING_WINDOW} \
	${USE_FIXED_REGRESSORS} ${REPETITION_TIME} ${SMOOTHING_FWHM}
