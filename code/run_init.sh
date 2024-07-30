#!/bin/bash

# Define an array of strings
datasets=(
"ds000210"
"ds000254"
"ds000258"
"ds001491"
"ds002156"
"ds002278"
"ds003192"
"ds003592"
"ds003643"
"ds003823"
"ds004627"
"ds004662"
"ds004787"
"ds004935"
"ds005085"
"ds005118"
)

# Loop over the array
for dataset in "${datasets[@]}"
do
  # Check if the folder doesn't exist
  if [ ! -d "/cbica/home/salot/open-multi-echo-data/$dataset" ]
  then
    # Run the script if the folder doesn't exist
    source /cbica/home/salot/open-multi-echo-data/code/code/init_superdataset.sh $dataset
  else
    # Print a message if the folder already exists
    echo "Dataset $dataset already exists."
  fi
done
