# How to use

This folder contains two runnable scripts:
* `setup.sh` builds up the needed conda environments and downloads the databases that are needed for the pipeline to function
* `run.sh` runs the pipeline itself

And a `utils` folder with jupyter notebooks containing utility code that can be use for processing outputs and creating charts

# Enabling functional classification via Humann2

## Important note on hardware (This is disabled by default and only becomes relevant if humann2 is re-enabled)

This is anecdotal evidence, but I managed to fry an old Dell Optiplex 390 motherboard while testing the pipeline (humann2 seems to be really heavy as far as cpu load is concerned (and this load lasts around 10 hours running on a 8700k)) - as a result I would not recommend running the pipeline on a laptop or desktop that you would not feel comfortable running benchmarking software on for an extended amount of time.

This functionality can be enabled editing `run.sh` by changing
```
run_humann=false
```
to

```
run_humann=true
```