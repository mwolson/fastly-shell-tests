#!/bin/bash

curl_token=
_inspect_next_curl=
kept_headers="Age|X-Cache|Access-Control-Allow-Origin|X-Served-By"
full=

# QA settings
origin_url="https://services-intqa.ticketmaster.net/api/ismds"
link_prefix="http://services-fastly.ticketmaster.net"
target_url="https://services-fastly.ticketmaster.net/api/ismds"
target_event_id=26004E4DF73E808C
target_apikey=b462oi7fic6pehcdkzony5bxhe
target_apisecret=pquzpfrfz7zd2ylvtz3w5dtyse
target_proxy_auth_token="YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U="

# Production settings
# origin_url="https://services.ticketmaster.com/api/ismds"
# link_prefix="http://services-fastly.ticketmaster.com"
# target_url="https://services-fastly.ticketmaster.com/api/ismds"
# target_event_id=01004F90D7D94571
# target_apikey=b462oi7fic6pehcdkzony5bxhe
# target_apisecret=pquzpfrfz7zd2ylvtz3w5dtyse
# target_proxy_auth_token="YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U="

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
    local age=
    local max_age=
    shift
    "$@"
    age=$(get_header Age); max_age=$(get_cache_max_age)
    until ! is_numeric "$age" || ! is_numeric "$max_age" || test $test_duration -lt $((max_age - age)); do
        sleep 1
        "$@"
        age=$(get_header Age); max_age=$(get_cache_max_age)
    done
}

function get_cache_max_age() {
    <<< "$(get_header Cache-Control)" $sed 's/.*max-age=([0-9]+)$/\1/i'
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

function get_response_body() {
    <<< "$full" tr -d '\r' | awk '!NF{body=1;next}body'
}

function replace_in_response() {
    full=$(<<< "$full" $sed "$1")
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
    expect_header X-Timer; to_match ",VS.*,VE"
    local timer_value=$(get_header X-Timer)
    local start=$(<<< "$timer_value" $sed 's/.*,VS([0-9]+)(,|$).*/\1/i')
    local end=$(<<< "$timer_value" $sed 's/.*,VE([0-9]+)(,|$).*/\1/i')
    side_a=$((end - start))
    side_a_text="response time of origin server (${side_a}ms)"
}

function expect_header() {
    local header_name=$1
    side_a=$(get_header "$header_name")
    side_a_text="header ${header_name} with value \"${side_a}\""
    addl_text="Response headers:\n$(<<< "$full" $grep -i "^(${kept_headers}):")"
}

function expect_response_body() {
    side_a=$(get_response_body)
    side_a_text="response body"
    addl_text="Response headers:\n$(<<< "$full" $grep -i "^(${kept_headers}):")\n\nResponse body:\n${side_a}"
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
    if ! <<< "$side_a" $grep -i "$1" > /dev/null; then
        fail "Expected $side_a_text to match \"$1\" but it did not"
    fi
}
