#!/bin/bash

. $(dirname $0)/../setup.sh

describe "Guru mediation 503 pages"

keep_headers "Age|X-Cache|X-Served-By|X-Timer|Server|Retry-After|Content-Type"

it "provides a synthetic JSON response in case of a 503 instead of a Guru Mediation page"

record_curl "${target_url}/test/guru?apikey=${target_apikey}&apisecret=${target_apisecret}" -H 'Pragma: no-cache' -H 'Origin: http://fastly-hackathon.tmdev.co' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36' -H 'Accept: */*' -H "Referer: http://fastly-hackathon.tmdev.co" -H 'Connection: keep-alive' -H 'Cache-Control: no-cache' --compressed

expect_header Server; to_equal Varnish
expect_header Access-Control-Allow-Origin; to_equal "http://fastly-hackathon.tmdev.co"
expect_header X-Cache; to_match MISS$
expect_header Age; to_be_empty
expect_header Retry-After; to_equal 5
expect_header Content-Type; to_equal "application/hal+json;charset=UTF-8"
expect "$(response | first_line)"; to_equal "HTTP/1.1 503 Synthetic test error"

read -r -d '' expected_body <<EOF
{
  "schema": "urn:com.ticketmaster.services:schema:common:Status:1.0",
  "meta": {
    "type": "urn:com.ticketmaster.services:type:common:Status"
  },
  "code": "Error.Varnish.NotFound",
  "title": "503 Synthetic test error",
  "_links": {},
  "_embedded": {}
}
EOF

expect_response_body; to_equal "$expected_body"
