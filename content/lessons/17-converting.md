---
number: 17
slug: converting
title: Converting between YAML and JSON
module: Contracts and conversion
level: intermediate
minutes: 30
summary: JSON to YAML is easy. YAML to JSON drops comments, anchors, tags, and some keys. Capture exactly what is lost and how to compare results fairly.
objectives:
  - List what a YAML to JSON conversion discards or changes
  - Predict what happens to anchors, aliases, tags, and non-string keys
  - Explain why YAML written by one tool can be misread by another
  - Compare two documents as trees with jq -S instead of comparing text
further:
  - title: YAML 1.2.2 specification
    url: https://yaml.org/spec/1.2.2/
  - title: RFC 8259, The JSON Data Interchange Format
    url: https://www.rfc-editor.org/rfc/rfc8259
pitfall: |
  A round trip that "works" on your test file can still lose information. Conversion is safe only for the part of YAML that JSON can already express. Comments, anchors, tags, and non-string keys are gone after one pass through JSON, and nothing in the output tells you they were there.
---

Converting is mostly a question of which direction you go. JSON is the smaller format, so every JSON document has a YAML spelling. YAML is the larger one, so a conversion to JSON has to throw something away. This lesson captures what.

## Losses going to JSON

A small YAML file with a comment, an anchor, a tag, and a second document shows most of it. `yaml2json` refuses a stream of several documents unless you pass `--all`.

```run
# title: A comment, an anchor, and a second document
# expect-exit: 1
cat > multi.yaml <<'EOF'
# deployment defaults
defaults: &d
  retries: 3   # per request
service:
  <<: *d
  name: api
copy: *d
---
second: true
EOF
yaml2json multi.yaml
```

The tool stops and says the stream has two documents. JSON has no way to hold two documents in one file. With `--all` the result is an array of trees, which is a choice the tool made, not something YAML specifies.

```run
# title: One document, comments and anchors gone
cat > one.yaml <<'EOF'
# deployment defaults
defaults: &d
  retries: 3   # per request
copy: *d
EOF
yaml2json one.yaml
echo "--- and back to YAML ---"
yaml2json one.yaml | json2yaml
```

Both comments disappeared. `copy` became a full duplicate of `defaults` instead of a reference, and the way back does not restore the alias: the second YAML file has the same data, spelled out twice. If somebody edits `retries` under `defaults` in that file, `copy` no longer follows. The anchor was information about *how the author wrote it*, not about the data, and JSON has no place for it.

## Several documents

`--all` is the way through. It prints one JSON array holding one tree per document, and `jq` can then take the array apart again, one compact line per document.

```run
# title: A document stream as a JSON array
cat > stream.yaml <<'EOF'
kind: Service
name: api
---
kind: Job
name: migrate
EOF
yaml2json --all stream.yaml | jq -c '.[]'
echo "--- just the names ---"
yaml2json --all stream.yaml | jq -r '.[].name'
```

The array is a convention of this helper. A tool that reads a stream may instead emit one JSON value per line, which is the [JSON Lines](/lessons/json-lines) format, so check what a converter does with a stream before you build on it.

## Tags and keys

Tags are another thing a JSON tree cannot carry. Non-string keys are a third, because a JSON object key is always a string.

```run
# title: Tags and unusual keys through the converter
cat > odd.yaml <<'EOF'
count: !!str 12
ref: !Ref MyBucket
1: one
true: "yes"
? [a, b]
: pair
null: nothing
EOF
yaml2json odd.yaml
```

Read the output slowly. The explicit `!!str` tag made `12` a string, which survived because JSON has strings. The `!Ref` tag, which AWS CloudFormation uses, was silently dropped and only the word `MyBucket` remains. The integer key `1` and the boolean key `true` became the strings `"1"` and `"true"`. The list key `[a, b]` was flattened into the string `[ a, b ]`, and Node printed a warning on stderr saying so. The key `null` became the empty string `""`. None of those conversions fail, and none changes the exit status. If your data has keys like these, check the output by eye.

## JSON to YAML is safe, with one catch

Going the other way you start from the smaller format, so nothing can be lost. The catch is how the YAML is *written*. `json2yaml` uses the `yaml` package, which targets YAML 1.2, and only quotes a string when a 1.2 reader would otherwise read it as something else.

```run
# title: Strings that a YAML 1.1 reader would change
cat > strings.json <<'EOF'
{"country": "no", "switch": "on", "mode": "010", "ratio": "1:30", "flag": "true", "version": "3.10"}
EOF
json2yaml strings.json | tee strings.yaml
echo "--- read as YAML 1.2 ---"
yaml2json strings.yaml
echo "--- read as YAML 1.1 ---"
yaml2json --yaml-1.1 strings.yaml
```

Compare the three outputs. `json2yaml` quoted `"010"`, `"true"`, and `"3.10"`, but left `no`, `on`, and `1:30` bare. A YAML 1.2 reader gets the original strings back. A YAML 1.1 reader turns `no` into `false`, `on` into `true`, and `1:30` into the number `90`. Both readers are correct for their version. The practical rule: if you write YAML that another team's tool will load, quote any string that could be a boolean, a number, or a time, whatever your own writer does. [Lesson 11](/lessons/yaml-types) lists the cases.

## Comparing as trees

When you test a conversion, compare trees, not text. Two files that differ only in key order or whitespace describe the same data. `jq -S` sorts object keys and prints in a fixed layout, so `diff` shows only real differences.

```run
# title: Canonical comparison with jq -S
cat > a.json <<'EOF'
{"b": [1, 2], "a": {"y": 1, "x": 2}}
EOF
cat > b.yaml <<'EOF'
a:
  x: 2
  y: 1
b: [1, 2]
EOF
yaml2json b.yaml | jq -S . > b.canonical
jq -S . a.json > a.canonical
diff a.canonical b.canonical && echo "same tree"
echo "--- a real difference ---"
echo '{"a": {"x": 2, "y": 1}, "b": [2, 1]}' | jq -S . > c.canonical
diff a.canonical c.canonical || true
```

Arrays are ordered, so `[1, 2]` and `[2, 1]` differ, and `diff` reports it. Objects are not, so `jq -S` is allowed to reorder keys.

## A conversion checklist

Before you rely on a YAML to JSON step in a pipeline, ask five questions. Does the file contain more than one document? Does anything depend on an anchor staying a shared reference rather than a copy? Are there tags the downstream tool needs? Are all keys plain strings? And do any bare words, such as `no`, `on`, or version numbers, need quoting for the *next* reader? A "no" to all five means the round trip is lossless.

## Exercises

```exercise
---title---
Spot the loss
---prompt---
Convert this YAML to JSON and back, then list every difference between the original and the result: `# build`, `base: &b {os: linux}`, `ci: *b`, `v: !!str 1`.
---hint---
Look for what is in the YAML text but not in the JSON: comments, anchor names, and tags.
---solution---
The comment is gone. `ci` is now a full copy rather than an alias, and the anchor name `b` is gone. The `!!str` tag is gone too, but the value stays the string `"1"` because the converter had already resolved it.
---script---
cat > in.yaml <<'EOF'
# build
base: &b {os: linux}
ci: *b
v: !!str 1
EOF
yaml2json in.yaml | tee out.json
json2yaml out.json
```

```exercise
---title---
Make YAML safe for a 1.1 reader
---prompt---
Take `{"answer": "yes", "region": "no"}`, produce YAML with `json2yaml`, then edit it so that a YAML 1.1 reader also gets strings. Prove it with `yaml2json --yaml-1.1`.
---hint---
Quote the values by hand. Single or double quotes both work.
---solution---
Quoting `"yes"` and `"no"` turns them into strings for either version, so the 1.1 read matches the 1.2 read.
---script---
echo '{"answer": "yes", "region": "no"}' | json2yaml > raw.yaml
cat raw.yaml
echo "--- 1.1 read of the raw file ---"
yaml2json --yaml-1.1 raw.yaml
printf 'answer: "yes"\nregion: "no"\n' > safe.yaml
echo "--- 1.1 read of the quoted file ---"
yaml2json --yaml-1.1 safe.yaml
```
