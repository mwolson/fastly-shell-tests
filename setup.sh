#!/bin/bash

target_url="https://ismdsqa-tmol-co.global.ssl.fastly.net/api/ismds"
curl_args="--resolve ismdsqa-tmol-co.global.ssl.fastly.net:443:199.27.79.249"
keep_headers="Age|X-Cache|Access-Control-Allow-Origin|X-Served-By"

full=

function _reset_assertion_state() {
    addl_text=
    side_a=
    side_a_text=
}

_reset_assertion_state

function describe() {
    echo "* $@"
}

function it() {
    echo "  - it $@"
}

function record_curl() {
    full=$(curl -s -i $curl_args "$@" | grep -E "^(${keep_headers}):")
}

function get_header() {
    <<< "$full" grep "^$1: " | sed -r "s/^$1: //" | head -n 1 | tr -d '\r\n'
}

function expect() {
    side_a=$1
    side_a_text="\"$side_a\""
}

function expect_header() {
    local header_name=$1
    side_a=$(get_header "$header_name")
    side_a_text="header ${header_name} with value \"${side_a}\""
    addl_text="Response headers:\n${full}"
}

function fail() {
    echo "$@"
    if test -n "$addl_text"; then
        echo -e "\n$addl_text"
    fi
    echo
    exit 1
}

function to_equal() {
    local side_b=$1
    if test "$side_a" != "$side_b"; then
        fail "Expected $side_a_text to equal \"${side_b}\" but it does not"
    fi
    _reset_assertion_state
}

function to_be_between() {
    if test "$side_a" -lt "$1" || test "$side_a" -gt "$2"; then
        fail "Expected $side_a_text to be within $1 and $2 but it was not"
    fi
    _reset_assertion_state
}
