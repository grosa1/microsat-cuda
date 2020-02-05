# lancio sequenziale di sat solver

dir=$1
mcuda=$2
log_name=$3
mem=$4
learn_mem=$5
learn_clauses=$6
i=0

for f in $dir/*; do
   ((i++))
   echo $log_name - $i: $f formulas 
    timeout 60m sh -c "time ./$mcuda $f $mem $learn_mem $learn_clauses" > cuda_logs/mcuda$log_name-$i.txt
    echo
done
