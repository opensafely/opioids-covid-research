#1/bin/bash
echo 'dmd_id'
tail -q -n +2 codelists/*-dmd.csv | cut -d , -f 2 | sort | uniq
