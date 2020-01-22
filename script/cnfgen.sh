dir=$1
vars=$2
clauses=$3

mkdir $dir/1000

for i in {1..1000}; do
echo generate $i - 3 $2 $3
cnfgen randkcnf 3 $2 $3 > $dir/1000/sat$i.cnf
done 
