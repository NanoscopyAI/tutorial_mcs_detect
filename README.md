# Walkthrough
The below steps allow you to run fiduciual alignment on 2/3D point cloud data, then compute colocalization metrics.

## What this will do for you:
- Given any number of directories with 3D TIF STED data of Mitochondria and ER
- Compute the contact sites 
- Compute the statistics of those contacts
- Notify you when it's completed

## What you will need
- A Compute Canada account https://ccdb.computecanada.ca/security/login
- Globus to transfer data https://github.com/NanoscopyAI/globus

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
### Step 2
Copy your data to a folder under /scratch/$USER, preferably using [Globus](https://globus.computecanada.ca/)

### Step 3 Validate your dataset
If you schedule the processing of a large dataset, you don't want it to be interrupted because of avoidable mistakes, so first we'll check if the data is correctly organized so processing works as expected.
Get Compute resources:
Replace `FIXME` with an account ID, which is either `def-yourpiname` or `rrg-yourpiname`. Check ccdb.computecanada.ca, or the output of `groups`.
```bash
salloc --mem=62GB --account=FIXME --cpus-per-task=8 --time=3:00:00
```
Once granted this will look something like this:
```bash
salloc --mem=62GB --account=def-hamarneh --cpus-per-task=8 --time=3:00:00
salloc: Pending job allocation 61241941
salloc: job 61241941 queued and waiting for resources
salloc: job 61241941 has been allocated resources
salloc: Granted job allocation 61241941
salloc: Waiting for resource configuration
salloc: Nodes cdr552 are ready for job
[bcardoen@cdr552]$
```

Set the DATASET variable to the name of your dataset
```bash
export DATASET="/scratch/$USER/FIXME"
```
And you need to configure where you want the data saved:
```
export OUTPATH="/scratch/$USER/OUTPUT"
```

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
[you@cdrxyz scratch]$ 
```

This includes, but is not limited to
See the reppository

For each execution, temporary output is saved in the directory `tmp_{DATE}`.

See below for more docs.

### Troubleshooting
See [DataCurator.jl](https://github.com/NanoscopyAI/DataCurator.jl), (https://github.com/NanoscopyAI/SubPrecisionContactDetection.jl) repositories for documentation.

Create an [issue here](https://github.com/NanoscopyAI/tutorial_smlm_alignment_colocalization/issues/new/choose) with
- Exact error (if any)
- Input
- Expected output

