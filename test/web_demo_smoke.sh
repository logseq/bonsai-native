#!/bin/sh
set -eu

main=$1
runtime=$2
components=$3

test -s "$main"
test -s "$runtime"
test -s "$components"
grep -q "createRenderer" "$main"
grep -q "component_by_id(\"counter\")" "$main"
grep -q "createRoot" "$runtime"
grep -q "Counter" "$runtime"
grep -q "Increment" "$components"
