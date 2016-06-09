#!/bin/bash

pass_cnt=0
fail_cnt=0
skip_cnt=0
fail_list=""

for test_case in test/*; do
    if test ! -x "$test_case"; then
        (( skip_cnt++ ))
        echo "> Skipping $test_case since it is not executable"
    elif "$test_case"; then
        (( pass_cnt++ ))
    else
        (( fail_cnt++ ))
        fail_list="${fail_list}\n  - ${test_case}"
    fi
done

echo -e "\nTest Summary:"
echo -e "  - ${pass_cnt} test case(s) passed"
echo -e "  - ${skip_cnt} test case(s) skipped"
echo -e "  - ${fail_cnt} test case(s) failed"

if test "$fail_cnt" -gt 0; then
    echo -e -n '\nFailures:'
    echo -e "$fail_list"
    exit 1
else
    exit 0
fi
