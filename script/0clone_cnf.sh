# creazione istanze
dir=$1

mkdir $dir/2000
mkdir $dir/4000
mkdir $dir/8000
mkdir $dir/16000
mkdir $dir/32000
mkdir $dir/64000
mkdir $dir/128000

echo clone 2000 $dir
i=0
for f in $dir/1000/*.cnf; do
((i++))
yes | cp -f $f $dir/2000
yes | cp -f $f $dir/2000/sat_a$i.cnf
done

echo clone 4000 $dir
i=0
for f in $dir/2000/*.cnf; do
((i++))
yes | cp -f $f $dir/4000
yes | cp -f $f $dir/4000/sat_b$i.cnf
done

echo clone 8000 $dir
i=0
for f in $dir/4000/*.cnf; do
((i++))
yes | cp -f $f $dir/8000
yes | cp -f $f $dir/8000/sat_c$i.cnf
done

echo clone 16000 $dir
i=0
for f in $dir/8000/*.cnf; do
((i++))
yes | cp -f $f $dir/16000
yes | cp -f $f $dir/16000/sat_d$i.cnf
done

echo clone 32000 $dir
i=0
for f in $dir/16000/*.cnf; do
((i++))
yes | cp -f $f $dir/32000
yes | cp -f $f $dir/32000/sat_e$i.cnf
done

echo clone 64000 $dir
i=0
for f in $dir/32000/*.cnf; do
((i++))
yes | cp -f $f $dir/64000
yes | cp -f $f $dir/64000/sat_f$i.cnf
done

echo clone 128000 $dir
i=0
for f in $dir/64000/*.cnf; do
((i++))
yes | cp -f $f $dir/128000
yes | cp -f $f $dir/128000/sat_g$i.cnf
done
