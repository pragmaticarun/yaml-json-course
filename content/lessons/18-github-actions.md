---
number: 18
slug: github-actions
title: Reading a GitHub Actions workflow
module: In the wild
level: advanced
minutes: 30
summary: A workflow file is YAML with a few traps. See the tree GitHub receives, why the key on is special, and how to catch mistakes before you push.
objectives:
  - Name the parts of a workflow file and the tree each becomes
  - Explain why ${{ }} expressions are plain strings to the YAML parser
  - Show why the top-level key on is read differently by YAML 1.1 and 1.2 parsers
  - Write multi-line run steps and quote values that contain colons or glob characters
  - Catch structural mistakes with a small schema before pushing
further:
  - title: Workflow syntax for GitHub Actions
    url: https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions
  - title: JSON Schema draft 2020-12
    url: https://json-schema.org/draft/2020-12
pitfall: |
  YAML is parsed before GitHub evaluates anything. A value such as `${{ matrix.os }}` reaches GitHub as an ordinary string, and a typo inside it is not a YAML error. Your editor's YAML checker will say a file is fine while the workflow fails when it runs.
---

GitHub Actions workflows live in `.github/workflows/*.yml`. They are the most common YAML file a developer edits, so they make a good test of everything so far. The file is parsed into a tree, and GitHub reads that tree: `on` says when to run, `jobs` is a mapping of job names, and each job has `runs-on` and a list of `steps`.

## The anatomy as a tree

The easiest way to see the structure is to convert a workflow to JSON.

```run
# title: A workflow and the tree behind it
cat > ci.yml <<'EOF'
name: ci
on:
  push:
    branches: [main]
  pull_request:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install
        run: npm ci
      - name: Test
        run: npm test
EOF
yaml2json ci.yml | jq -c '{name, on, jobs: (.jobs | keys), steps: (.jobs.test.steps | length)}'
yaml2json ci.yml | jq -c '.jobs.test.steps[]'
```

Each step is a mapping. `uses` names a reusable action, `run` holds a shell command, `name` is a label, and `with` supplies arguments. A step needs `uses` or `run`, not both. Notice `pull_request:` with nothing after it. An empty value is `null` in YAML, and GitHub accepts that as "run on every pull request event".

## The key called on

In YAML 1.1, the bare words `on`, `off`, `yes`, and `no` are booleans, so a 1.1 loader reads the key `on:` as `true`. In YAML 1.2 they are plain strings. GitHub's own parser reads `on` as the string, so the file works there, but another tool might not agree.

```run
# title: The same key under YAML 1.2 and 1.1
cat > trigger.yml <<'EOF'
on:
  push:
    branches: [main]
EOF
echo "--- YAML 1.2 ---"
yaml2json trigger.yml | jq -c 'keys'
echo "--- YAML 1.1 ---"
yaml2json --yaml-1.1 trigger.yml | jq -c 'keys'
```

If a script of yours loads workflows with a 1.1 library, it will look for a `"on"` key and find `"true"`. The fix is in your script, not in the workflow: either use a 1.2 parser or handle both spellings. Writing `"on":` with quotes in the workflow also works on both, but most people leave it bare.

## Expressions are strings

`${{ ... }}` is GitHub's expression syntax. YAML does not know about it, so the parser sees an ordinary scalar, and the dollar sign and braces are legal inside a plain scalar when it starts with `$`. A value that *starts* with `{` would be a different story: YAML would try to read a flow mapping.

```run
# title: Quoting values that look like YAML syntax
cat > quote.yml <<'EOF'
env:
  PLAIN: ${{ secrets.TOKEN }}
  FROM_BRACE: "{{ not.an.expression }}"
  GLOB: "*.js"
  RATIO: "3:1"
  BRANCHES: ['*', 'release/**']
EOF
yaml2json quote.yml
echo "--- the same glob, unquoted ---"
printf 'files: *.js\n' > unquoted-glob.yml
yaml2json unquoted-glob.yml || true
echo "--- braces at the start of a value, unquoted ---"
printf 'x: {{ a.b }}\n' > unquoted-brace.yml
yaml2json unquoted-brace.yml 2>/dev/null
```

A leading `*` starts an alias in YAML, so the unquoted glob is an error: the parser looks for an anchor named `.js` and finds none. Quoting `'*'` is the standard answer. The unquoted `{{ a.b }}` is worse because it is *not* an error. A value that starts with `{` is read as a flow mapping, so `x` becomes a mapping with one key, `{ a.b }`, whose value is null. The file parses and the meaning is wrong. GitHub's `${{ }}` form avoids this because the value starts with `$`, but a bare `{{ }}` copied from a templating language does not. The `:` in a plain scalar is only special when followed by a space, which is why `3:1` can be left bare, but quoting it makes the intent clear.

(`yamlcheck`, the course's checker, reports `unquoted-glob.yml` as fine, because it only looks at parse errors and the alias problem appears when the data is built. `yaml2json` builds the data, so it catches it. Run the converter as well when you want to be sure.)

## Multi-line commands

For anything longer than one line, use a literal block scalar (`|`). Every line is kept exactly, including newlines, and the shell receives it as one script.

```run
# title: run: | keeps newlines, run: > folds them
cat > steps.yml <<'EOF'
steps:
  - run: |
      echo one
      echo two
  - run: >
      echo three
      echo four
EOF
yaml2json steps.yml | jq -c '.steps[].run'
```

The first command is two lines, and the second is one line, because `>` folds line breaks into spaces. For a shell script you almost always want `|`. See [lesson 10](/lessons/yaml-scalars) for the chomping indicators that control the final newline.

## needs and if

Jobs run in parallel unless one names another in `needs`. A step or job can carry an `if` condition, which is again a string that GitHub evaluates later.

```run
# title: needs is a list, if is a string
cat > flow.yml <<'EOF'
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: make
  deploy:
    needs: [build]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: make deploy
EOF
yaml2json flow.yml | jq -c '.jobs.deploy | {needs, "if": .["if"], type_of_if: (.["if"] | type)}'
```

The `if` value is a string to the parser, as the `type_of_if` field shows. Inside it, the single quotes belong to GitHub's expression language, and YAML passes them through untouched. Because a plain scalar cannot start with certain characters, an `if` that begins with `!` or `{` must be quoted or wrapped in `${{ }}`.

## Matrices

A matrix is a mapping from a name to a list of values, and GitHub runs the job once per combination.

```run
# title: A matrix is a mapping of lists, and a schema can check the shape
cat > matrix.yml <<'EOF'
name: build
on: push
jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        node: [20, 22]
    steps:
      - run: node --version
EOF
yaml2json matrix.yml | jq -c '.jobs.build.strategy.matrix'
cat > mini.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["on", "jobs"],
  "properties": {
    "jobs": {
      "type": "object",
      "minProperties": 1,
      "additionalProperties": {
        "type": "object",
        "required": ["runs-on"],
        "properties": {
          "steps": {
            "type": "array",
            "items": {
              "type": "object",
              "anyOf": [{"required": ["uses"]}, {"required": ["run"]}]
            }
          }
        }
      }
    }
  }
}
EOF
schema-check mini.schema.json matrix.yml
printf 'on: push\njobs:\n  t:\n    steps:\n      - name: nothing\n' > broken.yml
schema-check mini.schema.json broken.yml || true
```

The schema above is a small hand-written one for this lesson, not GitHub's own. It checks that `on` and `jobs` exist, that every job has `runs-on`, and that every step has `uses` or `run`. It catches structural slips, but not a misspelt expression or a wrong action name. For fuller checking, use a dedicated workflow linter.

## Exercises

```exercise
---title---
Why does this step fail?
---prompt---
A workflow contains `- run: echo hello: world`. Convert it and say what `run` holds, then fix the file so the command prints `hello: world`.
---hint---
A colon followed by a space inside a plain scalar starts a nested mapping.
---solution---
The parser reports an error rather than a string, because `hello: world` looks like a key and value on one line. Quoting the whole command, or using `run: |`, fixes it.
---script---
printf -- '- run: echo hello: world\n' > bad.yml
yamlcheck bad.yml || echo "(yamlcheck exit status $?)"
printf -- '- run: "echo hello: world"\n' > good.yml
yaml2json good.yml
```

```exercise
---title---
Count the matrix jobs
---prompt---
Given a matrix with `os` of three values and `node` of two, how many job runs does GitHub create? Write the YAML, then count the combinations with `jq`.
---hint---
The product of the list lengths.
---solution---
Three times two is six. `jq` can multiply the lengths of the lists in the mapping.
---script---
cat > m.yml <<'EOF'
matrix:
  os: [ubuntu-latest, macos-latest, windows-latest]
  node: [20, 22]
EOF
yaml2json m.yml | jq '[.matrix[] | length] | reduce .[] as $n (1; . * $n)'
```
