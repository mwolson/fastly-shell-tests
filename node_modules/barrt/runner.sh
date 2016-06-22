#!/bin/bash

pass_cnt=0
fail_cnt=0
skip_cnt=0
fail_list=""

for scenario in test/*; do
    if test ! -x "$scenario"; then
        (( skip_cnt++ ))
        echo "> Skipping $scenario since it is not executable"
    elif "$scenario"; then
        (( pass_cnt++ ))
    else
        (( fail_cnt++ ))
        fail_list="${fail_list}\n  - ${scenario}"
    fi
done

echo -e "\nTest Summary:"
echo -e "  - ${pass_cnt} scenario(s) passed"
echo -e "  - ${skip_cnt} scenario(s) skipped"
echo -e "  - ${fail_cnt} scenario(s) failed"

if test "$fail_cnt" -gt 0; then
    echo -e -n '\nFailures:'
    echo -e "$fail_list"
    exit 1
else
    exit 0
fi
