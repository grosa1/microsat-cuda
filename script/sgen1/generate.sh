# sat formula generator
n=100
mkdir gen$n

for i in {1..1000}; do
    echo "generate $i"
    ./sgen1 -sat -n 100 -s $i > gen$n/sat$n\_$i.cnf
done 
