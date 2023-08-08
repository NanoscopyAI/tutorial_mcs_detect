# Walkthrough
The below steps allow you to compute contacts in 3D STED between subcellular organelles.
See https://github.com/bencardoen/SubPrecisionContactDetection.jl/ for documentation on the project.

## Table of contents
1. [Batch processing on Compute Canada (1-1000s of cells)](#batch)
2. [Processing a single cell](#single)
3. [Troubleshooting](#trouble)

<a name="batch"></a>
## What this will do for you:
- Given any number of directories with 3D TIF STED data of Mitochondria and ER 
- Check that your dataset is valid
- Schedule it for processing
- Compute the contact sites 
- Compute the statistics of those contacts
- Notify you when it's completed


## What you will need
- A Compute Canada account https://ccdb.computecanada.ca/security/login
- Globus to transfer data https://github.com/NanoscopyAI/globus

## Dataset organization:
Your data **has to be organized** in the following way
```
- replicate      (1, 2, ...), directory
  - condition    (COS7, RMgp78), directory
     - Series001 (cellnr), directory
        ...0.tif  #Mitochannel
        ...1.tif  #ER Channel
     - Series002 etc
```
Do not:
- store other files 
- use spaces in names
- change condition names "C0s7" and "Cos7"
If you do, the statistical analysis will be corrupted.


### Step 0
Copy your data to the cluster using Globus. 

### Step 1
Log in to cluster, where you'd replace `$USER` with your userid.
```bash
ssh $USER@computecanada.ca
```
You'll see something like this
```
[$USER@cedar5 ~]$
```
Change to `scratch` directory
```bash
cd /scratch/$USER
```
Now it'll show
```bash
[you@cedar5 /scratch/YOU]$
```
Note that not all shells will show your current working directory, when in doubt type `pwd` to check, it will print
```bash
/scratch/$USER
```
where $USER is equal to your username.

Create a new, clean directory (replace `experiment` with something you pick, e.g. the date to keep track of experiments):
```bash
mkdir -p experiment
cd experiment
```
You can create this with Globus as well. A new directory ensures there's no clashes with existing files.

### Step 2
Copy your data to a folder under /scratch/$USER, preferably using [Globus](https://globus.computecanada.ca/)

### Step 3

#### 3.0 [Optional] If you have your own configuration scripts
If you already completed this tutorial before, or if you know what you're doing and want to change parameters, for example:
- Ask for more memory
- Change scheduling options
- Change channel numbers
- ...

The below script that does everything for you will check if you have an existing script in the current directory, named `submit.sh`. 
If it finds this, it won't use the default pristine version.
However, make sure these fields in your custom script (which will be copied and modified on the fly) are **EXACTLY** like this:
```
#SBATCH --account=ACCOUNT
#SBATCH --mail-user=EMAIL
#SBATCH --array=1-CELLS
```
These are automatically updated with the right nr of cells, email, and account.
Everything else is up to you to modify as you see fit, e.g. if you want to increase memory:
```
#SBATCH --mem=180G
```

#### 3.1 Configure 

Set the DATASET variable to the name of your dataset
```bash
export DATASET="/scratch/$USER/FIXME"
```
And you need to configure where you want the data saved:
```bash
export OUTPATH="/scratch/$USER/OUTPUT"
```

**DO NOT PROCEED UNLESS THESE 2 DIRECTORIES EXIST**

#### 3.2 Account info
Set your group ID and email.
Replace `def-abcdef` with an account ID, which is either `def-yourpiname` or `rrg-yourpiname`. Check ccdb.computecanada.ca, or the output of `groups`.
```bash
export GROUP="def-abcdef"
export EMAIL="your@university.ca"
 ```


### Step 4 Validate your dataset
If you schedule the processing of a large dataset, you don't want it to be interrupted because of avoidable mistakes, so first we'll check if the data is correctly organized so processing works as expected.
Get Compute resources:
```bash
salloc --mem=62GB --account=$GROUP --cpus-per-task=8 --time=3:00:00
```
Once granted this will look something like this:
```bash
salloc --mem=62GB --account=$GROUPID --cpus-per-task=8 --time=3:00:00
salloc: Pending job allocation 61241941
salloc: job 61241941 queued and waiting for resources
salloc: job 61241941 has been allocated resources
salloc: Granted job allocation 61241941
salloc: Waiting for resource configuration
salloc: Nodes cdr552 are ready for job
[bcardoen@cdr552]$
```


### Step 5 Execute

The remainder is done by executing a script, to keep things simple for you.
```bash
wget https://raw.githubusercontent.com/NanoscopyAI/tutorial_mcs_detect/main/check.sh -O script.sh
```
Make it executable
```bash
chmod u+x script.sh
```
Execute it
```bash
./script.sh
```
That's it. 
At the end you'll see something like
```bash
 Info: 2023-02-27 06:14:21 curator.jl:180: Complete with exit status proceed
+ echo Done
Done
Submitted batch job 63009530
[you@cdrxyz scratch]$ 
```

You will receive an email when your cells are scheduled to process and when they complete, e.g.
```
Slurm Array Summary Job_id=63009530_* (63009530) Name=submit.sh Began
```

For each execution, temporary output is saved in the directory `/scratch/$USER/tmp_{DATE}`, e.g. `tmp_05_03_2023_HH04_36`.

See below for more docs.

See https://github.com/bencardoen/SubPrecisionContactDetection.jl/ for documentation on the project, what the generated output means and so forth.

### Troubleshooting
See [DataCurator.jl](https://github.com/NanoscopyAI/DataCurator.jl), (https://github.com/NanoscopyAI/SubPrecisionContactDetection.jl) repositories for documentation.

Create an [issue here](https://github.com/NanoscopyAI/tutorial_smlm_alignment_colocalization/issues/new/choose) with
- Exact error (if any)
- Input
- Expected output
#### Checking queue delays
To check what the status is of a queued job, type
```bash
sq
```
this will print for each job the status (running, pending, ..) and the reason (if any) why it's queued. 

You can also view
```bash
partition-stats
```
This will print a table showing how long the queue times are, per time slot. See the documentation for a more complete explanation.

Queue time will increase with usage (slowly), you can check how strong this effect is with:
```bash
sshare -l -A $GROUP_cpu
```
Check the column `LEVELFS`, a value > 1 means high priority (almost no waiting), < 1 is more waiting.


<a name="single"></a>
### Running a single cell (on cluster or at home)
- Assumes you have a Linux-like command line available, for windows install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

Once you have WSL installed:
##### Download singularity
```bash
wget https://github.com/apptainer/singularity/releases/download/v3.8.7/singularity-container_3.8.7_amd64.deb
```
##### Install itYou're sure this is the
```bash
sudo apt-get install ./singularity-container_3.8.7_amd64.deb
```
##### Test if it's working as expected
```bash
singularity --version
```
this will show
```bash
singularity version 3.8.7
```
##### Download MCSDetect Singularity image
```bash
singularity pull --arch amd64 library://bcvcsert/subprecisioncontactdetection/mcsdetect:latest
mv mcsdetect_latest.sif mcsdetect.sif
chmod u+x mcsdetect.sif
```
##### Configure
```bash
export IDIR="/where/your/data/is/stored/"
export ODIR="/where/your/data/should/be/stored/"
```
You should also grant singularity access
```
export SINGULARITY_BINDPATH=${PWD}
```
##### Run
```bash
 singularity exec mcsdetect.sif julia --project=/opt/SubPrecisionContactDetection.jl --sysimage=/opt/SubPrecisionContactDetection.jl/sys_img.so $LSRC/scripts/ercontacts.jl  --inpath $IDIR -r "*[0,1].tif" -w 2 --deconvolved --sigmas 2.5-2.5-1.5 --outpath  $ODIR --alpha 0.05 --beta  0.05 -c 1 -v 2000 --mode=decon 
```

The results and what the resulting output should be is described [here](https://github.com/bencardoen/SubPrecisionContactDetection.jl#usage)

<a name="trouble"></a>
### Troubleshooting

#### Memory exceeded
For large cells the default memory limit may be not enough. 
A higher limit allows (very) large cells to process, but can mean longer queue time.

You can find out which cells failed:
```bash
wget https://raw.githubusercontent.com/NanoscopyAI/tutorial_mcs_detect/main/findcellstorerun.sh
chmod u+x findcellstorerun.sh
# Copy the old lists as a backup
cp in.txt inold.txt
cp out.txt outold.txt
# Create in/out_rerun.txt that contain failed cells
./findcellstorerun.sh $JOBID in.txt out.txt
# Overwrite so the scheduling script knows where to look
mv inlist_rerun.txt in.txt
mv outlist_rerun.txt out.txt
```
This script will ask the cluster which cells failed, extract them from the input and output lists, and create new ones with only those cells so you can reschedule them.

Next, you'll need to update your `submit.sh` script that was used in scheduling the data earlier:

During the running of the `check.sh` script, a folder `tmp_{date}` is created, where all the above files are saved (incl. submit.sh).

```bash
nano submit.sh
```
This will open an text editor where you can edit and save the script, change the lines with memory and array
```bash
#SBATCH --mem=116G # Change to e.g. 140G (>120G will mean large memory nodes, > 300G will be very large nodes, with very long wait times)
...
#SBATCH --array=1-SETTONEWNROFCELLS
```
Then reschedule
```bash
sbatch submit.sh
```

### MCS Detect Background filtering only (~ segmentation).
If you only want to compute the background filtering, use these instructions.

Run this in an interactive session, see above.

For reference, the setup should look like 
```bash
module load apptainer/1.1
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
```

#### Download the recipe 
```bash
wget https://raw.githubusercontent.com/bencardoen/DataCurator.jl/main/example_recipes/ermito.toml -O recipe.toml
```

The recipe looks for files ending with 0, 1, or 2.tif. 
If that does not match your data, change it, for example
```toml
["*1.tif"] # Matches only abc_1.tif, 01.tif etc.
["*[1-2].tif"] # Only channels 1 and 2
```
Use `nano` or `vi` as text editors if needed.

**Change the inputdirectory**
The recipe will have `testdir` as inputdirectory, change it to point to your directory of choice. 
Or if you have defined it as a variable `DATASET`:
```bash
sed -i "s|testdir|${DATASET}|" recipe.toml
```

#### Download Datacurator
```bash
singularity pull --arch amd64 library://bcvcsert/datacurator/datacurator:latest
chmod u+x datacurator_latest.sif
```

#### Execute recipe
```bash
./datacurator_latest.sif -r recipe.toml
```
See the [recipe](https://raw.githubusercontent.com/bencardoen/DataCurator.jl/main/example_recipes/ermito.toml) for documentation.

Output is saved in the _same_ location as input files. 
