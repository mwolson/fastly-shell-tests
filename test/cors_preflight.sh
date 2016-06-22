#!/bin/bash

. $(dirname $0)/../setup.sh

describe "CORS preflight requests"

keep_headers ".*"

record_curl -H "Origin: http://example.com" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: x-foo-bar" -X OPTIONS "${target_url}/api/ismds/host/${target_event_id}/facets?by=inventorytypes%20offertypes%20accessibility&q=available&apikey=${target_apikey}&apisecret=${target_apisecret}"

it "is an HTTP 204 No Content response"
expect "$(get_response | first_line)"; to_equal "HTTP/1.1 204 No Content"

it "is always a cache hit"
expect_header X-Cache; to_match HIT$

it "has all the expected headers"
expect_header Access-Control-Max-Age; to_equal 86400
expect_header Access-Control-Allow-Methods; to_contain POST
expect_header Access-Control-Allow-Headers; to_equal x-foo-bar
expect_header Access-Control-Allow-Origin; to_equal "http://example.com"
