#!/bin/bash

. $(dirname $0)/../setup.sh

describe "Cookies should be removed from the response by fastly to improve caching"

keep_headers "Age|X-Cache|X-Served-By|Server|Set-Cookie|Cookie"

it "echoes Set-Cookie on origin server"

until_fresh_curl_object 5 record_curl -k "${origin_url}/host/${target_event_id}/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H "X-Proxy-Authorization: Basic ${target_proxy_auth_token}" -H 'Set-Cookie: CMPS=Q5oQ2d5Dp4NJiGw9hOPvVwTUgwpc0LG7oFTYDCL9qFGv7yZOOnpbJuPC1zFXCC450KX5ygu/fEU=; path=/' --compressed

expect_header Server; to_equal nginx

if test -z "$(get_header Set-Cookie)"; then
    it "skips remaining tests since this origin server doesn't set cookies"
    exit 0
fi

expect_header Set-Cookie; to_contain "CMPS="

it "cache misses and removes Set-Cookie on fastly"

record_curl "${target_url}/host/${target_event_id}/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H "X-Proxy-Authorization: Basic ${target_proxy_auth_token}" -H 'Set-Cookie: CMPS=Q5oQ2d5Dp4NJiGw9hOPvVwTUgwpc0LG7oFTYDCL9qFGv7yZOOnpbJuPC1zFXCC450KX5ygu/fEU=; path=/' --compressed

expect_header X-Cache; to_match MISS
expect_header Set-Cookie; to_be_empty
miss_age=$(get_header Age)

it "cache hits and removes Set-Cookie on fastly"

record_curl "${target_url}/host/${target_event_id}/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H "X-Proxy-Authorization: Basic ${target_proxy_auth_token}" -H 'Set-Cookie: CMPS=Q5oQ2d5Dp4NJiGw9hOPvVwTUgwpc0LG7oFTYDCL9qFGv7yZOOnpbJuPC1zFXCC450KX5ygu/fEU=; path=/' --compressed

expect_header X-Cache; to_match HIT
expect_header Age; to_be_between $((miss_age)) $((miss_age + 2))
expect_header Set-Cookie; to_be_empty
