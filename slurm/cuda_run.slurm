#!/bin/bash

####################################
#  Iridis 5 slurm script template  #
#                                  #
#  Submit script: sbatch filename  #
#                                  #
####################################
#SBATCH -p gpu
# #SBATCH -p gtx1080 
#SBATCH --gres=gpu:1

#SBATCH --job-name=mcuda75    # Job name
#SBATCH --output=/home/gp1y10/cuda_sat/microsat-cuda/cuda_jobs/mcuda75.log # Stdout (%j expands to jobId)
#SBATCH --error=/home/gp1y10/cuda_sat/microsat-cuda/cuda_jobs/mcuda75.err # Stderr (%j expands to jobId)
#SBATCH --ntasks-per-node=1     # Tasks per node
#SBATCH --ntasks=1     # Number of processor cores (i.e. tasks)
#SBATCH --nodes=1     # Number of nodes requested
#SBATCH --cpus-per-task=40     # Threads per task
#SBATCH --time=30:00   # walltime
#SBATCH --begin=now

# load necessary modules
module load cuda

## Running serial applications##
nvcc -o /home/gp1y10/cuda_sat/microsat-cuda/mcuda /home/gp1y10/cuda_sat/microsat-cuda/microsat_cuda.cu
/home/gp1y10/cuda_sat/microsat-cuda/mcuda /home/gp1y10/cuda_sat/microsat-cuda/dimacs/sat/75_325/1000 20000 1000 2000
