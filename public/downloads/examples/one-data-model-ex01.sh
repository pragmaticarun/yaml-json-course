#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > book.yaml <<'EOF'
title: The Pragmatic Programmer
year: 1999
authors:
  - Andrew Hunt
  - David Thomas
in_print: true
EOF
cat > book.json <<'EOF'
{"title": "The Pragmatic Programmer", "year": 1999,
 "authors": ["Andrew Hunt", "David Thomas"], "in_print": true}
EOF
yaml2json book.yaml > from-yaml.json
yaml2json book.json > from-json.json
cmp from-yaml.json from-json.json && echo "same tree"
cat from-yaml.json
