#!/bin/bash
#PBS -N build_db
#PBS -l nodes=1:ppn=32,pmem=6g
#PBS -l walltime=96:00:00
#PBS -q long
#PBS -j oe

kraken2/kraken2-build --build --db full_ref --threads 32

