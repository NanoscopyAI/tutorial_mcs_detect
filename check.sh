#!/bin/bash

# Copyright (C) 2023 Ben Cardoen
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

### First, any error should immediately halt and quit (set -e)
### Undefined variables are an error (set -u)
### Be verbose on what we do (set -x) = -xtrace
### If a pipe (x | b) fails in x, quit, do not pass possible garbage through (set -o pipefail
set -euxo pipefail

### Check if the dataset env var is defined and exists
if [ ! -d "$DATASET" ]; then
    echo "Dataset directory $DATASET does not exist. Set it by export DATASET=/scratch/$USER/my/data/inputdirectory"
    exit 1
fi

### Check if the output path is defined, and exists
if [ ! -d "$OUTPATH" ]; then
    echo "Dataset directory $OUTPATH does not exist. Set it by export DATASET=/scratch/$USER/my/data/outputdirectory"
    exit 1
fi

### We'll create a temporary working directory so all experiment files, logs, etc, are located here.
NOW=$(date +"%m_%d_%Y_HH%I_%M")
echo "Creating temporary directory tmp_$NOW"
mkdir tmp_$NOW

### We will schedule a complex workload, which is pre-templated in a script called submit.sh. Check if the user has their own version, if not, download the template.
FILE="submit.sh"
echo "Cheking if you have your own submission script.... looking for submit.sh ..."
if test -f "$FILE"; then
    echo "$FILE exists -- not going to download a new submission script"
else
    echo "No script found, downloading fresh one"
    wget https://raw.githubusercontent.com/NanoscopyAI/tutorial_mcs_detect/main/submitdata.sh -O submit.sh
fi
cp $FILE tmp_$NOW/

## If MCS Detect already has been downloaded, set it executable, and copy it to the local folder where the processing will occur
MCS="mcsdetect.sif"
if test -f "$MCS"; then
    echo "$MCS exists -- not going to download a new image"
    chmod u+x $MCS
    cp $MCS tmp_$NOW/
fi

# Change to the local temporary directory
cd tmp_$NOW

## We'll run Singularity, so let's make sure it's configured properly
echo "Configuring singularity"
# module load apptainer/1.1
module load StdEnv/2020 apptainer/1.1.3
## Configure the cache for downloads
export SINGULARITY_CACHEDIR="/scratch/$USER"
export APPTAINER_CACHEDIR="/scratch/$USER"
## Make sure we can read/write the needed directories
export APPTAINER_BINDBATH="/scratch/$USER,$SLURM_TMPDIR"
export SINGULARITY_BINDPATH="/scratch/$USER,$SLURM_TMPDIR"
## Make sure we only use the threads we're allowed to
export JULIA_NUM_THREADS="$SLURM_CPUS_PER_TASK"

## We'll need to download some singularity images, check if that has been configured correctly
echo "Checking if remote lib is available ..."
export LISTED=`apptainer remote list | grep -c SylabsCloud`
# apptainer remote list | grep -q SylabsCloud

## If our chosen repository (where our images are uplaoded) is listed, select it
## Container images are hosted at SylabsCloud
if [ $LISTED -eq 1 ]
then
    apptainer remote use SylabsCloud
else
    echo "Not available, adding .."    # Here we need to tell singularity to use our remote servers, and add it first
    apptainer remote add --no-login SylabsCloud cloud.sycloud.io
    apptainer remote use SylabsCloud
fi

### We'll download DataCurator to preprocess the data
echo "Downloading required files"
singularity pull --arch amd64 library://bcvcsert/datacurator/datacurator:latest
chmod u+x datacurator_latest.sif

### Next, if we haven't downloaded or copied MCS yet, download it
# MCS="mcsdetect.sif"
if test -f "$MCS"; then
    echo "$MCS exists -- not going to download a new image"
    chmod u+x $MCS # Technically not needed
else
    echo "No recipe found, downloading fresh one"
    singularity pull --arch amd64 library://bcvcsert/subprecisioncontactdetection/mcsdetect:latest
    mv mcsdetect_latest.sif mcsdetect.sif
    chmod u+x mcsdetect.sif
fi

### Download the `recipe' 
echo "Downloading recipe"
wget https://raw.githubusercontent.com/NanoscopyAI/tutorial_mcs_detect/main/recipe.toml -O recipe.toml

### Now we modify the recipe by substituting the dataset directory
echo "Updating recipe"
sed -i "s|testdir|${DATASET}|" recipe.toml

### Now we modify the recipe by substituting the output directory
echo "Updating recipe"
sed -i "s|outpath|${OUTPATH}|" recipe.toml

### Test if the data is in the way MCS Detect expects it. If we don't do this here, it can lead to costly resubmissions. 
echo "Validating dataset with recipe"
./datacurator_latest.sif -r recipe.toml

### DataCurator also counted how many cells it detected, let's update the submission script
echo "Finding number of files"
FN=`wc -l in.txt | awk '{print $1}'`
echo "Total of $FN cells to process"

## Time to configure the submission script, we'll use the user's information so the cluster accepts it
echo "Creating computing request"
sed -i "s|EMAIL|${EMAIL}|" submit.sh
sed -i "s|ACCOUNT|${GROUP}|" submit.sh
sed -i "s|CELLS|${FN}|" submit.sh

## Le moment supreme, we invoke sbatch (the scheduler) and pass it our script. All output (logs) will be written here.
echo "Submitting"
sbatch submit.sh
echo "Done"
