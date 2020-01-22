# lancio sequenziale di sat solver

for f in $1/*.cnf; do
    /home/giovanni/microsat $f
    #minisat $f
    #/home/giovanni/Desktop/git/microsat-cuda-seq/mcuda_seq $f
done 
