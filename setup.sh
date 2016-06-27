#!/bin/bash

modules=$(dirname "$BASH_SOURCE")/node_modules

. "$modules"/barrt/setup.sh
. "$modules"/barrt-curl/setup.sh

# QA settings
origin_url="https://services-intqa.ticketmaster.net/api/ismds"
target_url="https://services-fastly.ticketmaster.net/api/ismds"
target_event_id=26004E4DF73E808C
target_apikey=b462oi7fic6pehcdkzony5bxhe
target_apisecret=pquzpfrfz7zd2ylvtz3w5dtyse
target_proxy_auth_token="YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U="

# Production settings
# origin_url="https://services.ticketmaster.com/api/ismds"
# target_url="https://services-fastly.ticketmaster.com/api/ismds"
# target_event_id=01004F90D7D94571
# target_apikey=b462oi7fic6pehcdkzony5bxhe
# target_apisecret=pquzpfrfz7zd2ylvtz3w5dtyse
# target_proxy_auth_token="YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U="

function describe() {
    echo "* $@"
    define_curl_token "TMPS-IdentityToken: test-$(basename $0)-$RANDOM"
}

function expect_origin_response_time() {
    expect_header X-Timer; to_match ",VS.*,VE"
    local timer_value=$(get_header X-Timer)
    local start=$(<<< "$timer_value" sed 's/.*,VS([0-9]+)(,|$).*/\1/i')
    local end=$(<<< "$timer_value" sed 's/.*,VE([0-9]+)(,|$).*/\1/i')
    define_side_a "$((end - start))"
    define_side_a_text "response time of origin server (${side_a}ms)"
}
