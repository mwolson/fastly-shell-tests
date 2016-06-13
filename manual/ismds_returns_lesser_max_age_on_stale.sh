#!/bin/bash

. $(dirname $0)/../setup.sh

# This is a manual test because we can't guarantee that ISMDS will always have a stale cache result to begin the test
describe "Max-age should be 5 on stale ISMDS objects"

keep_headers "Age|X-Cache|X-Served-By|Server|Expires|Cache-Control"

function record_ismds() {
    record_curl -k "${origin_url}/host/26004E4DF73E808C/facets?by=shape+attributes+available+accessibility+offer+inventoryType+offerType+description&show=places&embed=description&unlock=&apikey=b462oi7fic6pehcdkzony5bxhe&apisecret=pquzpfrfz7zd2ylvtz3w5dtyse" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H 'Referer: http://fastly-hackathon.tmdev.co/event/3F004EAECFB7BA10?fg=ism' -H 'Connection: keep-alive' --compressed
}

function record_fastly() {
    record_curl "${target_url}/host/26004E4DF73E808C/facets?by=shape+attributes+available+accessibility+offer+inventoryType+offerType+description&show=places&embed=description&unlock=&apikey=b462oi7fic6pehcdkzony5bxhe&apisecret=pquzpfrfz7zd2ylvtz3w5dtyse" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H 'Referer: http://fastly-hackathon.tmdev.co/event/3F004EAECFB7BA10?fg=ism' -H 'Connection: keep-alive' --compressed
}

it "captures Age of a stale ISMDS request (if it doesn't pass, repeat the test case later when the object goes stale)"

record_fastly
stash_curl
record_ismds

expect_header Server; to_equal nginx
expect_header Age; to_be_less_than 3
expect_header Cache-Control; to_match max-age=5$
ismds_age=$(get_header Age)

it "compared to fastly request made just before, should preserve the Age header from ismds"

pop_curl

expect_header X-Cache; to_match MISS$
expect_header Age; to_be_between $((ismds_age - 1)) $((ismds_age + 1))

it "after 6 seconds, cache misses on a followup request but has the new Age header from ismds"

sleep 6
record_fastly
stash_curl
record_ismds

expect_header Server; to_equal nginx
expect_header Age; to_be_less_than 8
expect_header Cache-Control; to_match max-age=60$
ismds_age=$(get_header Age)

it "compared to fastly request made just before, should preserve the Age header from ismds"

pop_curl

expect_header X-Cache; to_match MISS$
expect_header Age; to_be_between $((ismds_age - 1)) $((ismds_age + 1))
