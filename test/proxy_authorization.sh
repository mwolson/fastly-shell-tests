#!/bin/bash

. $(dirname $0)/../setup.sh

describe "Query parameters and Proxy-Authorization are normalized to same cache key"

keep_headers "Age|Cache-Control|X-Cache|X-Served-By|X-Timer|(X-)?Proxy-Authorization|fastly-ff"

function record_with_query_params() {
    record_curl "${target_url}/host/${target_event_id}/facets?by=inventorytypes%20offertypes%20accessibility&q=available&apikey=${target_apikey}&apisecret=${target_apisecret}" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed
}

function record_with_x_proxy_auth() {
    record_curl "${target_url}/host/${target_event_id}/facets?by=inventorytypes%20offertypes%20accessibility&q=available" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed -H "X-Proxy-Authorization: Basic ${target_proxy_auth_token}"
}

function record_with_proxy_auth() {
    record_curl "${target_url}/host/${target_event_id}/facets?by=inventorytypes%20offertypes%20accessibility&q=available" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed -H "Proxy-Authorization: Basic ${target_proxy_auth_token}"
}

it "misses on the first request with apikey/apisecret query params"

until_fresh_curl_object 5 record_with_query_params

expect_header X-Cache; to_match MISS
miss_age=$(get_header Age)

it "cache hits on the second request"

record_with_query_params

expect_header X-Cache; to_match HIT
expect_header Age; to_be_between $((miss_age)) $((miss_age + 2))
expect_origin_response_time; to_be_less_than $expected_fastly_shield_time

it "hits on an X-Proxy-Authorization request"

record_with_x_proxy_auth

expect_header X-Cache; to_match HIT
expect_header Age; to_be_between $((miss_age)) $((miss_age + 3))
expect_origin_response_time; to_be_less_than $expected_fastly_shield_time

it "hits on a Proxy-Authorization request"

record_with_proxy_auth

expect_header X-Cache; to_match HIT
expect_header Age; to_be_between $((miss_age)) $((miss_age + 4))
expect_origin_response_time; to_be_less_than $expected_fastly_shield_time
