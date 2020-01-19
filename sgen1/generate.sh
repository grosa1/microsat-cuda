# sat formula generator

mkdir gen20

for i in {1..1000}; do
    echo "generate $i"
    ./sgen1 -sat -n 20 -s $i > gen20/sat20_$i.cnf
done 
