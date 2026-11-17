---
number: 13
slug: yaml-documents
title: Documents, comments, directives, and tags
module: YAML
level: intermediate
minutes: 25
summary: A YAML file is a stream that can hold several documents. Learn the document markers, where comments are allowed, what a %YAML directive does, and how a parser treats tags it does not know.
objectives:
  - Write and split a multi-document YAML stream and convert it with --all
  - Place comments correctly and know when a # is not a comment
  - Explain what the %YAML directive changes and what an unsupported version does
  - Predict what a generic parser does with core tags like !!str and with unknown tags like !Ref
further:
  - title: YAML 1.2.2 specification, chapter 9 (Document Stream Productions)
    url: https://yaml.org/spec/1.2.2/#chapter-9-document-stream-productions
  - title: YAML 1.2.2 specification, section 6.8 (Directives)
    url: https://yaml.org/spec/1.2.2/#68-directives
  - title: YAML 1.2.2 specification, section 3.2.1.2 (Tags)
    url: https://yaml.org/spec/1.2.2/#3212-tags
pitfall: |
  A generic YAML parser does not reject a tag it does not recognise. It drops the tag and keeps the value, so `!Ref MyBucket` loads as the plain string "MyBucket". Whatever the tag meant is lost without an error. A tool that needs the tag, such as CloudFormation, must be given a parser that knows it.
---

A JSON file is one value. A YAML file is a **stream** of zero or more documents, and each document is one value. Most files have a single document, but multi-document files are routine: Kubernetes manifests and many log formats use them.

## Document markers

A line of three dashes, `---`, starts a document. A line of three dots, `...`, ends one. The start marker is optional for the first document and required to separate the rest. The end marker is rarely needed, since the next `---` also ends the previous document.

```run
# title: A stream of three documents
cat > stream.yaml <<'EOF'
a: 1
---
b: 2
...
---
c: 3
EOF
echo "== without --all"
yaml2json stream.yaml || echo "(exit status $?)"
echo "== with --all"
yaml2json --all stream.yaml | jq -c .
echo "== yamlcheck"
yamlcheck stream.yaml
```

By default `yaml2json` refuses a stream with more than one document, because a single JSON value cannot hold three. `--all` collects them into a JSON array in order. `yamlcheck` counts them: three documents, with the `...` end marker making no difference to the count.

A JSON consumer cannot read a stream, so multi-document YAML is usually split first, or converted with `--all` and processed as an array. Lesson 19 does this with a Kubernetes-style file.

## Comments

A `#` starts a comment **only when it follows whitespace or begins a line**. Inside quotes, or glued to other text, it is just a character:

```run
# title: When a # is a comment
cat > comments.yaml <<'EOF'
a: 1 # a comment
b: 2#not a comment
# a whole-line comment
c: "x # y"
EOF
yaml2json comments.yaml | jq -c .
```

`a` is `1` with the comment stripped, `b` is the string `"2#not a comment"`, and `c` keeps the `#` inside the quotes. JSON has no comments at all, so converting to JSON discards them. They are not in the tree.

One practical habit follows from the stream rule. When you receive a YAML file from someone else, count its documents before assuming it is one value. `yamlcheck` prints the count, and a file that you expected to hold a single configuration but that reports two is usually a sign of a stray `---` in the middle of a copy-and-paste.

## Directives

A line beginning with `%` before the `---` is a **directive**. The one you will see is `%YAML`, which declares the YAML version of the document. A parser that supports several versions uses it to choose rules. Here the helper runs in its default 1.2 mode, yet the directive changes the outcome:

```run
# title: A %YAML directive changes how a document is read
printf '%%YAML 1.2\n---\na: no\n' > v12.yaml
printf '%%YAML 1.1\n---\na: no\n' > v11.yaml
printf '%%YAML 1.3\n---\na: 1\n' > v13.yaml
echo "== declared 1.2"; yaml2json v12.yaml | jq -c .
echo "== declared 1.1"; yaml2json v11.yaml | jq -c .
echo "== declared 1.3"; yamlcheck v13.yaml
```

Under `%YAML 1.1`, `no` became `false`, even though no `--yaml-1.1` flag was passed. This is the Norway problem from [lesson 11](/lessons/yaml-types), switched on by the file itself. A version the parser does not know, like 1.3, produced a `BAD_DIRECTIVE` warning from `yamlcheck`, and the document was still read.

Directives are rare in practice. Most files carry none, which means the version comes from the library that loads them.

## Tags

A **tag** says what type a node is, written before the value with `!`. YAML defines a set of standard tags, spelled `!!` followed by a name. The ones that matter: `!!str`, `!!int`, `!!float`, `!!bool`, `!!null`, and `!!binary`. Beyond those, anyone can define their own, such as `!Ref` and `!Sub` in AWS CloudFormation templates.

```run
# title: Core tags and tags the parser does not know
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
```

Read the output carefully:

- `!!int "42"` forced the quoted text to the number 42, and `!!str 42` forced the number to the string `"42"`. `!!bool "true"` and `!!null ""` converted the text in the same way. So a tag can *change* the type that guessing would pick, which is why `!!str` is the heavy-duty alternative to quoting.
- The three CloudFormation tags did not fail. `!Ref MyBucket` is the string `"MyBucket"`, `!GetAtt [Res, Arn]` is a list of two strings, and `!Sub` kept its text unchanged. **The tags are gone from the JSON.**
- `yamlcheck` reports a `TAG_RESOLVE_FAILED` warning for each of the three, and still says the document is fine. `yaml2json` printed nothing to stderr and exited 0. A warning is easy to miss, and a converter has no obligation to show it.

The consequence is the one in the pitfall above. A generic loader gives you the values but not the meaning, so a CloudFormation file converted this way no longer says which strings are references.

## Exercises

```exercise
---title---
Split a stream
---prompt---
Write `docs.yaml` containing two documents: the first has `kind: config`, the second has `kind: data` and `items: [1, 2]`. Use `yaml2json --all` and `jq` to print only the `kind` of each document, one per line.
---hint---
`jq -r '.[].kind'` iterates the array and prints the values without quotes.
---solution---
Put `---` between the documents. `--all` turns the stream into a JSON array, so `.[]` visits each document.
---script---
cat > docs.yaml <<'EOF'
kind: config
---
kind: data
items: [1, 2]
EOF
yaml2json --all docs.yaml | jq -r '.[].kind'
```

````exercise
---title---
Is it a comment?
---prompt---
Predict the values of `x`, `y`, and `z` in the file below, then run it to check.

```yaml
x: 10 #ten
y: 10#ten
z: "10 #ten"
```
---hint---
A `#` only starts a comment after whitespace and outside quotes.
---solution---
`x` is 10, `y` is the string `10#ten`, and `z` is the string `10 #ten`.
---script---
cat > hash.yaml <<'EOF'
x: 10 #ten
y: 10#ten
z: "10 #ten"
EOF
yaml2json hash.yaml | jq -c .
````

```exercise
---title---
Which tag survives?
---prompt---
Convert a file with `a: !Ref Bucket` and `b: !!str 7`. Explain, from the output, what information about `a` is no longer present.
---hint---
Compare what JSON can say about a value with what the tag said.
---solution---
`a` becomes the plain string `"Bucket"`. JSON has nowhere to record that it was a reference, so a reader of the JSON cannot tell it from any other string.
---script---
cat > ref.yaml <<'EOF'
a: !Ref Bucket
b: !!str 7
EOF
yaml2json ref.yaml | jq -c .
```
