#!/bin/bash

. $(dirname $0)/../setup.sh

describe "Error-handling"

keep_headers "Age|X-Cache|X-Served-By|X-Timer|(X-)?Proxy-Authorization|fastly-ff"

function record_with_query_params() {
    record_curl "${target_url}/host/26004E4DF73E808C/facets?by=inventorytypes%20offertypes%20accessibility&q=available&apikey=b462oi7fic6pehcdkzony5bxhe&apisecret=pquzpfrfz7zd2ylvtz3w5dtyse" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Referer: http://fastly-hackathon.tmdev.co/event/26004E4DF73E808C?fg=ism' -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed
}

function record_with_wrong_api_secret() {
    record_curl "${target_url}/host/26004E4DF73E808C/facets?by=inventorytypes%20offertypes%20accessibility&q=available&apikey=b462oi7fic6pehcdkzony5bxhe&apisecret=wrong" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Referer: http://fastly-hackathon.tmdev.co/event/26004E4DF73E808C?fg=ism' -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed
}

it "misses on the first request with apikey/apisecret query params"

record_with_query_params

expect_header X-Cache; to_match MISS$

it "cache hits on the second request"

wait_on_fastly_cache
record_with_query_params

expect_header X-Cache; to_match HIT$
expect_header Age; to_be_between 1 10
expect_origin_response_time; to_be_less_than 25

it "misses on a wrong api secret"

record_with_wrong_api_secret

expect_header X-Cache; to_match MISS$
expect_header Server; to_equal nginx

it "does not cache the request containing wrong api secret"

wait_on_fastly_cache
record_with_wrong_api_secret

expect_header X-Cache; to_match MISS$
expect_header Server; to_equal nginx
