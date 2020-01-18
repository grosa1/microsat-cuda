import sys
import os

"""
Eliminazione dlla fine dei files dimacs di:

%
0

"""

parent_f = sys.argv[1]

for in_file in os.listdir(parent_f):
    current = os.path.join(parent_f, in_file)
    if os.path.isfile(current) and current.endswith('.cnf'):
        lines = "";
        with open(current, 'r') as infile:
            lines = infile.readlines()
        with open(current, 'w') as outfile:
            lines = lines[:len(lines)-3]
            outfile.write("".join(lines))


