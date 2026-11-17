#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > strict_load.py <<'EOF'
import json, sys

def no_duplicates(pairs):
    seen = set()
    for key, _ in pairs:
        if key in seen:
            raise ValueError(f"duplicate key: {key}")
        seen.add(key)
    return dict(pairs)

with open(sys.argv[1]) as handle:
    print(json.load(handle, object_pairs_hook=no_duplicates))
EOF
echo '{"role":"user","name":"x","role":"admin"}' > req.json
python3 strict_load.py req.json 2>&1 | tail -1
