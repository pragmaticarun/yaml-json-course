#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
printf '{"e":"caf\\u00e9 \\ud83d\\ude00 \\n tab\\t q\\" s\\\\ sl\\/"}\n' > s.json
echo "--- the file"; cat s.json
echo "--- jq -r (the decoded text)"; jq -r .e s.json
echo "--- jq -c (JSON again)"; jq -c . s.json
echo "--- jq -a (ASCII only)"; jq -a -c . s.json
