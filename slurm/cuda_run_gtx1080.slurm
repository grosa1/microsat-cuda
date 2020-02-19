#!/bin/bash

####################################
#  Iridis 5 slurm script template  #
#                                  #
#  Submit script: sbatch filename  #
#                                  #
####################################
#SBATCH -p gtx1080 --gres=gpu:1

#SBATCH --job-name=mcuda_opt    # Job name
#SBATCH --output=/home/gp1y10/cuda_sat/microsat-cuda/cuda_jobs/gtx1080/mcuda_opt.log # Stdout (%j expands to jobId)
#SBATCH --error=/home/gp1y10/cuda_sat/microsat-cuda/cuda_jobs/gtx1080/mcuda_opt.err # Stderr (%j expands to jobId)
#SBATCH --ntasks-per-node=1     # Tasks per node
#SBATCH --ntasks=1     # Number of processor cores (i.e. tasks)
#SBATCH --nodes=1     # Number of nodes requested
#SBATCH --cpus-per-task=1     # Threads per task
#SBATCH --time=1440:00   # walltime
#SBATCH --begin=now

# load necessary modules
module load cuda

## Running serial applications##
nvcc -o /scratch/gp1y10/dimacs/mcuda_opt /home/gp1y10/cuda_sat/microsat-cuda/microsat_cuda_malloc_opt.cu
cd /scratch/gp1y10/dimacs/
sh cuda_opt_job_cluster.sh
