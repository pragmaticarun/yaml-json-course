---
number: 5
slug: json-objects
title: Objects, duplicate keys, and ordering
module: JSON
level: intermediate
minutes: 25
summary: A JSON object looks like a dictionary, but the grammar is looser than any dictionary type. Duplicate keys, key order, and the difference between null and missing all behave differently from what you might assume.
objectives:
  - Say what RFC 8259 requires, and does not require, of object keys
  - Show how four tools treat a duplicated key and how to reject duplicates in Python
  - Explain why key order cannot carry meaning, and where it still shows up
  - Distinguish a key set to null from a missing key in jq, Python, and JavaScript
further:
  - title: RFC 8259, section 4 (Objects)
    url: https://www.rfc-editor.org/rfc/rfc8259#section-4
  - title: Python json module, object_pairs_hook
    url: https://docs.python.org/3/library/json.html#json.load
  - title: jq manual (keys, has, the alternative operator //)
    url: https://jqlang.org/manual/
pitfall: |
  RFC 8259 says object names SHOULD be unique and that behaviour on duplicates is unpredictable. "Unpredictable" means two systems can read the same bytes and disagree. If a duplicate could change a permission or a price, reject it explicitly instead of trusting every parser to pick the same winner.
---

An object is a set of name/value pairs. The grammar requires the names to be strings. It does not require them to be unique, and it says nothing about order. The RFC's wording is that names **should** be unique. Software is free to do something else, and it does.

## Duplicate keys

The script below parses `{"a":1,"b":2,"a":3}` with four tools: jq, node, Python, and the course's `yaml2json` helper, which is a YAML parser reading the JSON.

```run
# title: One duplicated key, four tools
echo '{"a":1,"b":2,"a":3}' > dup.json
echo "jq:     $(jq -c . dup.json)"
echo "node:   $(node -e 'console.log(JSON.stringify(JSON.parse(require("fs").readFileSync("dup.json","utf8"))))')"
echo "python: $(python3 -c 'import json; print(json.dumps(json.load(open("dup.json"))))')"
echo "yaml2json:"
yaml2json dup.json || echo "(exit status $?)"
```

jq, node, and Python all return `{"a":3,"b":2}`: the **last** value wins, and the key keeps the position of its first appearance. That agreement is a convention, and not one you can rely on in every library. The YAML parser takes the opposite view. It reports `DUPLICATE_KEY` with a position and the helper exits with status 1. YAML 1.2 requires keys to be unique, so a parser that rejects the duplicate is following its specification.

Python can also be made strict. `json.load` calls an `object_pairs_hook` with the list of pairs before it builds the dictionary, and that list still contains both entries.

```run
# title: Rejecting duplicate keys in Python
# expect-exit: 1
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
```

The example is deliberately a security-shaped one. If one component reads `role` as `user` and another as `admin`, you have a vulnerability, and the usual cause is two parsers with different rules about the same bytes.

## Key order

An object is unordered, so no program should depend on key order. That does not mean order is invisible. Parsers preserve it differently, and diffs, hashes, and signatures all see the bytes.

```run
# title: Key order in jq, node, and Python
echo '{"z":1,"b":2,"a":{"y":1,"x":2},"1":"one","0":"zero"}' > ord.json
echo "input:       $(cat ord.json)"
echo "jq:          $(jq -c . ord.json)"
echo "jq -S:       $(jq -S -c . ord.json)"
echo "node:        $(node -e 'console.log(JSON.stringify(JSON.parse(require("fs").readFileSync("ord.json","utf8"))))')"
echo "python:      $(python3 -c 'import json; print(json.dumps(json.load(open("ord.json"))))')"
echo "python sort: $(python3 -c 'import json; print(json.dumps(json.load(open("ord.json")), sort_keys=True))')"
```

jq and Python write keys back in the order they were read. `jq -S` and `sort_keys=True` sort them, at every level, which is how you make two documents comparable with `diff`. node is the surprise: it put `"0"` and `"1"` **first**, in numeric order, ahead of the other keys. JavaScript objects order integer-like keys before string keys, and `JSON.parse` builds ordinary objects. Any order you saw in a JavaScript client for numeric keys is the language's, not the document's.

For stable output, sort keys before you hash, sign, or diff. Lesson [Converting between YAML and JSON](/lessons/converting) uses `jq -S` for exactly this.

## null is not missing

`{"a": null}` and `{}` are different documents. A key set to `null` exists. A missing key does not. Whether your language shows the difference depends on how you ask.

```run
# title: null versus a missing key
echo '{"a": null, "c": 1}' > nul.json
echo "jq has(a), has(b):  $(jq -c '[has("a"), has("b")]' nul.json)"
echo "jq .a, .b:          $(jq -c '[.a, .b]' nul.json)"
echo "jq .a // dflt:      $(jq -c '[.a // "dflt", .c // "dflt"]' nul.json)"
python3 - <<'EOF'
import json
d = json.load(open("nul.json"))
print("python d.get:       ", d.get("a"), d.get("b"))
print("python in:          ", "a" in d, "b" in d)
EOF
node -e '
const d = JSON.parse(require("fs").readFileSync("nul.json", "utf8"));
console.log("node values:        ", d.a, d.b);
console.log("node in:            ", "a" in d, "b" in d);
console.log("node stringify:     ", JSON.stringify({x: undefined, y: null}));
'
```

Reading `.a` and `.b` in jq gives `null` for both, but `has` tells them apart. Python's `d.get` returns `None` for both, while `in` shows which exists. In node, reading the missing key gives `undefined`, a value JSON cannot write, so `JSON.stringify` drops the key `x` altogether and keeps `y`. Notice also that jq's `//` operator replaces both `null` and `false` with its default, so `.a // "dflt"` treats a present-but-null key like a missing one.

Choose a convention for your own formats and document it. Some APIs treat `null` as "clear this field" and a missing key as "leave it alone", and that distinction is what makes partial updates work.

## Empty containers

`{}` and `[]` are valid values and are not `null`. They are what you get from an object with no members or a list with no items.

```run
# title: Empty objects and arrays
echo '{"a":{},"b":[]}' > empty.json
jq -c '[(.a|length), (.b|length), (.a == .b), (.a == null)]' empty.json
jq -c '{"a": null} | del(.a)' empty.json
```

Both have length 0, the two are not equal to each other, and neither equals `null`. The last line shows `del` removing a key: deleting `a` from `{"a":null}` leaves `{}`, a different document from `{"a":null}`.

## Exercises

```exercise
---title---
Last one wins
---prompt---
Write a JSON object in which the key `limit` appears three times, with the values 10, 20, and 30. Show what jq prints and what the YAML helper `yamlcheck` says about the same file.
---hint---
The YAML parser reports the second and third duplicates separately.
---solution---
jq prints `{"limit":30}`. `yamlcheck` reports a `DUPLICATE_KEY` error with line and column for each repeated key and exits with status 1, so a pipeline can stop on it.
---script---
echo '{"limit":10,"limit":20,"limit":30}' > l.json
jq -c . l.json
yamlcheck l.json || echo "(exit status $?)"
```

```exercise
---title---
Tell null from missing
---prompt---
For the document `{"nickname": null}`, print three jq results: whether the key `nickname` exists, whether `.nickname` is null, and whether the key `email` exists.
---hint---
`has("name")` is about presence. `.name == null` is about the value.
---solution---
`has("nickname")` is `true`, `.nickname == null` is `true`, and `has("email")` is `false`. Reading `.email` would also be `null`, which is why `has` is the test for presence.
---script---
echo '{"nickname": null}' > nick.json
jq -c '[has("nickname"), (.nickname == null), has("email")]' nick.json
```
