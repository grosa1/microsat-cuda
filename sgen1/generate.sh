# sat formula generator

for i in {1..1000}; do
    ./sgen1 -sat -n 140 -s $i > gen/sat$i.cnf
done 
