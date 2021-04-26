# How to use

This folder contains two runnable scripts
* `setup.sh` builds up the needed conda environments and downloads the databases that are needed for the pipeline to function
* `run.sh` runs the pipeline itself

And two folders
* `subscripts` contains job scripts that will be queued up for running on the cluster
* `utils` contains utility scripts for making custom databases and compressing the outputs

# Enabling functional classification via Humann2

## Important note on running humann2 (This is disabled by default and only becomes relevant if humann2 is re-enabled)

Unlike the local scripts the only concern here is computational time - humann2 takes a while to run (it increases the processing time for a single sample from around an hour with the gdrive database to around 8 hours)

This functionality can be enabled editing `subscripts/sub.run.sh` by changing
```
run_humann=false
```
to

```
run_humann=true
```