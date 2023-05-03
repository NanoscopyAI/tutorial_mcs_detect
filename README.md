# Walkthrough
The below steps allow you to compute contacts in 3D STED between subcellular organelles.
See https://github.com/bencardoen/SubPrecisionContactDetection.jl/ for documentation on the project.

## Table of contents
1. [Batch processing on Compute Canada (1-1000s of cells)](#batch)
2. [Processing a single cell](#single)

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
Log in to cluster
```bash
ssh you@computecanada.ca
```
You'd see something like this
```
[YOU@cedar5 ~]$
```
Change to `scratch` directory
```bash
cd /scratch/$USER
```
Now it'll show
```bash
[you@cedar5 /scratch/YOU]$
```

Create a new, clean directory (replace `experiment` with something you pick, e.g. the date to keep track of experiments):
```bash
mkdir -p experiment
cd experiment
```

### Step 2
Copy your data to a folder under /scratch/$USER, preferably using [Globus](https://globus.computecanada.ca/)

### Step 3

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
salloc --mem=62GB --account=$GROUPID --cpus-per-task=8 --time=3:00:00
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
This script assumes you want to process dStorm data in CSV format, output by Thunderstorm.
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


<a name="single"></a>
### Running a single cell (on cluster or at home)
- Assumes you have a Linux-like command line available, for windows install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

Once you have WSL installed:
##### Download singularity
```bash
wget https://github.com/apptainer/singularity/releases/download/v3.8.7/singularity-container_3.8.7_amd64.deb
```
##### Install it
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
