---
number: 1
slug: one-data-model
title: Two formats, one data model
module: Foundations
level: beginner
minutes: 20
summary: JSON and YAML both describe trees of maps, lists, and scalars. Learn that model first and the syntax becomes notation for it.
objectives:
  - Name the six kinds of value that JSON can hold
  - Write the same small tree in JSON, YAML block style, and YAML flow style
  - Explain why a valid JSON document is also a valid YAML 1.2 document
  - Run the course helpers yaml2json and json2yaml and read their output
further:
  - title: RFC 8259, The JavaScript Object Notation (JSON) Data Interchange Format
    url: https://www.rfc-editor.org/rfc/rfc8259
  - title: YAML 1.2.2 specification, chapter 1 (Introduction)
    url: https://yaml.org/spec/1.2.2/#chapter-1-introduction-to-yaml
pitfall: |
  "YAML is a superset of JSON" is true for YAML 1.2. Many tools still load YAML 1.1 (PyYAML is one), and under 1.1 a few JSON inputs read differently. Lesson 11 shows the cases. When someone says "it is just YAML", ask which version their parser implements.
---

You will meet these two formats everywhere a program needs settings or a message. `package.json`, `tsconfig.json`, and every REST API you call speak JSON. GitHub Actions workflows, Kubernetes manifests, Docker Compose files, and OpenAPI documents are usually YAML. They look different. Underneath, they describe the same kind of thing: a tree.

## The tree underneath

Every JSON document is one value, and a value is one of six things:

| Kind | JSON example | Notes |
| --- | --- | --- |
| object | `{"name": "api", "port": 8080}` | Unordered set of name/value pairs. YAML calls it a *mapping*. |
| array | `[1, 2, 3]` | Ordered list. YAML calls it a *sequence*. |
| string | `"hello"` | Always double-quoted in JSON. |
| number | `8080`, `-1.5e3` | One number type. No separate integer or float. |
| boolean | `true`, `false` | Lowercase only. |
| null | `null` | The absence of a value. |

Objects and arrays are containers. They hold other values, including other containers, so a document can nest as deep as you like. The other four are *scalars*: leaves of the tree.

YAML has the same three building blocks: mappings, sequences, and scalars. It adds features JSON lacks (comments, anchors, several documents in one file, explicit type tags), but when a YAML file is loaded into a program, the result is almost always the same tree of maps, lists, strings, numbers, booleans, and nulls.

That is the main idea of this course. **Learn the tree first. Treat the syntax as notation for it.** Most YAML bugs come from a gap between the tree the author pictured and the tree the parser built.

## One tree, three spellings

Here is a small service description, written three ways. The script saves each spelling to a file and converts it to JSON with the course helper `yaml2json`. The `cmp` lines at the end compare the converted output byte for byte.

```run
# title: The same tree in JSON, YAML block style, and YAML flow style
cat > service.json <<'EOF'
{"name": "api", "port": 8080, "tags": ["web", "public"], "tls": null, "debug": false}
EOF

cat > service.yaml <<'EOF'
name: api
port: 8080
tags:
  - web
  - public
tls: null
debug: false
EOF

cat > service-flow.yaml <<'EOF'
{name: api, port: 8080, tags: [web, public], tls: null, debug: false}
EOF

yaml2json service.yaml > a.json
yaml2json service-flow.yaml > b.json
yaml2json service.json > c.json
cat a.json
cmp a.json b.json && echo "block style and flow style: same tree"
cmp a.json c.json && echo "YAML block style and the JSON file: same tree"
```

Three things to notice:

1. `service.json` went through a **YAML** parser and came out unchanged. YAML 1.2 was designed so that JSON documents are valid YAML.
2. The *flow style* (`{...}` and `[...]`) is YAML's JSON-like notation. Inside flow style, YAML still lets you leave strings unquoted.
3. The *block style* uses indentation and `- ` for list items. This is what most YAML files you meet look like.

## Going the other way

`json2yaml` reads strict JSON and writes block-style YAML. Lesson 17 covers what can and cannot survive a round trip. For plain data like this, nothing is lost.

```run
# title: JSON to YAML and back again
cat > order.json <<'EOF'
{
  "id": 1042,
  "customer": {"name": "Ada", "email": "ada@example.com"},
  "items": [
    {"sku": "A-1", "qty": 2},
    {"sku": "B-7", "qty": 1}
  ],
  "paid": true
}
EOF
json2yaml order.json | tee order.yaml
echo "---- back to JSON, compared with jq -S (sorted keys) ----"
yaml2json order.yaml | jq -S . > round.json
jq -S . order.json > original.json
diff original.json round.json && echo "round trip preserved the tree"
```

A sequence of mappings, written `- sku: A-1` followed by `  qty: 2`, often trips people up. The dash starts a list item, and that item is a mapping with two keys. Indentation is how you can tell `qty` belongs to the same item as `sku`.

## The tools used in this course

Every example on this site was run by the build, and the stdout and stderr shown are what came back. The examples rely on a few commands:

- `jq`, the command-line JSON processor, used from lesson 6 on.
- `python3` and `node`, used where a language's own JSON library behaves in a way worth seeing.
- Four small helpers in this repository's `tools/bin/`, each a thin wrapper around a published library:
  - `yaml2json` and `yamlcheck` use the [`yaml`](https://eemeli.org/yaml/) npm package, a YAML 1.2 parser that can also be switched to YAML 1.1 with `--yaml-1.1`.
  - `json2yaml` uses `JSON.parse` and then the same package's `stringify`.
  - `schema-check` uses [Ajv](https://ajv.js.org/) to validate against JSON Schema draft 2020-12.

To run the examples yourself, clone the repository, run `npm ci`, and put the helpers on your `PATH`:

```bash
git clone https://github.com/pragmaticarun/yaml-json-course.git
cd yaml-json-course
npm ci
export PATH="$PWD/tools/bin:$PATH"
```

The [playground](/playground) runs the same `yaml` package in your browser if you just want to try a snippet.

```run
# title: What a helper reports when the input is broken
# expect-exit: 1
printf 'name: api\n  port: 8080\n' > broken.yaml
yamlcheck broken.yaml
```

The messages give `file:line:column` and an error code from the `yaml` package. They are also a first look at how a YAML parser reads indentation. `port` is indented under `name: api`, so the parser tries to treat `api` and the next line as one value, then finds a second `key:` inside it. The real mistake is the two spaces before `port`, which the message does not mention. Lesson 9 covers indentation in detail.

```run
# title: The exit status says whether parsing succeeded
# expect-exit: 1
printf '{"name": "api",}\n' > trailing-comma.json
echo "As YAML (yaml2json accepts this flow mapping):"
yaml2json trailing-comma.json
echo "As strict JSON (json2yaml uses JSON.parse):"
json2yaml trailing-comma.json
```

The last example sets up later lessons. YAML's flow style allows a trailing comma, so the YAML parser accepted the file. `JSON.parse` follows RFC 8259, which does not, so it rejected the same bytes and the script ended with exit status 1. "Valid JSON is valid YAML" does not run in the other direction.

## Exercises

```exercise
---title---
Spell a tree three ways
---prompt---
Write a file `book.yaml` in block style that describes a book with a `title` (string), `year` (number), `authors` (a list of two names), and `in_print` (boolean). Then write the same tree as `book.json` and show with `yaml2json` and `cmp` that both files describe the same tree.
---hint---
Convert both files with `yaml2json`. The helper prints keys in the order they appear, so write the keys in the same order in both files.
---solution---
Converting both files with the same helper produces normalised JSON, which you can compare byte for byte. Key order is part of the text, so keep it the same in both files, or pipe both outputs through `jq -S .` to sort keys before comparing.
---script---
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
```

````exercise
---title---
Find the item boundary
---prompt---
Predict how many items the `steps` list has, and what keys each item has, before running the conversion:

```yaml
steps:
  - name: checkout
    uses: actions/checkout@v4
  - name: test
  run: npm test
```
---hint---
Look at the indentation of `run:`. Is it inside the second list item, or level with `steps:`?
---hint2---
`run:` starts at column 3, which is the indentation of the `- ` markers. A mapping key cannot appear at that position while the sequence is still open.
---solution---
The file is invalid. `run:` is indented less than the keys inside the list item (`name:` at column 5) and more than `steps:` (column 1), so it belongs to neither level. The parser reports an error at line 5. The fix is to indent `run:` to line up with `name:`, which makes the second item `{name: test, run: npm test}`.
---script---
cat > steps.yaml <<'EOF'
steps:
  - name: checkout
    uses: actions/checkout@v4
  - name: test
  run: npm test
EOF
yamlcheck steps.yaml || echo "(yamlcheck exit status $?)"
sed -i 's/^  run:/    run:/' steps.yaml
yaml2json steps.yaml
````
