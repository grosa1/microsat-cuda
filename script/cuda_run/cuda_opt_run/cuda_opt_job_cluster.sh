#!/bin/bash

cd /scratch/gp1y10/dimacs/
source /scratch/gp1y10/dimacs/clone20_91.sh
echo "running 20_91" 
cd /scratch/gp1y10/dimacs/
source /scratch/gp1y10/dimacs/cuda_runall.sh sat/20_91 mcuda_opt mcuda_opt 1000 1000 2000
source /scratch/gp1y10/dimacs/rm_all.sh /scratch/gp1y10/dimacs/sat/20_91/

cd /scratch/gp1y10/dimacs/
source /scratch/gp1y10/dimacs/clone50_218.sh
echo "running 50_218"
cd /scratch/gp1y10/dimacs/
source /scratch/gp1y10/dimacs/cuda_runall.sh sat/50_218 mcuda_opt mcuda_opt 3500 1000 2000
source /scratch/gp1y10/dimacs/rm_all.sh /scratch/gp1y10/dimacs/sat/50_218/

cd /scratch/gp1y10/dimacs/
source /scratch/gp1y10/dimacs/clone75_325.sh
echo "running 75_325"
cd /scratch/gp1y10/dimacs/
source /scratch/gp1y10/dimacs/cuda_runall.sh sat/75_325 mcuda_opt mcuda_opt 25000 2000 4000
source /scratch/gp1y10/dimacs/rm_all.sh /scratch/gp1y10/dimacs/sat/75_325/

cd /scratch/gp1y10/dimacs/
source /scratch/gp1y10/dimacs/clone100_430.sh
echo "running 100_430"
cd /scratch/gp1y10/dimacs/
source /scratch/gp1y10/dimacs/cuda_runall.sh sat/100_430 mcuda_opt mcuda_opt 40000 2000 4000
source /scratch/gp1y10/dimacs/rm_all.sh /scratch/gp1y10/dimacs/sat/100_430/

cd /scratch/gp1y10/dimacs/
source /scratch/gp1y10/dimacs/clone125_538.sh
echo "running 125_538"
cd /scratch/gp1y10/dimacs/
source /scratch/gp1y10/dimacs/cuda_runall.sh sat/125_538 mcuda_opt mcuda_opt 125000 3000 5000
source /scratch/gp1y10/dimacs/rm_all.sh /scratch/gp1y10/dimacs/sat/125_538/

cd /scratch/gp1y10/dimacs/
source /scratch/gp1y10/dimacs/clone150_645.sh
echo "running 150_645"
cd /scratch/gp1y10/dimacs/
source /scratch/gp1y10/dimacs/cuda_runall.sh sat/150_645 mcuda_opt mcuda_opt 420000 4000 6000
source /scratch/gp1y10/dimacs/rm_all.sh /scratch/gp1y10/dimacs/sat/150_645/
