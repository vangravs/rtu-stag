This is a project that's intended to wrap [StaG-mwc](https://github.com/ctmrbio/stag-mwc) with the goal of automating and expanding it's usage when all samples cannot be processed at the same time.

# Pre-usage assumptions

These scripts can be run only on RTU HPC. Running them locally is not supported (it would take forever anyway).

# How to use

This assumes all databases are already built on HPC and are more or less up-to-date, and there are some samples in `/home/groups/lu_kpmi/renamed_samples`.

* Create a work directory (you can name it however you want) and `cd` to it
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
* Run the `run.sh` script that will process samples in `/home/groups/lu_kpmi/renamed_samples`, move them to `/home/group/lu_kpmi/analysed_samples` and move results to `/home/groups/lu_kpmi/outputs`
```
./run.sh
```

# Building databases

Not yet :(

# Project structure

* `upstream`: holds scripts for preprocessing raw data from sequencer and propagating `renamed_samples` directory
* `hpc`: holds driver scripts for StaG-mwc and database build
  * `hpc/databases`: holds scripts for database build
  * `hpc/subscripts`: Contains job scripts that will be queued up for running on the cluster
* `downstream`: nothing here, but it will hold scripts that will do actual statistics on generated outputs

# Notes

The scripts have been made for use in the [Universities of Latvia Institute of Clinical and Preventitive Medicine](https://www.kpmi.lu.lv/en-gb/).
