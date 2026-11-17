#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
echo '{"name":"app","port":80}' > cfg.json
echo "--- the wrong way"
cp cfg.json wrong.json
jq '.port = 8080' wrong.json > wrong.json
echo "jq exit status: $?"
echo "wrong.json is now $(wc -c < wrong.json) bytes"
echo "--- the right way"
jq '.port = 8080' cfg.json > cfg.json.tmp && mv cfg.json.tmp cfg.json
cat cfg.json
