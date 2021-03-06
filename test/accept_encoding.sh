#!/bin/bash

. $(dirname $0)/../setup.sh

describe "Accept-Encoding header should be normalized, and it should be used in the cache key"

keep_headers "Age|Cache-Control|X-Cache|X-Served-By|Accept-Encoding|Content-Encoding"

it "misses on the first request"

until_fresh_curl_object 5 record_curl "${target_url}/host/${target_event_id}/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H "X-Proxy-Authorization: Basic ${target_proxy_auth_token}" --compressed

expect_header X-Cache; to_match MISS
expect_header Content-Encoding; to_equal gzip
miss_age=$(get_header Age)

it "cache hits on a request with a simpler encoding list"

record_curl "${target_url}/host/${target_event_id}/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip;q=1.0, deflate' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H "X-Proxy-Authorization: Basic ${target_proxy_auth_token}" --compressed

expect_header X-Cache; to_match HIT
expect_header Age; to_be_between $((miss_age)) $((miss_age + 2))
expect_header Content-Encoding; to_equal gzip

it "cache misses on a request without an Accept-Encoding header"

record_curl "${target_url}/host/${target_event_id}/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding:' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H "X-Proxy-Authorization: Basic ${target_proxy_auth_token}" --compressed

expect_header X-Cache; to_match MISS
expect_header Content-Encoding; to_be_empty
