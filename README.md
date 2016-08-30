# fastly-shell-tests

## Run tests

Run all tests with the default QA profile:

```sh
./runner.sh
```

Run all tests with the production profile (supported profiles are: qa, staging, production):

```sh
TEST_PROFILE=production ./runner.sh
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
