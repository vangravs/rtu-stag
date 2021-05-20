This is a project that's intended to wrap [StaG-mwc](https://github.com/ctmrbio/stag-mwc) with the goal of automating and expanding it's usage when all samples cannot be processed at the same time.

# Pre-usage assumptions

These scripts can be run only on RTU HPC. Running them locally is not supported (it would take forever anyway).

# How to use

## Setup

This should be executed only once.

* Create a working directory (you can name it however you want) and `cd` to it
```
mkdir work
cd work
```
* Clone the repository
```
git clone https://github.com/kcivkulis/rtu-stag.git
```
* Go to the `hpc` folder
```
cd rtu-stag/hpc
```
* Run the `conda_setup.sh` script that will create required conda environments
```
./conda_setup.sh
```
* Run the `setup.sh` script that will download and build necessary stuff
```
./setup.sh
```

## Preprocessing

Use scripts located in `upstream/` subfolder.

* `sync_with_mgi.sh` fetches new raw data from MGI.
* `rename_samples.sh` concatenates and renames them according to info in `sample_list_data/` group subfolder.
* `download_refseq.sh` downloads all the bacteria, archaea, protozoa and fungi reference sequences from NCBI databases.

## Building databases

* Run the `build_db.sh` script in `hpc` subfolder that will add downloaded sequences to library and build databases.
It's advised to run it on compute nodes
```
cd hpc
qsub build_db.sh
```
You probably would like to move the produced databases to the group subfolder.

## Main process

This assumes all databases are already built on HPC and are more or less up-to-date, and there are some samples in `/home/groups/lu_kpmi/renamed_samples`.

* Run the `run.sh` script in `hpc` subfolder that will process samples in `/home/groups/lu_kpmi/renamed_samples`,
move them to `/home/group/lu_kpmi/analysed_samples` and move results to `/home/groups/lu_kpmi/outputs`
```
cd hpc
./run.sh
```

## Analysis

Not yet :(

# Project structure

* `upstream`: holds scripts for preprocessing raw data from sequencer and propagating `renamed_samples` directory
* `hpc`: holds driver scripts for StaG-mwc and database build
  * `hpc/subscripts`: Contains job scripts that will be queued up for running on the cluster
* `downstream`: nothing here, but it will hold scripts that will do actual statistics on generated outputs

# Notes

The scripts have been made for use in the [Institute of Clinical and Preventive Medicine of the University of Latvia](https://www.kpmi.lu.lv/en-gb/).
