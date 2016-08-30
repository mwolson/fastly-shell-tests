#!/bin/bash

. $(dirname $0)/../setup.sh

describe "MAPS URLs that should be handled by fastly"

keep_headers "Age|X-Cache|X-Served-By|X-Timer|Access-Control-Allow-Origin"

target_url="${target_host}/api/maps/rest"

function record_event_with_header() {
    record_curl "${target_url}/geometry/${geometry_shard}/event/${target_event_id}?systemId=host" -H "X-Api-Key: ${target_apikey}" -H "X-Service-Token: ${target_apisecret}" -H 'Pragma: no-cache' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' --compressed
}

function record_placeDetail_with_query_param() {
    record_curl "${target_url}/geometry/${geometry_shard}/event/${target_event_id}/placeDetail?systemId=HOST&apikey=${target_apikey}&apisecret=${target_apisecret}" -H 'Pragma: no-cache' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' --compressed
}

function record_placeDetail_with_typo_query_param() {
    record_curl "${target_url}/geometry/${geometry_shard}/event/${target_event_id}/placeDetail%3FsystemId=host" -H "X-Api-Key: ${target_apikey}" -H "X-Service-Token: ${target_apisecret}" -H 'Pragma: no-cache' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' --compressed
}

function record_placeDetail_with_header() {
    record_curl "${target_url}/geometry/${geometry_shard}/event/${target_event_id}/placeDetail?systemId=host" -H "X-Api-Key: ${target_apikey}" -H "X-Service-Token: ${target_apisecret}" -H 'Pragma: no-cache' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' --compressed
}

function record_placeDetail_with_double_slash_path() {
    record_curl "${target_host}//api/maps/rest/geometry/${geometry_shard}/event/${target_event_id}/placeDetail?systemId=host" -H "X-Api-Key: ${target_apikey}" -H "X-Service-Token: ${target_apisecret}" -H 'Pragma: no-cache' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: no-cache' -H 'Connection: keep-alive' --compressed
}

function expect_modified_response() {
    expect_http_status; to_equal 200
    expect_header Vary; to_equal "Accept-Encoding,TMPS-IdentityToken"
    expect_header Access-Control-Allow-Origin; to_equal "http://fastly-hackathon.tmdev.co"
}

function run_cache_hit_scenario_for() {
    request_type=$1
    it "misses on the first ${request_type} request with shielding enabled"

    until_fresh_curl_object 6 record_${request_type}

    expect_header X-Cache; to_match 'MISS, *MISS$'
    expect_modified_response
    miss_age=$(get_header Age)

    it "misses on the second ${request_type} request"

    record_${request_type}

    expect_header X-Cache; to_match 'MISS, *MISS$'
    expect_modified_response
    expect_response_body; to_not_be_empty
}

run_cache_hit_scenario_for event_with_header
run_cache_hit_scenario_for placeDetail_with_query_param
run_cache_hit_scenario_for placeDetail_with_typo_query_param
run_cache_hit_scenario_for placeDetail_with_header
run_cache_hit_scenario_for placeDetail_with_double_slash_path
