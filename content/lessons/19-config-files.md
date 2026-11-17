---
number: 19
slug: config-files
title: Config files in the wild
module: In the wild
level: intermediate
minutes: 30
summary: package.json, tsconfig.json, Docker Compose, and Kubernetes manifests each use these formats a little differently. Read them as trees and know which parser each expects.
objectives:
  - Explain why package.json must be strict JSON while tsconfig.json may contain comments
  - Query a multi-document Kubernetes file with yaml2json --all and jq
  - Spot values that look like numbers or booleans but should be strings
  - Choose between JSON and YAML for a new config file
further:
  - title: TypeScript, tsconfig reference
    url: https://www.typescriptlang.org/tsconfig/
  - title: Docker Compose file reference
    url: https://docs.docker.com/reference/compose-file/
  - title: Kubernetes, working with objects
    url: https://kubernetes.io/docs/concepts/overview/working-with-objects/
pitfall: |
  A file's extension does not tell you which parser reads it. `tsconfig.json` ends in `.json` and accepts comments. `package.json` ends in `.json` and does not. Check the tool's documentation, and when you write a tool of your own, say which dialect you accept.
---

By now you can read the tree behind any one file. This lesson looks at four real file types and the small differences in how each tool reads its format.

## package.json is strict

`npm` reads `package.json` with an ordinary JSON parser. There are no comments, no trailing commas, and no single quotes. People often want a comment in it, and the common workaround is a made-up key such as `"//": "note"`, which npm ignores.

```run
# title: A comment breaks a strict JSON file
# expect-exit: 1
cat > package.json <<'EOF'
{
  "name": "demo",
  // the entry point
  "main": "index.js",
}
EOF
node -e 'try { JSON.parse(require("fs").readFileSync("package.json", "utf8")) } catch (e) { console.error(e.message); process.exit(1) }'
```

Node's `JSON.parse` follows RFC 8259, so it stops at the first thing the grammar does not allow, which here is the `//` comment on line 3, and the script exits with status 1. The message gives a position, which is the same information [lesson 2](/lessons/json-grammar) taught you to use. Fixing the comment would only reveal the next problem, the trailing comma after `"index.js"`.

The `"//"` workaround keeps the file strict:

```run
# title: A comment key that strict JSON accepts
cat > package.json <<'EOF'
{
  "name": "demo",
  "//": "the entry point is index.js",
  "main": "index.js"
}
EOF
jq -c '{name, main}' package.json
```

It is an ordinary key whose value nobody reads. That is why it works in a strict parser and also why it is a convention, not a feature.

## tsconfig.json is JSONC

The TypeScript compiler reads `tsconfig.json` with its own parser, which accepts comments and trailing commas. This is sometimes called JSONC, "JSON with comments". It is a dialect, not a standard: the TypeScript documentation describes what `tsconfig.json` allows, and other tools that read the same filename may be stricter. Compare what a strict parser and `jq` make of such a file.

```run
# title: The same file, read by strict parsers
# expect-exit: 1
cat > tsconfig.json <<'EOF'
{
  // compile for modern Node
  "compilerOptions": {
    "target": "ES2022",
    "strict": true,
  },
}
EOF
echo "--- jq ---"
jq . tsconfig.json || true
echo "--- JSON.parse ---"
node -e 'try { JSON.parse(require("fs").readFileSync("tsconfig.json", "utf8")) } catch (e) { console.error(e.message); process.exit(1) }'
```

Both reject the file. If you need to process a `tsconfig.json` in a script, strip the comments first with a tool that understands JSONC, or ask the TypeScript API to parse it, instead of running `jq` on it directly.

## Docker Compose is YAML

A Compose file is a YAML mapping. Its `services` key maps service names to settings, and `ports` is a list. Here the YAML types matter, because Compose reads port numbers that look like times.

```run
# title: A Compose file as a tree
cat > compose.yaml <<'EOF'
services:
  web:
    image: nginx:1.27
    ports:
      - "8080:80"
    environment:
      DEBUG: "false"
      WORKERS: 4
  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: example
EOF
yaml2json compose.yaml | jq -c '.services | to_entries[] | {name: .key, image: .value.image}'
yaml2json compose.yaml | jq -c '.services.web | {ports, debug_type: (.environment.DEBUG | type), workers_type: (.environment.WORKERS | type)}'
```

`"8080:80"` is quoted, and the output shows it as a string. That matters, because an unquoted `22:22` can be read as something else, as the next example shows. `DEBUG` is quoted too, so it is the string `"false"`, whereas `WORKERS` is a number. Environment variables are strings once they reach a process, so quoting a value that looks like a boolean or number states your intent.

```run
# title: An unquoted port mapping under two YAML versions
cat > ports.yaml <<'EOF'
ports:
  - 22:22
  - "22:22"
  - 8080:80
EOF
echo "--- YAML 1.2 ---"
yaml2json ports.yaml | jq -c .ports
echo "--- YAML 1.1 ---"
yaml2json --yaml-1.1 ports.yaml | jq -c .ports
```

Under YAML 1.2 every entry is a string. Under 1.1 the first becomes the number 1342, because `22:22` is read as base 60 (22 × 60 + 22), while `8080:80` stays a string since `80` is not a valid base-60 digit group. The quoted entry is safe both ways. That is why the Compose documentation advises quoting port mappings.

## Kubernetes: many documents in one file

A Kubernetes manifest often holds several objects separated by `---`. Each document has `apiVersion`, `kind`, and `metadata`. That is exactly what `--all` is for, and `jq` can then filter the array.

```run
# title: Filtering a multi-document manifest
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
```

Note that `RETRIES: "3"` is quoted. In a `ConfigMap`, `data` values must be strings, so an unquoted `3` would be a number and the cluster would reject it. That is a YAML typing issue the converter makes visible: convert and look for numbers where you meant strings.

## Numbers that should be strings

Identifiers that happen to be digits are a steady source of bugs: zip codes, phone numbers, version strings, build numbers.

```run
# title: Identifiers that look like numbers
cat > ids.yaml <<'EOF'
zip: 02134
phone: 5551234
version: 1.10
build: "0042"
EOF
yaml2json ids.yaml | jq -c '.'
yaml2json ids.yaml | jq -c 'map_values(type)'
```

The unquoted `02134` loses its leading zero and `1.10` loses its trailing one, because the parser built numbers. The quoted `"0042"` kept its zeros. If a value is an identifier rather than a quantity, quote it in YAML and use a JSON string in JSON. Nothing is wrong with the parser. It did what the grammar says, and the type is the author's decision to make explicit.

## Choosing a format

When you design a config file for your own tool, the decision is usually small.

- **JSON** when machines write it, when every parser must agree, or when you want no surprises. It has one dialect and no implicit types beyond the six.
- **YAML** when humans edit it by hand and want comments, anchors, or less punctuation. You accept the typing rules of [lesson 11](/lessons/yaml-types) and the safety care of [lesson 14](/lessons/yaml-safety).
- **JSONC** only if your own tool parses it. State the dialect in your documentation.

Whichever you pick, pair it with a schema ([lesson 15](/lessons/json-schema-basics)). The schema makes the contract explicit and lets editors check files as they are written.

## Exercises

```exercise
---title---
Find the stringly values
---prompt---
In a Compose `environment` mapping you have `PORT: 8080`, `ENABLED: yes`, and `VERSION: 3.10`. Convert it and list the type of each value under YAML 1.2. Then rewrite the file so all three are strings.
---hint---
Use `jq 'map_values(type)'`, and quote the values in the second file.
---solution---
`PORT` is a number, `ENABLED` is a string (YAML 1.2 does not treat `yes` as a boolean, though a 1.1 reader would), and `VERSION` is the number 3.1, which loses the trailing zero. Quoting all three makes them strings for every reader.
---script---
cat > env.yaml <<'EOF'
PORT: 8080
ENABLED: yes
VERSION: 3.10
EOF
yaml2json env.yaml | jq -c 'map_values(type)'
yaml2json env.yaml | jq -c .VERSION
printf 'PORT: "8080"\nENABLED: "yes"\nVERSION: "3.10"\n' > env-strings.yaml
yaml2json env-strings.yaml | jq -c 'map_values(type)'
```

```exercise
---title---
List a manifest
---prompt---
Write a two-document YAML file with a `Service` and a `Deployment`, then print only the `kind` of each, one per line.
---hint---
`yaml2json --all`, then `jq -r '.[].kind'`.
---solution---
`--all` turns the stream into an array of two trees, and `.[].kind` reads the field from each.
---script---
cat > two.yaml <<'EOF'
kind: Service
---
kind: Deployment
EOF
yaml2json --all two.yaml | jq -r '.[].kind'
```
