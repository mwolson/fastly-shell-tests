#!/bin/bash

. $(dirname $0)/../setup.sh

describe "Different Origin headers should cache to the same bucket"

keep_headers "Age|X-Cache|X-Served-By|Access-Control-Allow-Origin"

it "misses on the first request"

until_fresh_curl_object 3 record_curl "${target_url}/host/3F004EAECFB7BA10/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H 'Referer: http://fastly-hackathon.tmdev.co/event/3F004EAECFB7BA10?fg=ism' -H 'Connection: keep-alive' -H 'X-Proxy-Authorization: Basic YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U=' --compressed

expect_header X-Cache; to_match MISS$
miss_age=$(get_header Age)

it "cache hits on a second request with different Origin header"

record_curl "${target_url}/host/3F004EAECFB7BA10/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastlyy-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H 'Referer: http://fastly-hackathon.tmdev.co/event/3F004EAECFB7BA10?fg=ism' -H 'Connection: keep-alive' -H 'X-Proxy-Authorization: Basic YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U=' --compressed

expect_header X-Cache; to_match HIT$
expect_header Age; to_be_between $((miss_age)) $((miss_age + 1))
