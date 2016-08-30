#!/bin/bash

. $(dirname $0)/../setup.sh

describe "ISMDS URLs that should be cached by fastly"

keep_headers "Age|X-Cache|X-Served-By|X-Timer|Access-Control-Allow-Origin"

function record_attributes() {
    record_curl "${target_url}/host/${target_event_id}/attributes?apikey=${target_apikey}&apisecret=${target_apisecret}" -H 'Pragma: no-cache' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' --compressed
}

function record_descriptions() {
    record_curl "${target_url}/host/${target_event_id}/descriptions/${target_description_id}?apikey=${target_apikey}&apisecret=${target_apisecret}" -H 'Pragma: no-cache' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' --compressed
}

function record_event() {
    record_curl "${target_url}/event/${target_event_id}?apikey=${target_apikey}&apisecret=${target_apisecret}" -H 'Pragma: no-cache' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' --compressed
}

function record_facets() {
    record_curl "${target_url}/host/${target_event_id}/facets?by=inventorytypes%20offertypes%20accessibility&q=available&apikey=${target_apikey}&apisecret=${target_apisecret}" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed
}

function record_quickpicks() {
    record_curl "${target_url}/host/${target_event_id}/quickpicks?qty=000000000001%3A4&q=offertypes%3A%27standard%27&embed=area&embed=offer&embed=description&apikey=${target_apikey}&apisecret=${target_apisecret}" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H "Referer: http://fastly-hackathon.tmdev.co/event/${target_event_id}?fg=ism" -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed
}

function record_offers() {
    record_curl "${target_url}/host/${target_event_id}/offers?apikey=${target_apikey}&apisecret=${target_apisecret}" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' --compressed
}

function expect_modified_response() {
    expect_http_status; to_equal 200
    expect_header Vary; to_equal "Accept-Encoding,TMPS-IdentityToken,Origin,X-Api-Key"
    expect_header Access-Control-Allow-Origin; to_equal "http://fastly-hackathon.tmdev.co"
}

function run_cache_hit_scenario_for() {
    request_type=$1
    it "misses on the first ${request_type} request with shielding enabled"

    until_fresh_curl_object 6 record_${request_type}

    expect_header X-Cache; to_match 'MISS, *MISS$'
    expect_modified_response
    miss_age=$(get_header Age)

    it "cache hits on the second ${request_type} request"

    record_${request_type}

    expect_header X-Cache; to_match HIT
    expect_header Age; to_be_between $((miss_age)) $((miss_age + 2))
    expect_modified_response
    expect_origin_response_time; to_be_less_than $expected_fastly_shield_time
}

run_cache_hit_scenario_for attributes
run_cache_hit_scenario_for descriptions
run_cache_hit_scenario_for event
run_cache_hit_scenario_for facets
run_cache_hit_scenario_for offers
run_cache_hit_scenario_for quickpicks
