#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > tags.yaml <<'EOF'
a: !!int "42"
b: !!str 42
c: !!bool "true"
d: !!null ""
e: !Ref MyBucket
f: !GetAtt [Res, Arn]
g: !Sub "x-${AWS::Region}"
EOF
yaml2json tags.yaml | jq -c .
echo "== yamlcheck"
yamlcheck tags.yaml
