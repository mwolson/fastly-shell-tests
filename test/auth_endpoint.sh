#!/bin/bash

. $(dirname $0)/../setup.sh

describe "/auth endpoint"

keep_headers "Age|X-Cache|X-Served-By|X-Timer|Access-Control-Allow-Origin"

function record_auth_with_header() {
    record_curl "${target_host}/auth" -d '{"schema":"urn:com.ticketmaster.services:schema:gateway:Authentication:1.0"}' -H "X-Api-Key: ${target_apikey}" --digest --user "${target_apikey}:${target_apisecret}" -H 'Content-Type: application/json' -H 'Pragma: no-cache' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' --compressed
}

record_auth_with_header

it "cache misses with a 401 on first request"

use_nth_response 1
expect_http_status; to_equal 401
expect_header X-Cache; to_match 'MISS, *MISS$'
expect_header Vary; to_be_empty
expect_header Access-Control-Allow-Origin; to_equal "http://fastly-hackathon.tmdev.co"

it "cache misses with a 200 and response body on automatic second request"

use_nth_response 2
expect_http_status; to_equal 200
expect_header X-Cache; to_match 'MISS, *MISS$'
expect_header Vary; to_be_empty
expect_header Access-Control-Allow-Origin; to_equal "http://fastly-hackathon.tmdev.co"
expect_response_body; to_not_be_empty
