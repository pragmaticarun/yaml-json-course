#!/usr/bin/env bash
# From the YAML & JSON course. Expects the course tools on PATH:
#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)
set -eo pipefail
cat > app.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: info
  RETRIES: "3"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 2
  template:
    spec:
      containers:
        - name: app
          image: example/app:1.4
---
apiVersion: v1
kind: Service
metadata:
  name: app
spec:
  ports:
    - port: 80
EOF
echo "--- kinds and names ---"
yaml2json --all app.yaml | jq -r '.[] | "\(.kind)\t\(.metadata.name)"'
echo "--- images ---"
yaml2json --all app.yaml | jq -r '.[] | select(.kind == "Deployment") | .spec.template.spec.containers[].image'
