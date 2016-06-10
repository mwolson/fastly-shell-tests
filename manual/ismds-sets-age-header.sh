#!/bin/bash

. $(dirname $0)/../setup.sh

# This is a manual test because we can't guarantee that ISMDS will always have a cache miss to begin the test
describe "Age header from ISMDS should be preserved"

keep_headers "Age|X-Cache|X-Served-By|Server|Expires"

function record_ismds() {
    record_curl "${origin_url}/host/26004E4DF73E808C/facets?by=shape+attributes+available+accessibility+offer+inventoryType+offerType+description&show=places&embed=description&unlock=&apikey=b462oi7fic6pehcdkzony5bxhe&apisecret=pquzpfrfz7zd2ylvtz3w5dtyse" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H 'Referer: http://fastly-hackathon.tmdev.co/event/3F004EAECFB7BA10?fg=ism' -H 'Connection: keep-alive' --compressed
}

function record_fastly() {
    record_curl "${target_url}/host/26004E4DF73E808C/facets?by=shape+attributes+available+accessibility+offer+inventoryType+offerType+description&show=places&embed=description&unlock=&apikey=b462oi7fic6pehcdkzony5bxhe&apisecret=pquzpfrfz7zd2ylvtz3w5dtyse" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H 'Referer: http://fastly-hackathon.tmdev.co/event/3F004EAECFB7BA10?fg=ism' -H 'Connection: keep-alive' --compressed
}

it "misses internally on the ISMDS request and sets Age to 0"

record_ismds

expect_header Server; to_equal nginx
expect_header Age; to_equal 0

it "after 3 seconds, misses on initial fastly request to same path"

sleep 3
record_fastly

expect_header X-Cache; to_match MISS$
expect_header Age; to_be_between 3 4

it "after another 3 seconds, cache hits on a followup request with correct Age header"

sleep 3
record_fastly

expect_header X-Cache; to_match HIT$
expect_header Age; to_be_between 6 8
