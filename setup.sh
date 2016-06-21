#!/bin/bash

modules=$(dirname "$BASH_SOURCE")/node_modules

. "$modules"/barrt/setup.sh

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

function describe() {
    echo "* $@"
    curl_token="TMPS-IdentityToken: test-$(basename $0)-$RANDOM"
}

function keep_headers() {
    kept_headers=$1
}

function record_curl() {
    _reset_assertion_state
    full=$(curl -s -i $curl_args -H "$curl_token" "$@")
    local status=$?
    if test -n "$_inspect_next_curl"; then
        _inspect_next_curl=
        addl_text=$(curl -# -vv $curl_args "$@" 2> >(grep '^[*<>]'))
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
    <<< "$(get_header Cache-Control)" sed 's/.*max-age=([0-9]+)$/\1/i'
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
    full=$(<<< "$full" sed "$1")
}

function get_header() {
    <<< "$full" grep -i "^$1: " | sed "s/^$1: //i" | first_line
}

function expect_origin_response_time() {
    expect_header X-Timer; to_match ",VS.*,VE"
    local timer_value=$(get_header X-Timer)
    local start=$(<<< "$timer_value" sed 's/.*,VS([0-9]+)(,|$).*/\1/i')
    local end=$(<<< "$timer_value" sed 's/.*,VE([0-9]+)(,|$).*/\1/i')
    define_side_a "$((end - start))"
    define_side_a_text "response time of origin server (${side_a}ms)"
}

function expect_header() {
    local header_name=$1
    define_side_a "$(get_header "$header_name")"
    define_side_a_text "header ${header_name} with value \"${side_a}\""
    define_addl_text "Response headers:\n$(<<< "$full" grep -i "^(${kept_headers}):")"
}

function expect_response_body() {
    define_side_a "$(get_response_body)"
    define_side_a_text "response body"
    define_addl_text "Response headers:\n$(<<< "$full" grep -i "^(${kept_headers}):")\n\nResponse body:\n${side_a}"
}
