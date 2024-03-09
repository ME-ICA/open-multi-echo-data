#!/bin/bash
#$ -pe threaded 1
#$ -l h_vmem=64G
#$ -l h_rt=240:00:00
#$ -cwd
#$ -N fmriprep
#$ -e /cbica/home/salot/open-multi-echo-data/datasets/ds002156/code/logs
#$ -o /cbica/home/salot/open-multi-echo-data/datasets/ds002156/code/logs

# Submit with the following:
# qsub -t 1 -tc 1 run_fmriprep.sh
PROJECT_DIR=/cbica/home/salot/open-multi-echo-data
BIDS_DIR=${PROJECT_DIR}/datasets/ds002156/inputs/data
OUT_DIR=${PROJECT_DIR}/datasets/ds002156/outputs/fmriprep
LICENSE=/cbica/home/salot/datasets/mobile-phenomics/freesurfer_license.txt

mkdir -p ${PROJECT_DIR}/work/ds002156-fmriprep

# Extract the subject ID from the participants.tsv file.
subject=$( sed -n -E "$((${SGE_TASK_ID} + 1))s/sub-(\S*)\>.*/\1/gp" ${BIDS_DIR}/participants.tsv )

cmd="singularity run --home $HOME --cleanenv \
    -B $PROJECT_DIR:/data \
    -B $LICENSE:/license.txt \
    /cbica/home/salot/open-multi-echo-data/singularity/fmriprep-23_2_1.simg \
    /data/datasets/ds002156/inputs/data \
    /data/datasets/ds002156/outputs/fmriprep \
    participant \
    --participant-label $subject \
    --bids-filter-file /data/datasets/ds002156/code/bids_filter.json \
    -w /data/work/ds002156-fmriprep \
    --nprocs 1 \
    --omp-nthreads 1 \
    --level resampling \
    --output-spaces func T1w MNI152NLin6Asym:res-2 \
    --me-t2s-fit-method curvefit \
    --output-layout bids \
    --me-output-echos \
    --project-goodvoxels \
    --cifti-output \
    --fs-license-file /license.txt"

echo Running task ${SGE_TASK_ID}
echo Commandline: $cmd
datalad run -d $OUT_DIR -m "Run fMRIPrep on ds002156 ${subject}." $cmd
