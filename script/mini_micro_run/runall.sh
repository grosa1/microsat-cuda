#run all
dir=$1
sat_seq_bin=$2
log_name=$3
mkdir jobs

i=0
for f in $dir/*; do
((i++))
echo ++++++ $log_name run $i: $f ++++++

echo 1000 formulas 
timeout 60m sh -c "time sh $sat_seq_bin $f/1000 > jobs/log1000_$i$log_name.txt"
echo

echo 2000 formulas 
timeout 60m sh -c "time sh $sat_seq_bin $f/2000 > jobs/log2000_$i$log_name.txt"
echo

echo 4000 formulas 
timeout 60m sh -c "time sh $sat_seq_bin $f/4000 > jobs/log4000_$i$log_name.txt"
echo

echo 8000 formulas 
timeout 60m sh -c "time sh $sat_seq_bin $f/8000 > jobs/log8000_$i$log_name.txt"
echo

echo 16000 formulas 
timeout 60m sh -c "time sh $sat_seq_bin $f/16000 > jobs/log16000_$i$log_name.txt"
echo

echo 32000 formulas 
timeout 60m sh -c "time sh $sat_seq_bin $f/32000 > jobs/log32000_$i$log_name.txt"
echo

echo 64000 formulas 
timeout 60m sh -c "time sh $sat_seq_bin $f/64000 > jobs/log64000_$i$log_name.txt"
echo
 
echo 128000 formulas 
timeout 60m sh -c "time sh $sat_seq_bin $f/128000 > jobs/log128000_$i$log_name.txt"
echo
done





