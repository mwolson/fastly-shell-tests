# barrt-curl - cURL support for BARRT (A Bash Rspec-like Regression Test framework)

## Use it

Install these two modules from npm:

```sh
npm i --save barrt
npm i --save barrt-curl
```

Edit the `setup.sh` file in your test suite to include the following:

```sh
#!/bin/bash

modules=$(dirname "$BASH_SOURCE")/node_modules

. "$modules"/barrt/setup.sh
. "$modules"/barrt-curl/setup.sh

# other setup tasks...
```

Create a `runner.sh` file in your test suite with these contents:

```sh
#!/bin/bash

modules=$(dirname "$BASH_SOURCE")/node_modules

exec "$modules"/barrt/runner.sh
```

## API

`define_curl_token $extra_header_name_and_value_for_this_scenario`

`keep_headers $regex`

`inspect_next_curl`

`record_curl $curl_arguments`

`stash_curl`

`pop_curl`

`get_response`

`get_http_status`

`get_header`

`get_response_body`

`get_cache_max_age`

`until_fresh_curl_object $command_to_run`

`replace_in_response $sed_expression`

`expect_http_status`

`expect_header $header_name`

`expect_response_body`

## License

MIT
