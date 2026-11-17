---
number: 14
slug: yaml-safety
title: Loading untrusted YAML safely
module: YAML
level: advanced
minutes: 30
summary: "YAML's power is also its attack surface: tags that construct objects, alias expansion that exhausts memory, and silent surprises like duplicate keys. Learn the habit that covers them."
objectives:
  - Explain why a YAML loader that builds language-specific objects is dangerous on untrusted input
  - Show that a few hundred bytes of aliases can describe half a million values, and how a limit stops it
  - Detect duplicate keys instead of letting one silently win
  - Apply the rule "parse with a safe loader, then validate against a schema"
further:
  - title: PyYAML documentation, loading YAML
    url: https://pyyaml.org/wiki/PyYAMLDocumentation
  - title: The yaml npm package documentation, parse options
    url: https://eemeli.org/yaml/#options
  - title: YAML 1.2.2 specification, section 3.2.2.2 (Anchors and Aliases)
    url: https://yaml.org/spec/1.2.2/#3222-anchors-and-aliases
pitfall: |
  A parser can be "safe" and still hand you data you did not expect. Safe loading answers "can this file run code or eat all my memory?". It does not answer "is `port` a number between 1 and 65535?". That second question is validation, and it is a separate step.
---

Everything so far assumed you wrote the file. A YAML file that arrives from a user, a pull request, or an upload is **untrusted input**, and YAML needs more care than JSON here because it is a richer language. This lesson covers the specific ways it goes wrong and the small number of habits that prevent them.

## Risk 1: tags that build objects

A tag names a type, and some loaders let a tag name a *type in the host language*. This is a documented behaviour of PyYAML. Its full loader, `yaml.load` with an unsafe loader class, can construct arbitrary Python objects from tags such as `!!python/object/apply:...`, and that includes calling functions. For that reason PyYAML's documentation tells you to use `yaml.safe_load` for any input you do not control, which accepts only the standard YAML types. Treating `load` as an alias for `safe_load` is the classic mistake. Libraries in other languages that can build native objects from tags carry the same class of risk, so the advice is the same everywhere.

This course does not run such a payload. What we can show safely is what a *generic, safe* parser does with the same text:

```run
# title: A language-specific tag in a safe parser
cat > payload.yaml <<'EOF'
!!python/object/apply:os.system ["echo hi"]
EOF
echo "== yaml2json"
yaml2json payload.yaml | jq -c .
echo "== yamlcheck"
yamlcheck payload.yaml
```

The `yaml` package does not know a `python/object/apply` tag. It reported an unresolved tag, dropped it, and returned the argument list as plain data. Nothing was called, since this parser has no mechanism for constructing objects from tags. That is what "safe" means in practice: the document can only produce maps, lists, strings, numbers, booleans, and nulls.

Rule one: use the safe entry point of whichever library you have, and never enable object construction for input you did not write.

## Risk 2: aliases that expand

Lesson 12 showed that an alias is a copy in JSON. That means a small document can describe a very large one. Here each level lists the previous level nine times:

```run
# title: A small file that describes a very large one
cat > bomb.yaml <<'EOF'
a: &a ["lol","lol","lol","lol","lol","lol","lol","lol","lol"]
b: &b [*a,*a,*a,*a,*a,*a,*a,*a,*a]
c: &c [*b,*b,*b,*b,*b,*b,*b,*b,*b]
d: &d [*c,*c,*c,*c,*c,*c,*c,*c,*c]
e: &e [*d,*d,*d,*d,*d,*d,*d,*d,*d]
f: &f [*e,*e,*e,*e,*e,*e,*e,*e,*e]
EOF
printf 'source size: '; wc -c < bomb.yaml
echo "nine to the sixth power: $((9*9*9*9*9*9)) copies of \"lol\" under f"
yaml2json bomb.yaml || echo "(exit status $?)"
```

The file is 237 bytes, as the first line of output shows. Fully expanded, `f` alone holds 531441 strings. This is the "billion laughs" attack, and a parser that expands it naively can use gigabytes of memory.

The `yaml` package guards against this with a limit, `maxAliasCount`, and `yaml2json` exposes it as `--max-alias-count`. The default rejected the file above with a clear message. The same limit is useful in the other direction too: you can lower it for small, hand-written configs.

```run
# title: The alias limit, raised and lowered
cat > small.yaml <<'EOF'
a: &a [x, x, x, x]
b: &b [*a, *a, *a, *a]
c: &c [*b, *b, *b, *b]
EOF
echo "== default limit"
yaml2json small.yaml | jq -c '.c | flatten | length'
echo "== limit 10"
yaml2json --max-alias-count 10 small.yaml || echo "(exit status $?)"
```

The 64 strings in `small.yaml` pass the default limit and fail a limit of 10. Pick a limit that is generous for your legitimate files and far from what an attacker would want. Other libraries have different defaults, or none. Check yours.

Size limits matter too, but they belong outside the parser: cap the upload size, and cap nesting depth if your loader exposes it.

## Risk 3: duplicate keys

A mapping with the same key twice is ambiguous. JSON's RFC says names SHOULD be unique and does not say what a parser must do, so different tools disagree. YAML 1.2 requires keys to be unique, and the `yaml` package reports an error:

```run
# title: Duplicate keys in YAML and in JSON
printf 'role: user\nrole: admin\n' > dup.yaml
printf '{"role": "user", "role": "admin"}\n' > dup.json
echo "== YAML, yamlcheck"
yamlcheck dup.yaml || true
echo "== JSON text, read as YAML"
yamlcheck dup.json || true
echo "== JSON text, jq"
jq -c . dup.json
```

`yamlcheck` flagged both files, but `jq` printed `{"role":"admin"}` without complaint: the last value won. This is a security issue, not a style point. If one component validates the first value and another uses the last, an attacker can show each component a different answer. Rejecting duplicate keys at parse time closes that gap. For more on this see [JSON objects](/lessons/json-objects).

## The habit: safe parse, then validate

Safe loading tells you the data has the shape of plain maps and lists. It does not tell you the *contents* are right. Add a second step, which is to check the result against a schema, covered in [JSON Schema basics](/lessons/json-schema-basics):

```run
# title: Safe parse, then validate
cat > schema.json <<'EOF'
{
  "type": "object",
  "required": ["role", "port"],
  "properties": {
    "role": {"enum": ["user", "admin"]},
    "port": {"type": "integer", "minimum": 1, "maximum": 65535}
  },
  "additionalProperties": false
}
EOF
printf 'role: user\nport: 8080\n' > good.yaml
printf 'role: root\nport: "8080"\nextra: true\n' > bad.yaml
schema-check schema.json good.yaml bad.yaml || echo "(exit status $?)"
```

The good file passes. The bad one fails three checks at once: wrong role, a port that is a string, and an extra key. All three are things a safe parser accepts happily. The `|| echo` shows the exit status is non-zero, which is what a CI step or upload handler can act on.

Each step catches a different thing. The safe loader stops code execution, the alias limit stops memory exhaustion, the duplicate-key check stops two components disagreeing about one document, and the schema stops well-formed but wrong data. None of them replaces the others, and all four are cheap compared with an incident. If your language's YAML library cannot reject duplicate keys or cap aliases, put a small checker like `yamlcheck` in front of it in CI.

In short: use the safe loader, set resource limits, reject duplicate keys, validate the result, and only then use it.

## Exercises

```exercise
---title---
Lower the limit
---prompt---
Write a file with an anchored list `a` of three items and a key `b` that uses `*a` four times. Find the smallest `--max-alias-count` from 1, 2, 5, 10 that lets `yaml2json` succeed. Report it.
---hint---
Loop over the candidate values and check each exit status. Use `|| true` so a failing value does not stop the loop.
---solution---
In the captured run, 1 and 2 were rejected and 5 succeeded. The exact counting rule belongs to the library, so measure it for your own tool rather than assuming it equals the number of `*` signs in the file.
---script---
cat > refs.yaml <<'EOF'
a: &a [1, 2, 3]
b: [*a, *a, *a, *a]
EOF
for n in 1 2 5 10; do
  if yaml2json --max-alias-count $n refs.yaml > /dev/null 2>&1; then
    echo "limit $n: ok"
  else
    echo "limit $n: rejected"
  fi
done
```

```exercise
---title---
Catch the duplicate
---prompt---
A config has `timeout` set twice with different values. Write it, then run `yamlcheck` and `yaml2json` on it. Show that neither accepts it, and state the exit status.
---hint---
Both tools print the position of the second key.
---solution---
Both report `DUPLICATE_KEY` at the second occurrence and exit with status 1, so a pipeline stops instead of picking one value.
---script---
printf 'timeout: 5\nretries: 3\ntimeout: 60\n' > cfg.yaml
yamlcheck cfg.yaml || echo "yamlcheck exit $?"
yaml2json cfg.yaml || echo "yaml2json exit $?"
```

```exercise
---title---
Parse is not validate
---prompt---
Write `req.yaml` with `count: lots`. Show that `yamlcheck` calls it fine, then write a schema that requires `count` to be an integer and show `schema-check` rejecting it.
---hint---
A schema is plain JSON. `{"type": "object", "properties": {"count": {"type": "integer"}}}` is enough.
---solution---
`lots` is a valid string, so parsing succeeds. The schema turns "valid YAML" into "valid for this program".
---script---
printf 'count: lots\n' > req.yaml
echo '{"type":"object","properties":{"count":{"type":"integer"}}}' > req.schema.json
yamlcheck req.yaml
schema-check req.schema.json req.yaml || echo "(exit status $?)"
```
