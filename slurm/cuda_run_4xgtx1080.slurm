#!/bin/bash

####################################
#  Iridis 5 slurm script template  #
#                                  #
#  Submit script: sbatch filename  #
#                                  #
####################################
#SBATCH -p gtx1080 --gres=gpu:4

#SBATCH --job-name=multi100_430    # Job name
#SBATCH --output=/home/gp1y10/cuda_sat/microsat-cuda/cuda_jobs/gtx1080/multi100_430.log # Stdout (%j expands to jobId)
#SBATCH --error=/home/gp1y10/cuda_sat/microsat-cuda/cuda_jobs/gtx1080/multi100_430.err # Stderr (%j expands to jobId)
#SBATCH --ntasks-per-node=1     # Tasks per node
#SBATCH --ntasks=1     # Number of processor cores (i.e. tasks)
#SBATCH --nodes=1     # Number of nodes requested
#SBATCH --cpus-per-task=1     # Threads per task
#SBATCH --time=90:00   # walltime
#SBATCH --begin=now

# load necessary modules
module load cuda

## Running serial applications ##
rm /home/gp1y10/cuda_sat/microsat-cuda/multi
nvcc -o /home/gp1y10/cuda_sat/microsat-cuda/multi /home/gp1y10/cuda_sat/microsat-cuda/microsat_cuda_multi_gpu.cu

echo '\n\n+++ START 100_430 1000'
start=$(date +%s%3N)
/home/gp1y10/cuda_sat/microsat-cuda/multi /scratch/gp1y10/dimacs/sat/100_430/1000 100000 20000 40000 4
echo TOT_TIME_MILLS=$(( $(date +%s%3N) - $start )) 
echo '+++ END'

echo '\n\n+++ START 100_430 2000'
start=$(date +%s%3N)
/home/gp1y10/cuda_sat/microsat-cuda/multi /scratch/gp1y10/dimacs/sat/100_430/2000 100000 20000 40000 4
echo TOT_TIME_MILLS=$(( $(date +%s%3N) - $start )) 
echo '+++ END'

echo '\n\n+++ START 100_430 4000'
start=$(date +%s%3N)
/home/gp1y10/cuda_sat/microsat-cuda/multi /scratch/gp1y10/dimacs/sat/100_430/4000 100000 20000 40000 4
echo TOT_TIME_MILLS=$(( $(date +%s%3N) - $start )) 
echo '+++ END'

echo '\n\n+++ START 100_430 8000'
start=$(date +%s%3N)
/home/gp1y10/cuda_sat/microsat-cuda/multi /scratch/gp1y10/dimacs/sat/100_430/8000 100000 20000 40000 4
echo TOT_TIME_MILLS=$(( $(date +%s%3N) - $start )) 
echo '+++ END'

echo '\n\n+++ START 100_430 16000'
start=$(date +%s%3N)
/home/gp1y10/cuda_sat/microsat-cuda/multi /scratch/gp1y10/dimacs/sat/100_430/16000 100000 20000 40000 4
echo TOT_TIME_MILLS=$(( $(date +%s%3N) - $start )) 
echo '+++ END'

echo '\n\n+++ START 100_430 32000'
start=$(date +%s%3N)
/home/gp1y10/cuda_sat/microsat-cuda/multi /scratch/gp1y10/dimacs/sat/100_430/32000 100000 20000 40000 4
echo TOT_TIME_MILLS=$(( $(date +%s%3N) - $start )) 
echo '+++ END'

echo '\n\n+++ START 100_430 64000'
start=$(date +%s%3N)
/home/gp1y10/cuda_sat/microsat-cuda/multi /scratch/gp1y10/dimacs/sat/100_430/64000 100000 20000 40000 4
echo TOT_TIME_MILLS=$(( $(date +%s%3N) - $start )) 
echo '+++ END'

echo '\n\n+++ START 100_430 128000'
start=$(date +%s%3N)
/home/gp1y10/cuda_sat/microsat-cuda/multi /scratch/gp1y10/dimacs/sat/100_430/128000 100000 20000 40000 4
echo TOT_TIME_MILLS=$(( $(date +%s%3N) - $start ))
echo '+++ END'
