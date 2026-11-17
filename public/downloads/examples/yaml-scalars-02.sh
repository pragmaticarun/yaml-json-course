#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > forces.yaml <<'EOF'
colon_quoted: "a: b"
hash_quoted: "a #b"
inline_hash: a#b
comment_after: a #b
at_quoted: "@user"
EOF
yaml2json forces.yaml | jq -c .
echo "---- the unquoted forms ----"
for v in '@user' 'x: y' '- x' '[x' '*' '%x'; do
  printf 'a: %s\n' "$v" > one.yaml
  printf '%s  ->  ' "$v"
  yamlcheck one.yaml | head -n 1 || true
done
