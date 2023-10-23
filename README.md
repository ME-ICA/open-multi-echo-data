# open-multi-echo-data
Open multi-echo datasets

This repository contains code to do the following for multi-echo fMRI datasets on OpenNeuro:

1.  Create a Datalad super-dataset.
2.  Copy
```
dsXXXXXX/
    inputs/
        data/       <-- subdataset from OpenNeuro
            code/   <-- code to fix BIDS issues in raw dataset
    outputs/
        fmriprep/   <-- subdataset of fMRIPrep derivatives
        afni/       <-- subdataset of AFNI derivatives
    code/           <-- code to run fMRIPrep and AFNI
```
