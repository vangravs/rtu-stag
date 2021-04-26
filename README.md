This is a project that's intended to wrap [StaG-mwc](https://github.com/ctmrbio/stag-mwc) with the goal of automating and expanding it's usage when all samples cannot be processed at the same time.

# Pre-usage assumptions

Conda is expected to be installed on the host environment - https://www.digitalocean.com/community/tutorials/how-to-install-anaconda-on-ubuntu-18-04-quickstart can be used as installation instructions to set it up on a local environment.

# Quick start

Assuming you're looking to quickly try out these scripts locally
* Go to your home directory 
```
cd ~
```
* Clone the repository
```
git clone https://github.com/lucren/rtu-stag.git
```
* Copy your samples into the `samples` folder
* Open `configs/config.local.yaml` in a text editor and update the value for `base_path: ""` so that it contains your home directory (something like `base_path: "/home/username/"`)
* Go into the `local` folder
```
cd rtu-stag/local
```
* Run the `setup` script that will download and build databases 
```
./setup.sh
```
* Run the `run` script that will process your samples using the pipeline
```
./run.sh
```

**Do note** that running the pipeline like this may result in a partial reference database being downloaded (see the note on databases for a stable workaround).

# How to use

If you wish to run the project without fiddling with any of the configuration files you should clone it into your home directory.

The project is divided into 4 folders:
* `configs`: holds configuration files that both the local and the cluster jobs work
* `hpc`: holds scripts intended to be ran on the [Riga Technical Universities cluster](https://hpc.rtu.lv/)
* `local`: holds scripts intended for running on a local system (or a remote system with no queueing system)
* `samples`: intended to hold all of your samples (paired end reads expected with names that end with `..._<sample_id>_<direction_id>.fq.gz`)

# How to use custom Kraken2 databases

## Example scenario - you want to use minikraken in a local installation

Follow the quick start until you reach the `run` step. At this point (once the `setup` script has been executed) there will be a `databases` folder in your home directory.

Download [minikraken](https://ccb.jhu.edu/software/kraken2/index.shtml?t=downloads) and extract the contents to `databases/minikraken` (you should end up with three `*.k2d` files and three `*.kmer_distrib` files directly in this folder).

Once this has been done go to `rtu-stag/configs` and open the `config.local.yaml` file. Locate the line that says
```
db: "databases/taxon_databases/kraken_taxon"
```
and change it to 
```
db: "databases/minikraken"
```

Now you can go to the `rtu-stag/local` folder and use `./run.sh`, and it will use the minikraken database instead of using the one that was downloaded during the setup step

## Example scenario - you want to use the big (google drive) database on the RTU cluster

*TODO*

# Notes

## Important note on databases

Kraken2 seems to be pretty unreliable at downloading all required references (it looks like the NCBI ftp server starts timing out download request after a little while). I would, intstead, strongly recommend using either [Minikraken](https://ccb.jhu.edu/software/kraken2/index.shtml?t=downloads) when running these scripts locally (assuming you have less than 192 gigabytes of RAM) or using a database [I've made available via google drive](https://drive.google.com/file/d/1PSdMtl6LDXdn7VvjjIwVTPEtISoQqXmm/view) if you're using a cluster (or have more than 192 gigabytes of ram available locally) (it contains all [bacteria](https://ftp.ncbi.nlm.nih.gov/refseq/release/bacteria/), [archaea](https://ftp.ncbi.nlm.nih.gov/refseq/release/archaea/) and [fungi](https://ftp.ncbi.nlm.nih.gov/refseq/release/fungi/) *.genomic.fna.gz available on the NCBI ftp server (as of june 2020))).

## Additional notes

The scripts have been made for use in the [Universities of Latvia Institute of Clinical and Preventitive Medicine](https://www.kpmi.lu.lv/en-gb/).