---
number: 2
slug: json-grammar
title: The whole JSON grammar
module: JSON
level: beginner
minutes: 25
summary: JSON is small enough to hold in your head. Learn what it allows, what it forbids, and why three parsers can disagree about the forbidden parts.
objectives:
  - Write valid JSON for each of the six value kinds, including a top-level scalar
  - List the things people add to JSON that the grammar does not allow
  - Read the error messages that node, Python, and jq give for the same bad input
  - Explain why a lenient parser is a hazard when you are validating input
further:
  - title: RFC 8259, The JavaScript Object Notation (JSON) Data Interchange Format
    url: https://www.rfc-editor.org/rfc/rfc8259
  - title: Python json module documentation
    url: https://docs.python.org/3/library/json.html
  - title: jq manual
    url: https://jqlang.org/manual/
pitfall: |
  A parser that accepts something the grammar forbids is not "being helpful". If service A validates with a lenient parser and service B reads the same bytes with a strict one, they can disagree about what the document says. The installed jq 1.6 below is lenient in exactly this way.
---

The JSON grammar fits on one page of RFC 8259. That is a feature. Every language has a parser for it, and the format has almost no room for dialects. In practice dialects appear anyway, mostly at the edges of the grammar. This lesson maps those edges.

## What the grammar allows

A JSON text is **one value**, with optional whitespace around it. A value is an object, an array, a string, a number, `true`, `false`, or `null`. Older documentation says a top-level value must be an object or array. That was RFC 4627. RFC 8259 dropped the restriction, so `42` and `"hi"` are complete, valid JSON documents.

Whitespace is four characters: space, tab, line feed, carriage return. It may appear between any two tokens and nowhere inside one. Objects and arrays separate their members with commas, and objects join name to value with a colon. That is all of it.

The next script feeds the same top-level scalars to three parsers. `jq -c .` prints compact JSON, `node` uses `JSON.parse`, and Python uses `json.load`.

```run
# title: Top-level scalars are valid JSON
for text in '42' '"hi"' 'null' 'true' '[]'; do
  printf '%s\n' "$text" > doc.json
  printf '%-6s jq=%s' "$text" "$(jq -c . doc.json)"
  printf ' node=%s' "$(node -e 'console.log(JSON.stringify(JSON.parse(require("fs").readFileSync("doc.json","utf8"))))')"
  printf ' python=%s\n' "$(python3 -c 'import json; print(json.dumps(json.load(open("doc.json"))))')"
done
```

All three agree. Note that `null` is a document too. A file whose entire content is `null` is valid, and a program that reads it must not assume it got an object.

## What the grammar forbids

People bring habits from JavaScript, Python, and YAML. Each of these is **not** JSON:

| Habit | Example | Why people try it |
| --- | --- | --- |
| Trailing comma | `{"a": 1,}` | Cleaner diffs when you add a line |
| Single quotes | `{'a': 1}` | Python and JavaScript allow them |
| Unquoted keys | `{a: 1}` | JavaScript object literals |
| Leading zeros | `{"a": 01}` | Zero-padded IDs |
| `NaN`, `Infinity` | `{"a": NaN}` | Floating-point results |
| Comments | `// note` or `/* note */` | Config files |

Run each one through all three parsers and look at what comes back.

```run
# title: Six invalid inputs, three parsers
cat > cases.txt <<'EOF'
{"a":1,}
{'a':1}
{a:1}
{"a":01}
{"a":NaN}
{"a":Infinity}
EOF
while IFS= read -r text; do
  printf '%s\n' "$text" > t.json
  echo "--- $text"
  echo "jq:     $(jq -c . t.json 2>&1 | head -1)"
  echo "node:   $(node -e 'try{console.log(JSON.stringify(JSON.parse(require("fs").readFileSync("t.json","utf8"))))}catch(e){console.log("ERROR",e.message.split("\n")[0].slice(0,60))}')"
  echo "python: $(python3 -c '
import json
try: print(json.dumps(json.load(open("t.json"))))
except Exception as e: print("ERROR", e)')"
done < cases.txt
```

Read the output line by line:

- The first three inputs are rejected by all three parsers. The messages differ in wording, but each points at a line and column, which is what you want when hunting a stray comma in a large file.
- `01` is rejected by node and Python, but the installed **jq 1.6 accepts it and prints `1`**. A leading zero is not allowed by the grammar, so jq is being lenient.
- `NaN` and `Infinity` are rejected by node. **Python accepts both** and prints them back. jq 1.6 accepts them too, but silently changes them: `NaN` became `null` and `Infinity` became the largest finite double, `1.7976931348623157e+308`.

That last result is the dangerous one. A value that JSON cannot represent went in, and a different, valid-looking value came out, with exit status 0 and no warning.

## Making Python strict

Python's `json` module accepts `NaN`, `Infinity`, and `-Infinity` by default. The `parse_constant` hook is called for those three names, and you can raise from it.

```run
# title: Forbidding NaN in Python with parse_constant
# expect-exit: 1
cat > strict.py <<'EOF'
import json, sys

def reject(name):
    raise ValueError(f"{name} is not valid JSON")

text = sys.argv[1]
print("default:", json.loads(text))
print("strict: ", json.loads(text, parse_constant=reject))
EOF
python3 strict.py '{"ratio": NaN}' 2>&1 | grep -E '^(default|strict|ValueError)'
```

Without the hook the document loads; with it, loading fails with the message from `reject`. If you write a service that accepts JSON from outside, pass this hook. The same module can also write the invalid value: `json.dumps(float("nan"))` produces `NaN`, which strict parsers then refuse. Pass `allow_nan=False` to `dumps` so that you find out at the sending end.

## Comments

JSON has no comments. Crockford removed them on purpose, to stop people hiding parsing directives in them. Files such as `tsconfig.json` accept comments because TypeScript reads them with its own lenient parser (lesson [Config files](/lessons/config-files)), not because JSON allows them. The next script shows what the parsers here do with one.

```run
# title: Comments are an error everywhere here
printf '// the port\n{"port": 8080}\n' > commented.json
jq -c . commented.json 2>&1 | head -1 || true
python3 -c 'import json; json.load(open("commented.json"))' 2>&1 | tail -1 || true
```

If you need a comment in data that must stay strict, the usual workaround is a key such as `"_comment"`, which the consumer is told to ignore. YAML has real comments, which is one reason people prefer it for files that humans edit (lesson [YAML structure](/lessons/yaml-structure)).

## Empty input is not a document

An empty file contains no value, so it is not valid JSON. Node and Python report an error. jq 1.6 prints nothing and exits 0, so a pipeline can carry on with an empty result and no failure. Check what your tool does before relying on its exit status to catch a truncated download.

```run
# title: Empty input
: > empty.json
jq -c . empty.json; echo "jq exit: $?"
python3 -c 'import json; json.load(open("empty.json"))' 2>&1 | tail -1 || true
```

## Exercises

```exercise
---title---
Repair the document
---prompt---
The file below is almost JSON. Write `fixed.json` so that it is valid and says the same thing, then check it with `jq -c .` and `python3 -m json.tool`.

`{'name': "api", port: 8080, "tags": ["a", "b",], "debug": False}`
---hint---
There are four separate problems: one kind of quote, one unquoted key, one trailing comma, and one value that is a Python spelling.
---solution---
Use double quotes for `name`, quote `port`, delete the comma before the closing bracket, and write the boolean as lowercase `false`. Python's `False` is not JSON, but `false` is.
---script---
cat > fixed.json <<'EOF'
{"name": "api", "port": 8080, "tags": ["a", "b"], "debug": false}
EOF
jq -c . fixed.json
python3 -m json.tool --compact fixed.json
```

```exercise
---title---
Catch NaN at the boundary
---prompt---
Write a short Python script that reads a JSON document from standard input and exits with status 1 and a one-line message if it contains `NaN`, `Infinity`, or `-Infinity`. Test it on `{"x": 1}` and `{"x": NaN}`.
---hint---
Use `parse_constant` and catch the exception in the caller.
---solution---
`parse_constant` is called with the string name of the constant. Raising from it aborts the parse, and you can turn that into the message and exit status you want.
---script---
cat > check.py <<'EOF'
import json, sys

def reject(name):
    raise ValueError(name)

try:
    json.load(sys.stdin, parse_constant=reject)
except ValueError as err:
    print(f"rejected: {err}")
    sys.exit(1)
print("ok")
EOF
echo '{"x": 1}' | python3 check.py
echo '{"x": NaN}' | python3 check.py || echo "(exit status $?)"
```
