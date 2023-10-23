#!/bin/bash
#
# Install an OpenNeuro dataset.
dataset_id=$1
datalad create -c yoda -D "Create superdataset for OpenNeuro dataset ${dataset_id}" "${dataset_id}"`
cd ${dataset_id}
datalad clone -d . -D "Clone of OpenNeuro dataset. May be modified to work with fMRIPrep/AFNI and pushed to G-Node GIN." https://github.com/OpenNeuroDatasets/${dataset_id}.git inputs/data
cd inputs/data
datalad get .
cd ../..
datalad create -d . -D "fMRIPrep derivatives for ${dataset_id}." outputs/fmriprep
datalad create -d . -D "AFNI derivatives for ${dataset_id}." outputs/afni
mkdir code
cp run_afni_proc.sh code/
cp run_fmriprep.sh code/
datalad save -m "Add base scripts for preprocessing."
datalad create-sibling-gin --siblingname gin --access-protocol ssh --dataset . ME-ICA/${dataset_id}_superdataset
datalad push --to gin
