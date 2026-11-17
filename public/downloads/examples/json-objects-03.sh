#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '{"z":1,"b":2,"a":{"y":1,"x":2},"1":"one","0":"zero"}' > ord.json
echo "input:       $(cat ord.json)"
echo "jq:          $(jq -c . ord.json)"
echo "jq -S:       $(jq -S -c . ord.json)"
echo "node:        $(node -e 'console.log(JSON.stringify(JSON.parse(require("fs").readFileSync("ord.json","utf8"))))')"
echo "python:      $(python3 -c 'import json; print(json.dumps(json.load(open("ord.json"))))')"
echo "python sort: $(python3 -c 'import json; print(json.dumps(json.load(open("ord.json")), sort_keys=True))')"
