---
number: 20
slug: capstone
title: Capstone, a validated config pipeline
module: In the wild
level: advanced
minutes: 45
summary: Put the course together. A YAML file with anchors, a JSON Schema, a jq summary, and a shell check that fails the build on bad input.
objectives:
  - Describe a config contract as a YAML file plus a JSON Schema
  - Reuse values with anchors and confirm the converter expanded them
  - Produce a summary with yaml2json and jq
  - Write a CI-style check that exits non-zero on malformed, invalid, or inconsistent files
  - Extend the pipeline with a conditional rule and a rule a schema cannot express
further:
  - title: JSON Schema draft 2020-12
    url: https://json-schema.org/draft/2020-12
  - title: Ajv documentation
    url: https://ajv.js.org/
  - title: Understanding JSON Schema
    url: https://json-schema.org/understanding-json-schema/
pitfall: |
  Each layer of this pipeline catches a different kind of mistake, and none catches all of them. The parser finds malformed text, the schema finds wrong shapes and values, and only your own code can find rules that span several places, such as two services claiming the same port. Skip a layer and its class of mistake reaches production.
---

The pipeline in this lesson has four stages: **parse**, **validate**, **check relationships**, **summarise**. It uses nothing new, only the tools from the earlier lessons, and its job is to turn a hand-edited YAML file into something a script can trust.

## The data

The file describes services. Two reusable resource sizes are defined once with anchors, and each service points at one. Whole-value aliases like these work under YAML 1.2, which is what `yaml2json` reads by default.

```run
# title: Validate a services file, then summarise it
cat > services.yaml <<'EOF'
version: 1
sizes:
  small: &small {cpu: 1, memory_mb: 256}
  large: &large {cpu: 4, memory_mb: 2048}
services:
  - {name: api,    port: 8080, env: prod, replicas: 3, resources: *large}
  - {name: worker, port: 9090, env: prod, replicas: 2, resources: *small}
  - {name: docs,   port: 8000, env: dev,  replicas: 1, resources: *small}
EOF

cat > services.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {
    "resources": {
      "type": "object",
      "properties": {
        "cpu": {"type": "integer", "minimum": 1},
        "memory_mb": {"type": "integer", "minimum": 64}
      },
      "required": ["cpu", "memory_mb"],
      "additionalProperties": false
    },
    "service": {
      "type": "object",
      "properties": {
        "name": {"type": "string", "pattern": "^[a-z][a-z0-9-]*$"},
        "port": {"type": "integer", "minimum": 1, "maximum": 65535},
        "env": {"enum": ["dev", "staging", "prod"]},
        "replicas": {"type": "integer", "minimum": 1},
        "resources": {"$ref": "#/$defs/resources"}
      },
      "required": ["name", "port", "env", "replicas", "resources"],
      "additionalProperties": false
    }
  },
  "type": "object",
  "properties": {
    "version": {"const": 1},
    "sizes": {"type": "object", "additionalProperties": {"$ref": "#/$defs/resources"}},
    "services": {"type": "array", "minItems": 1, "items": {"$ref": "#/$defs/service"}}
  },
  "required": ["version", "services"],
  "additionalProperties": false
}
EOF

schema-check services.schema.json services.yaml
echo "--- summary by environment ---"
yaml2json services.yaml | jq -r '
  .services | group_by(.env)[]
  | {env: .[0].env,
     services: length,
     replicas: (map(.replicas) | add),
     memory_mb: (map(.replicas * .resources.memory_mb) | add)}
  | "\(.env): \(.services) services, \(.replicas) replicas, \(.memory_mb) MB"'
```

Read the summary line for `prod`. It multiplies each service's replicas by its memory, which only works because the anchors were expanded: `worker.resources.memory_mb` exists even though the YAML never spelt it out. That is what [lesson 17](/lessons/converting) meant by "anchors become copies". Here the copy is exactly what you want.

## The check script

A schema covers one document's shape. It cannot say that two services must not share a port. That belongs in a small script, and the script is also where you decide the order of the layers and the exit status. This one runs in CI style: it reports every problem it can, then exits 1 if there was any.

```run
# title: A check that fails on malformed, invalid, or inconsistent input
cat > check.sh <<'EOF'
#!/usr/bin/env bash
# usage: check.sh schema.json services.yaml
schema=$1; file=$2; status=0

yamlcheck "$file" || exit 1
yaml2json "$file" > /dev/null || exit 1
schema-check "$schema" "$file" || status=1

dups=$(yaml2json "$file" | jq -r '[.services[]?.port] | group_by(.)[] | select(length > 1) | .[0]')
for port in $dups; do
  echo "$file: port $port is used by more than one service"
  status=1
done
exit $status
EOF

cat > schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "services": {"type": "array", "items": {
      "type": "object",
      "properties": {"name": {"type": "string"}, "port": {"type": "integer"}},
      "required": ["name", "port"], "additionalProperties": false}}
  },
  "required": ["services"]
}
EOF

cat > good.yaml <<'EOF'
services:
  - {name: api, port: 8080}
  - {name: docs, port: 8000}
EOF
cat > clash.yaml <<'EOF'
services:
  - {name: api, port: 8080}
  - {name: docs, port: 8080}
EOF
cat > invalid.yaml <<'EOF'
services:
  - {name: api, port: "8080", colour: blue}
EOF
printf 'services:\n  - name: api\n   port: 8080\n' > malformed.yaml

for f in good clash invalid malformed; do
  echo "=== $f.yaml"
  bash check.sh schema.json $f.yaml && echo "PASS" || echo "FAIL (exit $?)"
done
```

Four files, four outcomes. `good.yaml` passes. `clash.yaml` is perfectly valid against the schema, and only the script's own port check catches it. `invalid.yaml` fails the schema twice, and `malformed.yaml` fails at the first stage, so no later stage runs on text that is not YAML. In CI, you would run `bash check.sh services.schema.json services.yaml` as one step, and a non-zero exit would stop the pipeline.

The `&&` and `||` in the loop turn the exit status into a printed label, so the script as a whole still succeeds and the capture shows all four results.

## Why the script is shaped this way

A few small decisions in `check.sh` are worth copying.

**Stop early only when later stages would be meaningless.** A malformed file has no tree, so the script exits straight after the parse stage. A schema failure, by contrast, does not stop the port check, because the data is still readable and a developer fixing a file would rather see every problem in one run than fix them one at a time.

**Run the converter as well as the checker.** `yamlcheck` reports parse errors, but as [lesson 18](/lessons/github-actions) showed, some mistakes, such as an alias to an undefined anchor, only appear when the data is built. Calling `yaml2json` and discarding its output is a cheap way to catch them.

**Keep the exit status honest.** The script ends with `exit $status`, so a caller can tell success from failure without reading any text. The messages are for people, and the status is for the pipeline.

**Tolerate missing keys in the relationship check.** The `?` in `.services[]?` stops `jq` from failing on a file with no `services` list, so that case is left for the schema to report instead of producing a confusing `jq` error.

## Running it in CI

In a GitHub Actions workflow this is one step. The YAML below is only an illustration of where the command goes, and it assumes the helpers are installed on the runner:

```yaml
- name: Validate services
  run: bash check.sh services.schema.json services.yaml
```

If the command exits non-zero, GitHub marks the step failed and later steps are skipped by default. Nothing in the YAML knows about your schema. The checking happens entirely in the command, which is the point of keeping the pipeline in a script you can also run on your own machine.

## Where to go from here

You now have every piece: the tree model, the two syntaxes, the typing rules and their traps, the conversion losses, and a contract language. When you meet a new config format, ask the same questions in order. Which parser reads it, and for which YAML or JSON dialect? What tree does it build? What does the schema, if any, require? And what rule falls outside what a schema can say? The [playground](/playground) is a quick place to try a snippet when you are unsure how a parser will read it.

## What each layer caught

| File | Parse | Schema | Own check |
| --- | --- | --- | --- |
| `good.yaml` | ok | ok | ok |
| `clash.yaml` | ok | ok | duplicate port |
| `invalid.yaml` | ok | wrong type, extra key | ok (one service, no clash) |
| `malformed.yaml` | error | not run | not run |

The last row of the table is a choice in the script, not a law: the script stops after a parse failure because later stages have nothing to read.

## Extending it

The exercises add three things the pipeline lacks: a conditional rule, a trap involving merge keys, and a second relationship check.

## Exercises

```exercise
---title---
Production needs two replicas
---prompt---
Add a rule to the service schema: when `env` is `prod`, `replicas` must be at least 2. Test it with one passing and one failing service. Use `if` and `then`.
---hint---
Put `if: {properties: {env: {const: "prod"}}}` and `then: {properties: {replicas: {minimum: 2}}}` inside the service schema. Remember `type: object`.
---solution---
The conditional goes inside the `service` definition, next to `required`. A `prod` service with one replica gets a message about `/replicas` and one about the `then` schema. A `dev` service with one replica passes.
---script---
cat > s.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "env": {"enum": ["dev", "prod"]},
    "replicas": {"type": "integer"}
  },
  "required": ["env", "replicas"],
  "if": {"properties": {"env": {"const": "prod"}}},
  "then": {"properties": {"replicas": {"type": "integer", "minimum": 2}}}
}
EOF
echo '{"env": "prod", "replicas": 2}' > ok.json
echo '{"env": "dev", "replicas": 1}' > dev.json
echo '{"env": "prod", "replicas": 1}' > bad.json
schema-check s.json ok.json dev.json bad.json || echo "(exit status $?)"
```

```exercise
---title---
The merge key trap
---prompt---
Rewrite one service to reuse a size with a merge key (`<<: *small`) instead of `resources: *small`. Convert it with the default settings and with `--yaml-1.1`, and say what the schema in this lesson would report for the default conversion.
---hint---
Look at which keys appear in the JSON each time.
---solution---
With the default YAML 1.2 settings the converter leaves `<<` as an ordinary key, so the data has a `<<` key and no `cpu`. A closed schema (`additionalProperties: false`) reports `<<` as an extra key and `cpu` as missing. With `--yaml-1.1` the merge is expanded. The schema doing its job here is a good reason to keep `additionalProperties: false`.
---script---
cat > m.yaml <<'EOF'
small: &small {cpu: 1, memory_mb: 256}
svc:
  <<: *small
  name: worker
EOF
echo "--- default ---"
yaml2json m.yaml | jq -c .svc
echo "--- 1.1 ---"
yaml2json --yaml-1.1 m.yaml | jq -c .svc
cat > r.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {"svc": {"type": "object",
    "properties": {"name": {"type": "string"}, "cpu": {"type": "integer"}},
    "required": ["name", "cpu"], "additionalProperties": false}}
}
EOF
schema-check r.schema.json m.yaml || echo "(exit status $?)"
```

```exercise
---title---
Duplicate names
---prompt---
Extend the check from the lesson so that two services with the same `name` also fail. Test it on a file with a repeated name and different ports.
---hint---
The port check groups by `.port`. Group by `.name` instead and print any group longer than one.
---solution---
The same `group_by` and `select(length > 1)` pattern works on any field. The schema's `uniqueItems` would not help, because the two objects differ in `port`.
---script---
cat > dup.yaml <<'EOF'
services:
  - {name: api, port: 8080}
  - {name: api, port: 9090}
EOF
yaml2json dup.yaml | jq -r '[.services[].name] | group_by(.)[] | select(length > 1) | "duplicate name: " + .[0]'
```
