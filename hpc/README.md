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
