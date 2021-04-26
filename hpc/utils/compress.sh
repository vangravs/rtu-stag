#!/bin/bash
#PBS -N compress outputs
#PBS -l nodes=1:ppn=8,pmem=6g
#PBS -l walltime=24:00:00
#PBS -q long
#PBS -j oe

zip -r outputs.zip outputs/
