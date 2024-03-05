#!/bin/bash
#
# Install an OpenNeuro dataset.
dataset_id=$1
base_dir="/cbica/home/salot/open-multi-echo-data/datasets"
superdataset_dir=${base_dir}/${dataset_id}_test
raw_dataset_dir=${superdataset_dir}/inputs/data
code_dir="/cbica/home/salot/open-multi-echo-data/code/code"

# Create the YODA superdataset
datalad create -c yoda \
    -D "Create superdataset for OpenNeuro dataset ${dataset_id}" \
    "${superdataset_dir}"
cd ${superdataset_dir}

# Download the OpenNeuro subdataset
datalad clone -d ${superdataset_dir} \
    -D "Clone of OpenNeuro dataset. May be modified for fMRIPrep/AFNI and pushed to G-Node GIN." \
    https://github.com/ME-ICA/${dataset_id}.git ${raw_dataset_dir}

datalad get ${raw_dataset_dir}
mkdir -p ${raw_dataset_dir}/code

# Create output subdatasets
datalad create -d ${superdataset_dir} \
    -D "fMRIPrep derivatives for ${dataset_id}." \
    ${superdataset_dir}/outputs/fmriprep

datalad create -d ${superdataset_dir} \
    -D "AFNI derivatives for ${dataset_id}." \
    ${superdataset_dir}/outputs/afni

# Prepare code directory
cp ${code_dir}/run_fmriprep.sh ${superdataset_dir}/code/
cp ${code_dir}/run_afni_proc.sh ${superdataset_dir}/code/
datalad save -d ${superdataset_dir} -m "Add base scripts for preprocessing."
