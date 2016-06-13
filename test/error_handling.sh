#!/bin/bash

. $(dirname $0)/../setup.sh

describe "Error-handling"

keep_headers "Age|X-Cache|X-Served-By|X-Timer|(X-)?Proxy-Authorization|fastly-ff"

function record_with_query_params() {
    record_curl "${target_url}/host/${target_event_id}/facets?by=inventorytypes%20offertypes%20accessibility&q=available&apikey=${target_apikey}&apisecret=${target_apisecret}" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed
}

function record_with_wrong_api_secret() {
    record_curl "${target_url}/host/${target_event_id}/facets?by=inventorytypes%20offertypes%20accessibility&q=available&apikey=${target_apikey}&apisecret=wrong" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed
}

it "misses on the first request with apikey/apisecret query params"

until_fresh_curl_object 3 record_with_query_params

expect_header X-Cache; to_match MISS$
miss_age=$(get_header Age)

it "cache hits on the second request"

record_with_query_params

expect_header X-Cache; to_match HIT$
expect_header Age; to_be_between $((miss_age)) $((miss_age + 1))
expect_origin_response_time; to_be_less_than 25

it "misses on a wrong api secret"

record_with_wrong_api_secret

expect_header Server; to_equal nginx
expect_header Age; to_be_empty
expect_header X-Cache; to_match MISS$

it "does not cache the request containing wrong api secret"

record_with_wrong_api_secret

expect_header Server; to_equal nginx
expect_header Age; to_be_empty
expect_header X-Cache; to_match MISS$
