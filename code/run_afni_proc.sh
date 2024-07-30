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

ses=ses-01
task=rest_run-1
echo_times=(15.1 28.7 42.3 55.9)
rootdir=~/code/meica/data_testing/Multi-echo_masking_test_dataset/${sbjID}/${ses}
anat=anat/${sbjID}_${ses}_acq-mpragePURE_run-1_T1w.nii.gz

# The data had several non-steady state volumes at the beginning.
# This will be used to remove the first four
remove_first_trs=4

# template from here: https://www.templateflow.org/browse/ in tpl-MNI152NLin6Asym
# Using the T1 that was already skull stripped
template=../../template/tpl-MNI152NLin6Asym_res-02_desc-brain_T1w.nii.gz

# You probably want to put files elsewhere, but fine for this demo
cd $rootdir

# Runs AFNI proc in native space
# The pre-processed runs to input into tedana are called pb03.${sbjID}.r01.e0?.volreg+orig.HEAD
cmd="apptainer run --home $HOME --cleanenv \
    -B $BIDS_DIR:/data \
    /cbica/home/salot/datasets/mobile-phenomics/singularity/afni-23_1_10.simg \
    base_afni_proc_script.sh"

echo Running task ${SGE_TASK_ID}
echo Commandline: $cmd
datalad run -m "Run afni_proc.py on ${dataset_id} ${subject}." $cmd
