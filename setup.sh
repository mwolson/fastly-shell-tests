#!/bin/bash

modules=$(dirname "$BASH_SOURCE")/node_modules

. "$modules"/barrt/setup.sh
. "$modules"/barrt-curl/setup.sh

# Common QA/Staging/Production settings
target_description_id=IE5A
target_apikey=b462oi7fic6pehcdkzony5bxhe
target_apisecret=pquzpfrfz7zd2ylvtz3w5dtyse
target_proxy_auth_token="YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U="
expected_fastly_shield_time=50

function qa_profile() {
    origin_host="https://services-intqa.ticketmaster.net"
    origin_url="${origin_host}/api/ismds"
    geometry_shard=3
    target_host="https://services-fastly.ticketmaster.net"
    target_url="${target_host}/api/ismds"
    target_event_id=3F004E88E462B5CF
}

function staging_profile() {
    origin_host="https://services.ticketmaster.com"
    origin_url="${origin_host}/api/ismds"
    geometry_shard=3
    target_host="https://services-staging.ticketmaster.com"
    target_url="${target_host}/api/ismds"
    target_event_id=01004F90D7D94571
}

function production_profile() {
    origin_host="https://jphx1services.ticketmaster.com"
    origin_url="${origin_host}/api/ismds"
    geometry_shard=3
    target_host="https://services.ticketmaster.com"
    target_url="${target_host}/api/ismds"
    target_event_id=01004F90D7D94571
}

if test "$TEST_PROFILE" = "qa"; then
    qa_profile
elif test "$TEST_PROFILE" = "production"; then
    production_profile
elif test "$TEST_PROFILE" = "staging"; then
    staging_profile
elif test -z "$TEST_PROFILE"; then
    echo "Using QA profile; change this by setting the TEST_PROFILE environment variable like:"
    echo "  $ TEST_PROFILE=production ./runner.sh"
    echo -e "\nAvailable profiles: qa, staging, production\n"
    qa_profile
else
    echo "Error: Unrecognized value of TEST_PROFILE environment variable: '$TEST_PROFILE'"
    echo "Available profiles: qa, staging, production"
    exit 1
fi

function get_random_token() {
    echo "test-$(basename $0)-$RANDOM"
}

function ensure_cache_miss() {
    define_curl_token "TMPS-IdentityToken: $(get_random_token)"
}

function count_lines() {
    wc -l | awk '{ print $1 }'
}

function describe() {
    echo "* $@"
    ensure_cache_miss
}

function expect_origin_response_time() {
    expect_header X-Timer; to_match ",VS.*,VE"
    local timer_value=$(get_header X-Timer)
    local start=$(<<< "$timer_value" sed 's/.*,VS([0-9]+)(,|$).*/\1/i')
    local end=$(<<< "$timer_value" sed 's/.*,VE([0-9]+)(,|$).*/\1/i')
    define_side_a "$((end - start))"
    define_side_a_text "response time of origin server (${side_a}ms)"
}
