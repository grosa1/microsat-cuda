# lancio sequenziale di sat solver

dir=$1
mcuda_bin=$2
log_name=$3
mem=$4
learn_mem=$5
learn_clauses=$6
mkdir jobs/$log_name

for f in $dir/*; do
    formula_size=${dir#*/}
    n_formulas=${f#*/}
    n_formulas=${n_formulas#*/}
    out_file=jobs/$log_name/$formula_size\_log$n_formulas\_$log_name.txt
    
    echo +++ START $formula_size $n_formulas > $out_file
    start=$(date +%s%3N)
    timeout 60m sh -c "./$mcuda_bin $f $mem $learn_mem $learn_clauses" >> $out_file
    echo TOT_TIME_MILLS=$(( $(date +%s%3N) - $start )) >> $out_file
    echo +++ END >> $out_file
done
