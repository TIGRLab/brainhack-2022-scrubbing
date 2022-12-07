#!/bin/bash

# Run distance matrix computation and cleaning on a subject
SUBJECT_NAME=$1
FMRIPREP_DIR=$2
CIFTIFY_DIR=$3
TASK_NAME=$4
CLEAN_CONFIG=$5
PARCELLATION=$6
OUTPUT_DIR=$7
BASE_WORKDIR=$8
SIMG=$9
FD_THRESHOLD=${10}
SCRUBBING_WINDOW=${11}
REPETITION_TIME=${12}
USE_FIXED_REGRESSORS=${13:-false}
SMOOTHING_FWHM=${14:-false}


subject_workdir=${BASE_WORKDIR}/${SUBJECT_NAME}
subject_outdir=${OUTPUT_DIR}/${SUBJECT_NAME}
mkdir -p ${subject_workdir}
mkdir -p ${subject_outdir}

# Execute distance matrix command
echo "Computing distance matrix for ${SUBJECT_NAME} using ${PARCELLATION}"
out_filename="${SUBJECT_NAME}_distance-matrix.txt"

if [[ ! -f ${subject_outdir}/${out_filename} ]]; then
	echo "Did not find ${subject_outdir}/${out_filename}... calculating..."
	singularity run \
		-B ${CIFTIFY_DIR}:/ciftify \
		-B ${PARCELLATION}:/parcellation.dlabel.nii \
		-B ${subject_outdir}:/output \
		-B ${subject_workdir}:/work \
		-B /projects/jjeyachandra/brainhack-project-2022/scripts:/scripts \
		$SIMG \
		/scripts/distance_matrix_from_ciftify \
			/ciftify \
			${SUBJECT_NAME} \
			/parcellation.dlabel.nii \
			/output/${SUBJECT_NAME}_distance-matrix.txt
else
	echo "Found ${subject_outdir}/${out_filename}, skipping distance matrix!"
fi

singularity run \
	-B ${CIFTIFY_DIR}:/ciftify \
	-B ${FMRIPREP_DIR}:/fmriprep \
	-B ${PARCELLATION}:/parcellation.dlabel.nii \
	-B ${CLEAN_CONFIG}:/clean_config.json \
	-B ${subject_outdir}:/output \
	-B ${subject_workdir}:/work \
	-B /projects/jjeyachandra/brainhack-project-2022/scripts:/scripts \
	$SIMG \
	/scripts/clean_subject_data \
		${SUBJECT_NAME} \
		/fmriprep /ciftify \
		${TASK_NAME} /clean_config.json \
		/parcellation.dlabel.nii \
		/work  /output \
		${USE_FIXED_REGRESSORS} ${SMOOTHING_FWHM} \
		"--t_r ${REPETITION_TIME} --fd_threshold ${FD_THRESHOLD} --scrub ${SCRUBBING_WINDOW}"

