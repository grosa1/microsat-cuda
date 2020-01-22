# lancio sequenziale di sat solver
i=0
for f in *.cnf; do
((i++))
cp $f sat2$i.cnf
    #/home/giovanni/microsat $f
    #minisat $f
    #/home/giovanni/Desktop/git/microsat-cuda-seq/mcuda_seq $f
done 
