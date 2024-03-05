#!/bin/bash
#
# A base AFNI script, written by Dan Handwerker.
sbjID=sub-23638
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
afni_proc.py -subj_id ${sbjID} \
    -blocks despike tshift align tlrc volreg mask combine regress \
    -dsets_me_run \
        ./func/${sbjID}_${ses}_task-${task}_echo-1_bold.nii.gz \
        ./func/${sbjID}_${ses}_task-${task}_echo-2_bold.nii.gz \
        ./func/${sbjID}_${ses}_task-${task}_echo-3_bold.nii.gz \
        ./func/${sbjID}_${ses}_task-${task}_echo-4_bold.nii.gz \
    -tlrc_base $template \
    -echo_times $echo_times \
    -reg_echo 2 \
    -copy_anat $anat \
    -anat_has_skull yes \
    -mask_epi_anat yes \
    -align_unifize_epi local \
    -volreg_align_e2a \
    -volreg_tlrc_warp \
    -tcat_remove_first_trs $remove_first_trs \
    -execute
