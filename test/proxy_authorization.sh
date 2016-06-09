#!/bin/bash

. $(dirname $0)/../setup.sh

describe "Query parameters and Proxy-Authorization are normalized to same cache key"

keep_headers "Age|X-Cache|X-Served-By|X-Timer|(X-)?Proxy-Authorization|fastly-ff"

function record_with_query_params() {
    record_curl "${target_url}/host/26004E4DF73E808C/facets?by=inventorytypes%20offertypes%20accessibility&q=available&apikey=b462oi7fic6pehcdkzony5bxhe&apisecret=pquzpfrfz7zd2ylvtz3w5dtyse" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Referer: http://fastly-hackathon.tmdev.co/event/26004E4DF73E808C?fg=ism' -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed
}

function record_with_x_proxy_auth() {
    record_curl "${target_url}/host/26004E4DF73E808C/facets?by=inventorytypes%20offertypes%20accessibility&q=available" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Referer: http://fastly-hackathon.tmdev.co/event/26004E4DF73E808C?fg=ism' -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed -H 'X-Proxy-Authorization: Basic YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U='
}

function record_with_proxy_auth() {
    record_curl "${target_url}/host/26004E4DF73E808C/facets?by=inventorytypes%20offertypes%20accessibility&q=available" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Referer: http://fastly-hackathon.tmdev.co/event/26004E4DF73E808C?fg=ism' -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed -H 'Proxy-Authorization: Basic YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U='
}

it "misses on the first request with apikey/apisecret query params"

record_with_query_params

expect_header X-Cache; to_equal MISS

sleep 5

it "5 seconds later, hits on the second request"

record_with_query_params

expect_header X-Cache; to_equal HIT
expect_header Age; to_be_between 4 7
expect_origin_response_time; to_be_less_than 25

it "hits on an X-Proxy-Authorization request"

record_with_x_proxy_auth

expect_header X-Cache; to_equal HIT
expect_header Age; to_be_between 4 8
expect_origin_response_time; to_be_less_than 25

it "hits on a Proxy-Authorization request"

record_with_proxy_auth

expect_header X-Cache; to_equal HIT
expect_header Age; to_be_between 4 9
expect_origin_response_time; to_be_less_than 25
