#!/bin/bash

. $(dirname $0)/../setup.sh

headers="X-Cache|X-TM-GTM-Origin|Age|Cache-Control"
iterations=20

describe "Load balancing between jash1 and jphx1 with varying URL"

if test "$TEST_PROFILE" = "qa"; then
    it "skips this test on QA"
    exit 0
fi

function request_varying_url() {
    local iteration=$1
    curl -k -s -i "${target_url}/host/${target_event_id}/facets?q=and(and(has(inventorytypes,%22primary%22),has(offertypes,%22standard%22)),available)&show=facerange&by=accessibility+shape+inventorytypes+offers+offerTypes&apikey=${target_apikey}&apisecret=${target_apisecret}&test_variance=$(get_random_token)-${iteration}" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H 'Cache-Control: no-cache' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' --compressed
}

count=0
output=$({ while test $count -lt $iterations; do ((count++)); request_varying_url $count; done; } | grep "^(${headers}):")

it "has $iterations cache misses"

define_addl_text "$output"
expect "$(<<< "$output" grep ", MISS" | count_lines)"; to_equal $iterations

it "makes at least 4 requests to jash1"

jash1_requests=$(<<< "$output" grep "X-TM-GTM-Origin: services-us-jash1" | count_lines)
expect $jash1_requests; to_be_greater_than 3

it "makes at least 4 requests to jphx1"

jphx1_requests=$(<<< "$output" grep "X-TM-GTM-Origin: services-us-jphx1" | count_lines)
expect $jphx1_requests; to_be_greater_than 3

it "summarizes request distribution"

echo "    - jash1 requests: ${jash1_requests}"
echo "    - jphx1 requests: ${jphx1_requests}"
