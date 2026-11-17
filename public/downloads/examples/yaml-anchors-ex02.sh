#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > job.yaml <<'EOF'
defaults: &d
  image: alpine
job:
  <<: *d
  cmd: echo hi
EOF
echo "== 1.2"; yaml2json job.yaml | jq -c .job
echo "== 1.1"; yaml2json --yaml-1.1 job.yaml | jq -c .job
