#!/bin/bash

curl_max_age=60
origin_url="https://services-intqa.ticketmaster.net/api/ismds"
target_url="https://services-fastly.ticketmaster.net/api/ismds"
curl_token=
_inspect_next_curl=
kept_headers="Age|X-Cache|Access-Control-Allow-Origin|X-Served-By"

full=

grep="grep -E"
if test "$(echo n | sed -r 's/(Y|N)/y/i' 2>/dev/null)" = "y"; then
    sed="sed -r"
else
    sed="perl -pe"
fi

function _reset_assertion_state() {
    addl_text=
    side_a=
    side_a_text=
}

_reset_assertion_state

function describe() {
    echo "* $@"
    curl_token="TMPS-IdentityToken: test-$(basename $0)-$RANDOM"
}

function it() {
    echo "  - it $@"
}

function keep_headers() {
    kept_headers=$1
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

function echo_quoted() {
    local needs_quote="[[:space:]&|\"]"
    for i in "$@"; do
        if [[ $i =~ $needs_quote ]]; then
            i=\'$i\'
        fi
        echo -n " $i"
    done
}

function record_curl() {
    _reset_assertion_state
    full=$(curl -s -i $curl_args -H "$curl_token" "$@")
    local status=$?
    if test -n "$_inspect_next_curl"; then
        _inspect_next_curl=
        addl_text=$(curl -# -vv $curl_args "$@" 2> >($grep '^[*<>]'))
        soft_fail "Inspecting curl command invoked like:$(echo_quoted curl -# -vv $curl_args "$@")"
    elif test $status -ne 0; then
        addl_text=$(curl -# -vv $curl_args "$@" 2>&1)
        fail "curl command failed with status code $status"
    fi
}

function until_fresh_curl_object() {
    local test_duration=$1
    local want_age_lt=$((curl_max_age - test_duration))
    shift
    "$@"
    until test -z "$(get_header Age)" || test $(get_header Age) -lt $want_age_lt; do
        sleep 1
        "$@"
    done
}

function stash_curl() {
    _curl_stash=$full
}

function pop_curl() {
    full=$_curl_stash
}

function inspect_next_curl() {
    _inspect_next_curl=true
}

function response() {
    echo "$full"
}

function first_line() {
    head -n 1 | tr -d '\r\n'
}

function get_header() {
    <<< "$full" $grep -i "^$1: " | $sed "s/^$1: //i" | first_line
}

function expect() {
    side_a=$1
    side_a_text="\"$side_a\""
}

function expect_origin_response_time() {
    local timer_value=$(get_header X-Timer)
    local start=$(<<< "$timer_value" $sed "s/.*,VS([0-9]+)(,|$).*/\1/i")
    local end=$(<<< "$timer_value" $sed "s/.*,VE([0-9]+)(,|$).*/\1/i")
    side_a=$(expr "$end" - "$start")
    side_a_text="response time of origin server (${side_a}ms)"
}

function expect_header() {
    local header_name=$1
    side_a=$(get_header "$header_name")
    side_a_text="header ${header_name} with value \"${side_a}\""
    addl_text="Response headers:\n$(<<< "$full" $grep -i "^(${kept_headers}):")"
}

function to_equal() {
    local side_b=$1
    if test "$side_a" != "$side_b"; then
        fail "Expected $side_a_text to equal \"${side_b}\" but it did not"
    fi
}

function to_be_empty() {
    if test -n "$side_a"; then
        fail "Expected $side_a_text to be empty but it was not"
    fi
}

function to_be_greater_than() {
    if test "$side_a" -le "$1"; then
        fail "Expected $side_a_text to be greater than $1 but it was not"
    fi
}

function to_be_less_than() {
    if test "$side_a" -ge "$1"; then
        fail "Expected $side_a_text to be less than $1 but it was not"
    fi
}

function to_be_between() {
    if test "$side_a" -lt "$1" || test "$side_a" -gt "$2"; then
        fail "Expected $side_a_text to be within $1 and $2 but it was not"
    fi
}

function to_contain() {
    if [[ "$side_a" != *"$1"* ]]; then
        fail "Expected $side_a_text to contain \"$1\" but it did not"
    fi
}

function to_match() {
    if ! <<< "$side_a" $grep -i "$1" > /dev/null; then
        fail "Expected $side_a_text to match \"$1\" but it did not"
    fi
}
