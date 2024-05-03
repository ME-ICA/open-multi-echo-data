#!/bin/bash
#
# Install an OpenNeuro dataset.
dataset_id=$1
base_dir="/cbica/home/salot/open-multi-echo-data/datasets"
superdataset_dir=${base_dir}/${dataset_id}
raw_dataset_dir=${superdataset_dir}/inputs/data
code_dir="/cbica/home/salot/open-multi-echo-data/code/code"

# Create the YODA superdataset
datalad create -c yoda \
    -D "Create superdataset for OpenNeuro dataset ${dataset_id}" \
    "${superdataset_dir}"
cd ${superdataset_dir}

# Fork the OpenNeuro dataset to ME-ICA if it doesn't exist

# Check if the repository exists
if gh repo view ME-ICA/$dataset_id &>/dev/null; then
    echo "ME-ICA/$dataset_id exists"
else
    # gh repo fork OpenNeuroDatasets/${dataset_id} --org "ME-ICA"
    echo "Repository does not exist"
fi

# Download the OpenNeuro subdataset
datalad clone -d ${superdataset_dir} \
    -D "Clone of OpenNeuro dataset. May be modified for fMRIPrep/AFNI and pushed to OpenNeuro." \
    https://github.com/ME-ICA/${dataset_id}.git ${raw_dataset_dir}

# Don't download the data
# datalad get ${raw_dataset_dir}
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
cd ${code_dir}
