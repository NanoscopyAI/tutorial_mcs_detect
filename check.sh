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

cd /scratch/$USER

NOW=$(date +"%m_%d_%Y_HH%I_%M")
echo "Creating temporary directory tmp_$NOW"
mkdir tmp_$NOW
cd tmp_$NOW


echo "Configuring singularity"
module load singularity
export SINGULARITY_CACHEDIR="$SLURM_TMPDIR/singularity/cache"
export SINGULARITY_BINDPATH="/scratch/$USER,$SLURM_TMPDIR"
export JULIA_NUM_THREADS="$SLURM_CPUS_PER_TASK"

echo "Downloading required files"
singularity pull --arch amd64 library://bcvcsert/datacurator/datacurator:latest
chmod u+x datacurator_latest.sif

echo "Downloading recipe"
wget https://raw.githubusercontent.com/NanoscopyAI/tutorial_mcs_detect/main/recipe.toml -O recipe.toml

echo "Updating recipe"
sed -i "s|testdir|${DATASET}|" recipe.toml


echo "Updating recipe"
sed -i "s|outpath|${OUTPATH}|" recipe.toml

echo "Running recipe"
./datacurator_latest.sif -r recipe.toml
