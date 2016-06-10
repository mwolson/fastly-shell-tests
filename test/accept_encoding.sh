#!/bin/bash

. $(dirname $0)/../setup.sh

describe "Accept-Encoding header should be normalized, and it should be used in the cache key"

keep_headers "Age|X-Cache|accept-encoding|X-Served-By"

it "misses on the first request"

record_curl "${target_url}/host/3F004EAECFB7BA10/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H 'Referer: http://fastly-hackathon.tmdev.co/event/3F004EAECFB7BA10?fg=ism' -H 'Connection: keep-alive' -H 'X-Proxy-Authorization: Basic YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U=' --compressed

expect_header X-Cache; to_equal MISS
expect_header Age; to_equal 0
expect_header Accept-Encoding; to_equal gzip

it "cache hits on a request with a simpler encoding list"

wait_on_fastly_cache
record_curl "${target_url}/host/3F004EAECFB7BA10/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip;q=1.0, deflate' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H 'Referer: http://fastly-hackathon.tmdev.co/event/3F004EAECFB7BA10?fg=ism' -H 'Connection: keep-alive' -H 'X-Proxy-Authorization: Basic YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U=' --compressed

expect_header X-Cache; to_equal HIT
expect_header Age; to_be_between 1 10
expect_header Accept-Encoding; to_equal gzip

it "cache misses on a request with an Accept-Encoding header of deflate but normalizes it"

record_curl "${target_url}/host/3F004EAECFB7BA10/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: deflate;q=1.0' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H 'Referer: http://fastly-hackathon.tmdev.co/event/3F004EAECFB7BA10?fg=ism' -H 'Connection: keep-alive' -H 'X-Proxy-Authorization: Basic YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U=' --compressed

expect_header X-Cache; to_equal MISS
expect_header Age; to_equal 0
expect_header Accept-Encoding; to_equal deflate

it "cache misses on a request without an Accept-Encoding header"

record_curl "${target_url}/host/3F004EAECFB7BA10/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding:' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H 'Referer: http://fastly-hackathon.tmdev.co/event/3F004EAECFB7BA10?fg=ism' -H 'Connection: keep-alive' -H 'X-Proxy-Authorization: Basic YjQ2Mm9pN2ZpYzZwZWhjZGt6b255NWJ4aGU6cHF1enBmcmZ6N3pkMnlsdnR6M3c1ZHR5c2U=' --compressed

expect_header X-Cache; to_equal MISS
expect_header Age; to_equal 0
expect_header Accept-Encoding; to_be_empty
