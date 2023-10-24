#!/bin/bash
#
# Install an OpenNeuro dataset.
#
# Must define DATALAD_CREDENTIAL_GIN_TOKEN environment variable.
dataset_id=$1
base_dir="/cbica/home/salot/open-multi-echo-data/datasets"
superdataset_dir=${base_dir}/${dataset_id}
code_dir="/cbica/home/salot/open-multi-echo-data/code"

# Create the YODA superdataset
datalad create -c yoda \
    -D "Create superdataset for OpenNeuro dataset ${dataset_id}" \
    "${superdataset_dir}"`
cd ${superdataset_dir}

# Download the OpenNeuro subdataset
datalad clone -d ${superdataset_dir} \
    -D "Clone of OpenNeuro dataset. May be modified for fMRIPrep/AFNI and pushed to G-Node GIN." \
    https://github.com/OpenNeuroDatasets/${dataset_id}.git inputs/data
datalad get inputs/data

# Create output subdatasets
datalad create -d ${superdataset_dir} \
    -D "fMRIPrep derivatives for ${dataset_id}." \
    outputs/fmriprep
datalad create -d ${superdataset_dir} \
    -D "AFNI derivatives for ${dataset_id}." \
    outputs/afni

# Prepare code directory
mkdir ${superdataset_dir}/code
cp ${code_dir}/run_fmriprep.sh ${superdataset_dir}/code/
cp ${code_dir}/run_afni_proc.sh ${superdataset_dir}/code/
datalad save -m "Add base scripts for preprocessing."

# Push raw subdataset to G-Node GIN
datalad create-sibling-gin \
    --siblingname gin \
    --access-protocol ssh \
    --dataset inputs/data \
    --credential GIN \
    ME-ICA/${dataset_id}_raw
datalad push -d inputs/data --to gin

# Push superdataset to G-Node GIN
datalad create-sibling-gin \
    --siblingname gin \
    --access-protocol ssh \
    --dataset . \
    --credential GIN \
    ME-ICA/${dataset_id}_superdataset
datalad push -d . --to gin
