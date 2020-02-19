#!/bin/bash

# rimuove tutte le istanze trannela quella di 1000 formule per questioni di spazio

dir=$1

cd $dir
rm -rf 2000 4000 8000 16000 32000 64000 128000
