#!/bin/bash

####################################
#  Iridis 5 slurm script template  #
#                                  #
#  Submit script: sbatch filename  #
#                                  #
####################################

#SBATCH --job-name=microsat20    # Job name
#SBATCH --output=jobs/microsat20.log # Stdout (%j expands to jobId)
#SBATCH --error=jobs/microsat20.err # Stderr (%j expands to jobId)
#SBATCH --ntasks-per-node=1     # Tasks per node
#SBATCH --ntasks=1     # Number of processor cores (i.e. tasks)
#SBATCH --nodes=1     # Number of nodes requested
#SBATCH --cpus-per-task=40     # Threads per task
#SBATCH --time=30:00   # walltime
#SBATCH --begin=now

# load necessary modules
module load jdk

## Running serial applications##
java -jar sat_multi_thread.jar /home/gp1y10/cuda_sat/microsat/microsat /home/gp1y10/cuda_sat/microsat-cuda/dimacs/sat/uf20-91 cnf
