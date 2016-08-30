# barrt - A Bash Rspec-like Regression Test Framework

## Usage

`barrt` was written to allow easy testing of commandline programs. The initial use case was making it possible to
choose "Copy as cURL" from a request in Google Chrome, drop the result into a test case, edit the URL slightly, and
begin checking the headers and response body. cURL support is available as a plugin in the
[barrt-curl](https://github.com/mwolson/barrt-curl) module.

One of the design goals is to provide helpful error messages when tests fail. The framework may be extended with
modules that create custom "expectations" (which are functions like `expect` that describe the left side of a
comparison) that make sense when coupled with existing assertions like `to_equal`.

`barrt` and `barrt-curl` are available as NPM modules. They don't use any Javascript. But having support for versioning
and ease of installing releases is helpful even so.

An effort has been made to provide compatible versions of `grep` and `sed` as functions that support extended (Perl or
PCRE-like) regular expression syntax which work on both Linux and OS X.

## Examples

### Simple test case

In a new file called `test/number-five.sh` (make sure to run `chmod +x` on it):

```sh
#!/bin/bash

. $(dirname $0)/../setup.sh

describe "The number 5"

num=5

it "is greater than 0"

expect $num; to_be_greater_than 0
```

### Test case with chained assertions

```sh
it "is a number less than 7"

expect $num; to_be_numeric; to_be_less_than 7
```

### Test case using the barrt-curl module

In a new file called `test/example-request.sh` (make sure to run `chmod +x` on it):

```sh
#!/bin/bash

. $(dirname $0)/../setup.sh

describe "Requests to example.com"

record_curl http://example.com

it "returns a 200 response with type text/html"

expect_response_code; to_equal 200
expect_header Content-Type; to_equal text/html
```

### Output

```sh
$ ./runner.sh
* Requests to example.com
  - it returns a 200 response with type text/html
* The number 5
  - it is greater than 0
  - it is a number less than 7

Test Summary:
  - 2 scenario(s) passed
  - 0 scenario(s) skipped
  - 0 scenario(s) failed
```

## Installation

Install the module from npm:

```sh
npm i --save barrt
```

Install any plugins you may want, such as [barrt-curl](https://github.com/mwolson/barrt-curl).

Edit the `setup.sh` file in your test suite to include the following:

```sh
#!/bin/bash

modules=$(dirname "$BASH_SOURCE")/node_modules

. "$modules"/barrt/setup.sh
. "$modules"/barrt-curl/setup.sh

# other plugins or setup tasks...
```

Create a `runner.sh` file in your test suite with these contents:

```sh
#!/bin/bash

modules=$(dirname "$BASH_SOURCE")/node_modules

exec "$modules"/barrt/runner.sh
```

Write some tests and place them in the `test/` directory.

## Run tests

Run all tests:

```sh
./runner.sh
```

Run a single test:

```sh
./test/different_origin.sh
```

Skipping a test:

```sh
chmod -x ./test/skip_this_one.sh
```

## API

The following are provided as bash functions:

### Core

`describe $scenario_description`

`it $test_case_description`

### Expectations

`expect $value_to_be_compared`

### Assertions

`to_be_empty`

`to_not_be_empty`

`to_equal $another_value`

`to_be_numeric`

`to_be_greater_than $another_number`

`to_be_less_than $another_number`

`to_be_between $range_1 $range_2`

`to_contain $substring`

`to_match $pattern`

### Compatibility

`grep $grep_arguments`

`sed $sed_arguments`

### Utility

`echo_quoted $arguments_to_quote`

`first_line`

`remove_last_line`

`fail $failure_reason`

`soft_fail $failure_reason`

`is_numeric $possible_number`

### Defining new assertions

`define_side_a $value_to_be_compared`

`define_side_a_text $description_of_value_to_be_compared`

`define_addl_text $additional_explanation_if_test_case_fails`

`get_side_a`, `get_side_a_text`, `get_addl_text`

## License

MIT
