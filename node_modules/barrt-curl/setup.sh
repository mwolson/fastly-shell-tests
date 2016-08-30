#!/bin/bash

modules=$(dirname "$(caller | awk '{ print $2; }')")/node_modules

if test ! -f "$modules"/barrt/setup.sh; then echo "Error: peer dependency 'barrt' not installed"; exit 1; fi
if ! define_side_a 2>/dev/null; then echo "Error: 'barrt' was not sourced yet"; exit 1; fi

curl_token=
_inspect_next_curl=
kept_headers=".*"
unnarrowed_response=
full=

function define_curl_token() {
    curl_token=$1
}

function keep_headers() {
    kept_headers=$1
}

function inspect_next_curl() {
    _inspect_next_curl=true
}

function record_curl() {
    _reset_assertion_state
    if test -n "$curl_token"; then
        full=$(curl -s -i $curl_args -H "$curl_token" "$@" | tr -d '\r')
    else
        full=$(curl -s -i $curl_args "$@" | tr -d '\r')
    fi
    local status=$?
    unnarrowed_response=$full

    if test -n "$_inspect_next_curl"; then
        _inspect_next_curl=
        addl_text=$full
        if test -n "$curl_token"; then
            soft_fail "Inspecting curl command invoked like:$(echo_quoted curl -# -vv $curl_args -H "$curl_token" "$@")"
        else
            soft_fail "Inspecting curl command invoked like:$(echo_quoted curl -# -vv $curl_args "$@")"
        fi
    fi
    if test $status -ne 0; then
        addl_text=$full
        fail "curl command failed with status code $status"
    fi
}

function stash_curl() {
    _curl_stash=$full
}

function pop_curl() {
    full=$_curl_stash
    unnarrowed_response=$full
}

function get_response() {
    echo "$full"
}

function get_http_status() {
    <<< "$full" first_line | sed 's!^HTTP/.+([0-9][0-9][0-9]).+$!\1!'
}

function get_headers() {
    <<< "$full" awk '!NF{body=1;next}!body'
}

function get_header() {
    get_headers | grep -i "^$1: " | sed "s/^$1: //i" | first_line
}

function get_response_body() {
    <<< "$full" awk '!NF{body++}!NF && body==1{next}body'
}

# The first response will be "1", not "0"
function use_nth_response() {
    local response_index=$1
    full=$(<<< "$unnarrowed_response" awk '$1 ~ /^HTTP\//{response++}response=='"${response_index}")
}

function get_cache_max_age() {
    <<< "$(get_header Cache-Control)" sed 's/.*max-age=([0-9]+)$/\1/i'
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

function replace_in_response() {
    full=$(<<< "$full" sed "$1")
}

function expect_http_status() {
    define_side_a "$(get_http_status)"
    define_side_a_text "HTTP response code of \"${side_a}\""
    local response_headers=$(get_headers | grep -i "^(${kept_headers}):")
    define_addl_text "Status line:\n$(get_response | first_line)\n\nResponse headers:\n${response_headers}"
}

function expect_header() {
    local header_name=$1
    define_side_a "$(get_header "$header_name")"
    define_side_a_text "header ${header_name} with value \"${side_a}\""
    define_addl_text "Response headers:\n$(get_headers | grep -i "^(${kept_headers}):")"
}

function expect_response_body() {
    define_side_a "$(get_response_body)"
    define_side_a_text "response body"
    local response_headers=$(get_headers | grep -i "^(${kept_headers}):")
    define_addl_text "Response headers:\n${response_headers}\n\nResponse body:\n${side_a}"
}
