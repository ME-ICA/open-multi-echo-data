#!/bin/bash
#
# Install an OpenNeuro dataset.
dataset_id=$1
datalad install https://github.com/OpenNeuroDatasets/${dataset_id}.git
