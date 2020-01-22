# sat formula generator

n=999999999999999999999999999999999999999878787899
mkdir factoring

for i in {1..100}; do
    echo "+++++++++ generate $i +++++++++"
    curl --data "target=${n}&type=factoring2&generate=Generate" https://toughsat.appspot.com/generate > factoring/sat$i.cnf
    sleep 2
done 
