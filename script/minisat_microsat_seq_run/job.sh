echo run microsat
./runall.sh sat microsat_seq.sh microsat

echo run minisat
./runall.sh sat minisat_seq.sh minisat

echo run cuda
./cuda_job.sh
