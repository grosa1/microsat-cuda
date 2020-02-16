#!/bin/bash

####################################
#  Iridis 5 slurm script template  #
#                                  #
#  Submit script: sbatch filename  #
#                                  #
####################################

#SBATCH --job-name=uf50    # Job name
#SBATCH --output=jobs/uf50.log # Stdout (%j expands to jobId)
#SBATCH --error=jobs/uf50.err # Stderr (%j expands to jobId)
#SBATCH --ntasks-per-node=1     # Tasks per node
#SBATCH --ntasks=1     # Number of processor cores (i.e. tasks)
#SBATCH --nodes=1     # Number of nodes requested
#SBATCH --cpus-per-task=1     # Threads per task
#SBATCH --time=30:00   # walltime
#SBATCH --begin=now

#SBATCH -p gtx1080
#SBATCH --gres=gpu:1

# load necessary modules
module load cuda

## Running serial applications##
#nvcc -o main microsat_cuda.cu
/home/gp1y10/cuda_sat/microsat-cuda/main /home/gp1y10/cuda_sat/microsat-cuda/dimacs/sat/uf50-218
