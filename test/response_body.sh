#!/bin/bash

. $(dirname $0)/../setup.sh

describe "Response body should not be modified in cache hits and cache misses"

keep_headers "Age|X-Cache|X-Served-By|Server|ETag"

function record_origin() {
    record_curl -k "${origin_url}/host/${target_event_id}/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H "X-Proxy-Authorization: Basic ${target_proxy_auth_token}" -H 'Set-Cookie: CMPS=Q5oQ2d5Dp4NJiGw9hOPvVwTUgwpc0LG7oFTYDCL9qFGv7yZOOnpbJuPC1zFXCC450KX5ygu/fEU=; path=/' --compressed
}

function record_fastly() {
    record_curl "${target_url}/host/${target_event_id}/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H "X-Proxy-Authorization: Basic ${target_proxy_auth_token}" -H 'Set-Cookie: CMPS=Q5oQ2d5Dp4NJiGw9hOPvVwTUgwpc0LG7oFTYDCL9qFGv7yZOOnpbJuPC1zFXCC450KX5ygu/fEU=; path=/' --compressed
}

function scrub_response() {
    replace_in_response 's!("created": *")[^"]*(")!\1_SCRUBBED_\2!'
    replace_in_response 's!("expires": *")[^"]*(")!\1_SCRUBBED_\2!'
    replace_in_response 's!("href": *")/api/ismds([^"]*")!\1'"$link_prefix"'\2!g'
}

it "does not change response body on a miss"

until_fresh_curl_object 5 record_origin

expect_header Server; to_equal nginx
scrub_response
origin_response_body=$(get_response_body)

record_fastly

expect_header X-Cache; to_match MISS$
scrub_response
expect_response_body; to_equal "$origin_response_body"

it "cache hits with same response body"

record_fastly

expect_header X-Cache; to_match HIT$
scrub_response
expect_response_body; to_equal "$origin_response_body"
