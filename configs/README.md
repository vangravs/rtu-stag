This folder contains four config files:
* `config.db.hpc.yaml`: config file that will be used when downloading databases in the cluster
* `config.db.local.yaml`: config file that will be used when downloading databases locally
* `config.hpc.yaml`: config file that will be used when running StaG in the cluster
* `config.local.yaml`: config file that will be used when running StaG locally


This value should be changed to the location of the taxonomy database in `config.hpc.yaml` (or `config.local.yaml` if running locally) if you downloaded [Minikraken](https://ccb.jhu.edu/software/kraken2/index.shtml?t=downloads) or if you're looking to use the full database downloaded from [google drive](https://drive.google.com/file/d/1PSdMtl6LDXdn7VvjjIwVTPEtISoQqXmm/view)
```
kraken2:
    db: "databases/taxon_databases/kraken_taxon" 
```

If you haven't cloned the project into your home directory you have to update this value
```
base_path: ""
```