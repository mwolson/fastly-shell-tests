#!/bin/bash

grep_cmd="$(which grep) -E"; if test $? -ne 0; then echo "Error: grep not found"; exit 1; fi
sed_cmd="$(which sed) -r"; if test $? -ne 0; then echo "Error: sed not found"; exit 1; fi
if test "$(echo n | $sed_cmd 's/(Y|N)/y/i' 2>/dev/null)" != "y"; then
    sed_cmd="$(which perl) -pe"; if test $? -ne 0; then echo "Error: perl not found"; exit 1; fi
fi

function grep() {
    $grep_cmd "$@"
}

function sed() {
    $sed_cmd "$@"
}

function _reset_assertion_state() {
    addl_text=
    side_a=
    side_a_text=
}

function define_side_a() {
    side_a=$1
}

function define_side_a_text() {
    side_a_text=$1
}

function define_addl_text() {
    addl_text=$1
}

function get_side_a() {
    echo -n "$side_a"
}

function get_side_a_text() {
    echo -n "$side_a_text"
}

function get_addl_text() {
    echo -n "$addl_text"
}

_reset_assertion_state

function echo_quoted() {
    local needs_quote="[[:space:]&|\"]"
    for i in "$@"; do
        if [[ $i =~ $needs_quote ]]; then
            i=\'$i\'
        elif test -z "$i"; then
            i=\'\'
        fi
        echo -n " $i"
    done
}

function first_line() {
    head -n 1 | tr -d '\r\n'
}

function remove_last_line() {
    sed '$ d'
}

function describe() {
    echo "* $@"
}

function it() {
    echo "  - it $@"
}

function soft_fail() {
    echo "$@"
    if test -n "$addl_text"; then
        echo -e "\n${addl_text}"
    fi
    echo
}

function fail() {
    soft_fail "$@"
    exit 1
}

function expect() {
    define_side_a "$1"
    define_side_a_text "\"$side_a\""
}

function to_be_empty() {
    if test -n "$side_a"; then
        fail "Expected $side_a_text to be empty but it was not"
    fi
}

function to_not_be_empty() {
    if test -z "$side_a"; then
        fail "Expected $side_a_text to not be empty but it was"
    fi
}

function to_equal() {
    to_not_be_empty
    local side_b=$1
    if test "$side_a" != "$side_b"; then
        fail "Expected $side_a_text to equal \"${side_b}\" but it did not"
    fi
}

function is_numeric() {
    local numeric='^[0-9]+$'
    [[ "$1" =~ $numeric ]]
}

function to_be_numeric() {
    if ! is_numeric "$side_a"; then
        fail "Expected $side_a_text to be a numeric value but it was not"
    fi
}

function to_be_greater_than() {
    to_be_numeric
    if ! is_numeric "$1"; then
        fail "Expected 1st argument \"$1\" to be a numeric value but it was not"
    elif test "$side_a" -le "$1"; then
        fail "Expected $side_a_text to be greater than $1 but it was not"
    fi
}

function to_be_less_than() {
    to_be_numeric
    if ! is_numeric "$1"; then
        fail "Expected 1st argument \"$1\" to be a numeric value but it was not"
    elif test "$side_a" -ge "$1"; then
        fail "Expected $side_a_text to be less than $1 but it was not"
    fi
}

function to_be_between() {
    to_be_numeric
    if ! is_numeric "$1"; then
        fail "Expected 1st argument \"$1\" to be a numeric value but it was not"
    elif ! is_numeric "$2"; then
        fail "Expected 2nd argument \"$2\" to be a numeric value but it was not"
    elif test "$side_a" -lt "$1" || test "$side_a" -gt "$2"; then
        fail "Expected $side_a_text to be within $1 and $2 but it was not"
    fi
}

function to_contain() {
    if [[ "$side_a" != *"$1"* ]]; then
        fail "Expected $side_a_text to contain \"$1\" but it did not"
    fi
}

function to_match() {
    if ! <<< "$side_a" grep -i "$1" > /dev/null; then
        fail "Expected $side_a_text to match \"$1\" but it did not"
    fi
}

