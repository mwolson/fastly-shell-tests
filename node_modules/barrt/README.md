# barrt - A Bash Rspec-like Regression Test Framework

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

## Setup

Edit `setup.sh`

## API

The following are provided as bash functions:

`grep $grep_arguments`

`sed $sed_arguments`

`echo_quoted $arguments_to_quote`

`first_line`

`define_side_a $value_to_be_compared`

`define_side_a_text $description_of_value_to_be_compared`

`define_addl_text $additional_explanation_if_test_case_fails`

`get_side_a`, `get_side_a_text`, `get_addl_text`

`describe $scenario_description`

`it $test_case_description`

`soft_fail $failure_reason`

`fail $failure_reason`

`expect $value_to_be_compared`

`to_be_empty`

`to_not_be_empty`

`to_equal $another_value`

`is_numeric $possible_number`

`to_be_numeric`

`to_be_greater_than $another_number`

`to_be_less_than $another_number`

`to_be_between $range_1 $range_2`

`to_contain $substring`

`to_match $pattern`

## License

MIT
