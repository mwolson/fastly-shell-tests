#!/bin/bash

modules=$(dirname "$BASH_SOURCE")/node_modules

if test -z "$TEST_PROFILE"; then
    echo "Using QA profile; change this by setting the TEST_PROFILE environment variable like:"
    echo "  $ TEST_PROFILE=production ./runner.sh"
    echo -e "\nAvailable profiles: qa, staging, production\n"
    export TEST_PROFILE=qa
fi

exec "$modules"/barrt/runner.sh
