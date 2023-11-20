#!/bin/bash
#$ -pe threaded 1
#$ -l h_vmem=32G
#$ -l h_rt=240:00:00
#$ -cwd
#$ -N afni
#$ -e /cbica/home/salot/datasets/${dataset_id}/code/logs
#$ -o /cbica/home/salot/datasets/${dataset_id}/code/logs

BIDS_DIR=/cbica/home/salot/datasets/${dataset_id}/dset

# Extract the subject ID from the participants.tsv file.
subject=$( sed -n -E "$((${SGE_TASK_ID} + 1))s/sub-(\S*)\>.*/\1/gp" ${BIDS_DIR}/participants.tsv )

cmd="singularity run --home $HOME --cleanenv \
    -B $BIDS_DIR:/data \
    /cbica/home/salot/datasets/mobile-phenomics/singularity/afni-23_1_10.simg \
    base_afni_proc_script.sh"

echo Running task ${SGE_TASK_ID}
echo Commandline: $cmd
datalad run -m "Run afni_proc.py on ${dataset_id} ${subject}." $cmd
