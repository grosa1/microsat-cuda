#run all
dir=$1
sat_seq_bin=$2
log_name=$3
mkdir jobs/$log_name
n_formulas=(1000 2000 4000 8000 16000 32000 64000 128000)

for f in $dir/*; do
    for num in "${n_formulas[@]}"; do 
        formula_size=${f#*/}
        out_file=jobs/$log_name/$formula_size\_log$num\_$log_name.txt
        
        echo +++ START $formula_size $num > $out_file
        start=$(date +%s%3N)
        timeout 60m sh -c "sh $sat_seq_bin $f/$num >> $out_file"
        echo TOT_TIME_MILLS=$(( $(date +%s%3N) - $start )) >> $out_file
        echo +++ END >> $out_file
    done
done




