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
set -euxo pipefail


if [ ! -d "$DATASET" ]; then
    echo "Dataset directory $DATASET does not exist. Set it by export DATASET=/scratch/$USER/my/data/inputdirectory"
    exit 1
fi


if [ ! -d "$OUTPATH" ]; then
    echo "Dataset directory $OUTPATH does not exist. Set it by export DATASET=/scratch/$USER/my/data/outputdirectory"
    exit 1
fi

NOW=$(date +"%m_%d_%Y_HH%I_%M")
echo "Creating temporary directory tmp_$NOW"
mkdir tmp_$NOW

FILE="submit.sh"
echo "Cheking if you have your own submission script.... looking for submit.sh ..."
if test -f "$FILE"; then
    echo "$FILE exists -- not going to download a new submission script"
else
    echo "No script found, downloading fresh one"
    wget https://raw.githubusercontent.com/NanoscopyAI/tutorial_mcs_detect/main/submitdata.sh -O submit.sh
fi
cp $FILE tmp_$NOW/

MCS="mcsdetect.sif"
if test -f "$MCS"; then
    echo "$MCS exists -- not going to download a new image"
    chmod u+x $MCS
fi
cp $MCS tmp_$NOW/
cd tmp_$NOW


echo "Configuring singularity"
# module load apptainer/1.1
module load StdEnv/2020 apptainer/1.1.3
export SINGULARITY_CACHEDIR="/scratch/$USER"
export APPTAINER_CACHEDIR="/scratch/$USER"
export APPTAINER_BINDBATH="/scratch/$USER,$SLURM_TMPDIR"
export SINGULARITY_BINDPATH="/scratch/$USER,$SLURM_TMPDIR"
export JULIA_NUM_THREADS="$SLURM_CPUS_PER_TASK"

echo "Checking if remote lib is available ..."

export LISTED=`apptainer remote list | grep -c SylabsCloud`
# apptainer remote list | grep -q SylabsCloud

if [ $LISTED -eq 1 ]
then
    apptainer remote use SylabsCloud
else
    echo "Not available, adding .."
    apptainer remote add --no-login SylabsCloud cloud.sycloud.io
    apptainer remote use SylabsCloud
fi

echo "Downloading required files"
singularity pull --arch amd64 library://bcvcsert/datacurator/datacurator:latest
chmod u+x datacurator_latest.sif

MCS="mcsdetect.sif"
if test -f "$MCS"; then
    echo "$MCS exists -- not going to download a new image"
    chmod u+x $MCS
else
    echo "No recipe found, downloading fresh one"
    singularity pull --arch amd64 library://bcvcsert/subprecisioncontactdetection/mcsdetect:latest
    mv mcsdetect_latest.sif mcsdetect.sif
    chmod u+x mcsdetect.sif
fi

# echo "Downloading mcs-detect"
# singularity pull --arch amd64 library://bcvcsert/subprecisioncontactdetection/mcsdetect:latest
# mv mcsdetect_latest.sif mcsdetect.sif
# chmod u+x mcsdetect.sif

echo "Downloading recipe"
wget https://raw.githubusercontent.com/NanoscopyAI/tutorial_mcs_detect/main/recipe.toml -O recipe.toml

echo "Updating recipe"
sed -i "s|testdir|${DATASET}|" recipe.toml


echo "Updating recipe"
sed -i "s|outpath|${OUTPATH}|" recipe.toml

echo "Validating dataset with recipe"
./datacurator_latest.sif -r recipe.toml

echo "Finding number of files"
FN=`wc -l in.txt | awk '{print $1}'`

echo "Total of $FN cells to process"

echo "Creating computing request"

#wget https://raw.githubusercontent.com/NanoscopyAI/tutorial_mcs_detect/main/submitdata.sh -O submit.sh

sed -i "s|EMAIL|${EMAIL}|" submit.sh
sed -i "s|ACCOUNT|${GROUP}|" submit.sh
sed -i "s|CELLS|${FN}|" submit.sh

echo "Submitting"
sbatch submit.sh
echo "Done"
