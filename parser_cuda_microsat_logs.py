import os, sys
from collections import defaultdict

log_file=sys.argv[1]

# extract filename from input file
out_name = (log_file.split('.')[0]).split(os.path.sep)[-1] + '.csv'

with open(log_file, 'r') as infile:
    lines = infile.readlines()
    # read file ids
    row_list = defaultdict(list)
    for line in lines:
        words = line.strip().split('=')
        if "file_" in words[0] and not row_list.get(words[0]) and len(words) < 4:
            row_list[words[0]].append(words[1])
    
    # read file id stats
    for line in lines:
        words = line.strip().split(',')
        file_id = words[0].split('=')[0]
        if "file_" in words[0] and row_list.get(file_id) and len(words) > 3:
            for word in words:
                row_list[file_id].append(word.split('=')[1])

# write csv
with open(out_name, 'w') as outfile:
    outfile.writelines('file_id,file_name,result,vars,clauses,mem_used(byte),conflicts,max_lemmas\n')
    for key in row_list.keys():
        outfile.write(key + ',' + ','.join(row_list[key]) + '\n')

    
        
            

