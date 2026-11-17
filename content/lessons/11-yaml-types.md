---
number: 11
slug: yaml-types
title: Implicit types and the Norway problem
module: YAML
level: intermediate
minutes: 30
summary: An unquoted YAML value is a string only if it fails to look like something else. See what YAML 1.2 and YAML 1.1 each turn into numbers, booleans, and nulls, and how quoting stops it.
objectives:
  - Explain how a YAML parser decides the type of an unquoted scalar
  - Reproduce the Norway problem and the other well-known 1.1 surprises
  - Tell which of these changed in YAML 1.2 and which did not
  - Use quoting or an explicit tag so a value stays a string
further:
  - title: YAML 1.2.2 specification, section 10.3 (Core Schema)
    url: https://yaml.org/spec/1.2.2/#103-core-schema
  - title: YAML 1.1 type repository (bool)
    url: https://yaml.org/type/bool.html
  - title: The yaml npm package, document and schema options
    url: https://eemeli.org/yaml/#options
pitfall: |
  Two programs can load the same YAML file and get different trees, because they implement different YAML versions. A library that follows YAML 1.1 reads `no` as false, `010` as 8, and `1:30` as 90. One that follows 1.2 does not. If a value must be a string, quote it, so the answer does not depend on which parser reads the file.
---

JSON values carry their type in their spelling: quotes mean string, digits mean number, `true` means boolean. A YAML scalar does not need quotes, so the parser has to *guess* the type of an unquoted value from its text. The rules for guessing are the YAML **schema**, and there are two you will meet.

## Two sets of rules

- **YAML 1.2 Core schema** is what the `yaml2json` helper uses by default. It recognises `null`, `~`, an empty value, `true`/`false` in a few capitalisations, decimal integers, floats, and `0x` hex and `0o` octal.
- **YAML 1.1** has a larger set. It also treats `yes`, `no`, `on`, `off`, `y`, `n` as booleans, reads a leading `0` as octal, and reads `1:30` as a number in base 60. Some very widely used libraries still implement 1.1. PyYAML is the best-known example.

The helper takes `--yaml-1.1` to switch. Here is one file read both ways:

```run
# title: One file, two schemas
cat > t.yaml <<'EOF'
countries: [GB, NO, DE]
switches: [yes, no, on, off, y, n]
octal_looking: 010
explicit_octal: 0o10
duration: 1:30
version: 3.10
EOF
echo "== YAML 1.2 (default)"
yaml2json t.yaml | jq -c .
echo "== YAML 1.1"
yaml2json --yaml-1.1 t.yaml | jq -c .
```

Compare the two lines:

- **`countries`.** Under 1.1 the second item, `NO`, became `false`. This is the **Norway problem**: a list of ISO country codes loses Norway because `NO` looks like "no".
- **`switches`.** Under 1.2 only `true` and `false` are booleans, so the six words stay strings. Under 1.1 all six become booleans.
- **`octal_looking`.** `010` is 10 under 1.2 (a decimal with a leading zero) and 8 under 1.1. An octal literal in 1.2 must be written `0o10`, and in 1.1 that is not a number, so it stays the string `"0o10"`.
- **`duration`.** `1:30` is the string `"1:30"` under 1.2 and the number 90 under 1.1 (one minute thirty seconds, counted in base 60).
- **`version`.** Both give `3.1`. `3.10` is a float in either schema, and the trailing zero is not kept. A version that must read `3.10` has to be a string.

The version case is not a YAML 1.1 quirk. It follows from the number rule alone, which makes it a common source of bugs in CI matrices, where `python: [3.8, 3.9, 3.10]` loses the last one's identity.

A note on the word "guess". The resolution of types happens in the parser, before your program sees the data. By the time you hold a value in memory, nothing records whether the author wrote `no` or `false`, or `010` or `10`. A bug that comes from the wrong guess cannot be fixed afterwards in application code, because the information is already gone. It has to be fixed in the source file or in the parser settings.

## The key `on`

The same schema difference changes keys, not just values:

```run
# title: A key named on
printf 'on: push\nname: ci\n' > wf.yaml
echo "== YAML 1.2"
yaml2json wf.yaml | jq -c .
echo "== YAML 1.1"
yaml2json --yaml-1.1 wf.yaml | jq -c .
```

Under 1.1 the key `on` became the string `"true"`, because JSON keys must be strings and the boolean `true` has to be spelled somehow. GitHub Actions workflows start with `on:`, so this is a known trap when you load a workflow with a 1.1 library. Lesson 18 returns to it.

## Nulls, empties, and special floats

```run
# title: Null spellings and special floats
cat > nulls.yaml <<'EOF'
tilde: ~
empty:
word: null
inf: .inf
nan: .nan
hex: 0x1F
plus: +12
exp: 1e3
date: 2024-01-15
EOF
echo "== YAML 1.2"
yaml2json nulls.yaml | jq -c .
echo "== YAML 1.1"
yaml2json --yaml-1.1 nulls.yaml | jq -c .
```

Three spellings of null agree: `~`, nothing at all, and the word `null`. A missing value is `null`, not an empty string. If you want an empty string, write `''`.

Two lines of the output deserve care:

- **`inf` and `nan`.** Both schemas parse `.inf` and `.nan` into real floating-point infinity and not-a-number, but **JSON cannot represent either**. The helper's `JSON.stringify` step wrote `null` for both, so the output does not distinguish them from a true null. Treat that as a limit of converting to JSON, not as the YAML meaning.
- **`date`.** YAML 1.2 Core leaves `2024-01-15` as a string. YAML 1.1 has a timestamp type, so the library turned it into a date object, which appears in JSON as `"2024-01-15T00:00:00.000Z"`, with a time and a time zone that were never in the source.

## The fix: say what you mean

Quoting always gives a string, in any version. An explicit tag does the same:

```run
# title: Quoting and !!str keep strings as strings
cat > safe.yaml <<'EOF'
countries: [GB, "NO", DE]
code: !!str 010
duration: "1:30"
version: "3.10"
EOF
echo "== YAML 1.2"
yaml2json safe.yaml | jq -c .
echo "== YAML 1.1"
yaml2json --yaml-1.1 safe.yaml | jq -c .
```

Both parsers give the same result now. That is the property you want from config that other people's tools will read.

Many teams adopt a simple convention: quote every string that could be mistaken for another type, and run a schema check ([JSON Schema basics](/lessons/json-schema-basics)) so a value of the wrong type is caught on load, not in production.

## Exercises

````exercise
---title---
Find the lost value
---prompt---
The file below is read by a tool that implements YAML 1.1. Run it both ways, and name which values differ. Then fix the file so both versions agree.

```yaml
flags: [on, off]
region: no
build: 007
```
---hint---
Compare the two JSON outputs. A quoted string is the same in both versions.
---solution---
`flags` and `region` are strings under 1.2 and booleans under 1.1. `build` is the number 7 under both, so it does not differ, but it is still not the string `007` that a build label probably should be. Quote all three so every parser agrees.
---script---
cat > flags.yaml <<'EOF'
flags: [on, off]
region: no
build: 007
EOF
echo "== 1.2"; yaml2json flags.yaml | jq -c .
echo "== 1.1"; yaml2json --yaml-1.1 flags.yaml | jq -c .
cat > fixed.yaml <<'EOF'
flags: ["on", "off"]
region: "no"
build: "007"
EOF
echo "== fixed, 1.2"; yaml2json fixed.yaml | jq -c .
echo "== fixed, 1.1"; yaml2json --yaml-1.1 fixed.yaml | jq -c .
````

```exercise
---title---
Keep the trailing zero
---prompt---
A CI matrix lists Python versions 3.8, 3.9, and 3.10. Write `matrix.yaml` so that all three load as the strings `"3.8"`, `"3.9"`, and `"3.10"`, and print the result with `jq -c`.
---hint---
Any quoting style works. Quote all three so they match.
---solution---
Quote every version. Quoting only `3.10` would work but leaves a list of mixed types.
---script---
cat > matrix.yaml <<'EOF'
python: ["3.8", "3.9", "3.10"]
EOF
yaml2json matrix.yaml | jq -c .
```

```exercise
---title---
Predict the types
---prompt---
Before running anything, write down the JSON type of each item in the flow sequence below. Then write it to `types.yaml` and use `jq -c 'map(type)'` to check your answers.

Items: `1`, `1.0`, `"1"`, `true`, `"true"`, `~`, and an empty single-quoted string.
---hint---
Quotes make a string in any style. `~` is one of the null spellings.
---solution---
`1` and `1.0` are numbers (JSON does not keep the difference between them, see [JSON numbers](/lessons/json-numbers)), `true` is a boolean, and `~` is null. `"1"`, `"true"`, and the empty quoted string are strings.
---script---
cat > types.yaml <<'EOF'
[1, 1.0, "1", true, "true", ~, '']
EOF
yaml2json types.yaml | jq -c 'map(type)'
```
