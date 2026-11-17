---
number: 16
slug: json-schema-composition
title: Composing schemas
module: Contracts and conversion
level: advanced
minutes: 35
summary: Reuse pieces with $defs and $ref, combine rules with allOf, anyOf, oneOf and not, branch with if/then/else, and learn why additionalProperties misbehaves next to allOf.
objectives:
  - Factor repeated shapes into $defs and refer to them with $ref
  - Choose between allOf, anyOf, oneOf, and not
  - Use if/then/else for rules that depend on another field
  - Explain why unevaluatedProperties works with allOf where additionalProperties does not
  - State what validation does and does not do with default
further:
  - title: JSON Schema draft 2020-12
    url: https://json-schema.org/draft/2020-12
  - title: Understanding JSON Schema
    url: https://json-schema.org/understanding-json-schema/
  - title: Ajv documentation
    url: https://ajv.js.org/
pitfall: |
  `additionalProperties` only looks at the `properties` that sit beside it in the same schema object. It cannot see properties declared inside an `allOf` branch, so combining the two rejects keys that every branch accepts. Use `unevaluatedProperties` when you extend a base schema.
---

[Lesson 15](/lessons/json-schema-basics) wrote one flat schema. Real contracts repeat themselves: every service has a port, every environment has a name. Draft 2020-12 gives you ways to name a piece once and reuse it, and ways to combine pieces.

## $defs and $ref

`$defs` is a holding area for named sub-schemas. `$ref` points at one with a JSON Pointer, so `#/$defs/port` means "the `port` entry under `$defs` in this document".

```run
# title: One definition, used twice
# expect-exit: 1
cat > pair.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {
    "port": {"type": "integer", "minimum": 1, "maximum": 65535}
  },
  "type": "object",
  "properties": {
    "listen": {"$ref": "#/$defs/port"},
    "admin":  {"$ref": "#/$defs/port"}
  },
  "required": ["listen"]
}
EOF
printf 'listen: 8080\nadmin: 99999\n' > pair.yaml
schema-check pair.schema.json pair.yaml
```

The error points at `/admin`, the place in the data, not at the definition. The rule lives in one spot, so changing the maximum changes both properties.

## allOf, anyOf, oneOf, not

| Keyword | Passes when |
| --- | --- |
| `allOf` | every sub-schema passes |
| `anyOf` | at least one passes |
| `oneOf` | exactly one passes |
| `not` | the sub-schema fails |

`oneOf` is the usual source of confusion. If two branches both match, `oneOf` fails, and the message says so.

```run
# title: oneOf fails when two branches match
# expect-exit: 1
cat > source.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "oneOf": [
    {"type": "object", "required": ["url"]},
    {"type": "object", "required": ["path"]}
  ]
}
EOF
echo '{"url": "https://example.com"}'                > url.json
echo '{"url": "https://example.com", "path": "/tmp"}' > both.json
echo '{}'                                            > neither.json
schema-check source.schema.json url.json both.json neither.json
```

A document with only `url` matches the first branch and not the second, so it passes. With both keys it matches two branches, and the only message is `must match exactly one schema in oneOf`. With neither it matches none, and you also get one line per branch explaining why that branch failed (`url` missing, `path` missing) before the closing `oneOf` line. So the two failures look different: when you see only the `oneOf` line, too many branches matched, and when you see per-branch lines, none did. If you meant "at least one", write `anyOf`.

`not` inverts a sub-schema and is mostly useful for forbidding a value, for example `{"not": {"const": "root"}}` on a `user` property. Because the error can only say that the inner schema matched, prefer a positive rule such as `enum` when you can.

## if / then / else

Some rules depend on another field: a `tls` section is needed only when `scheme` is `https`. `if` is tested against the data. If it passes, `then` applies; otherwise `else` does. A failing `if` is not an error by itself.

```run
# title: A rule that applies only when scheme is https
# expect-exit: 1
cat > endpoint.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {"scheme": {"enum": ["http", "https"]}},
  "required": ["scheme"],
  "if": {"properties": {"scheme": {"const": "https"}}},
  "then": {"required": ["cert"]}
}
EOF
printf 'scheme: http\n'              > plain.yaml
printf 'scheme: https\ncert: a.pem\n' > secure.yaml
printf 'scheme: https\n'             > nocert.yaml
schema-check endpoint.schema.json plain.yaml secure.yaml nocert.yaml
```

## additionalProperties and allOf

Suppose you extend a base shape with another. It looks natural to close the result with `additionalProperties: false`.

```run
# title: additionalProperties cannot see inside allOf
# expect-exit: 1
cat > closed.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "allOf": [
    {"properties": {"name": {"type": "string"}}},
    {"properties": {"port": {"type": "integer"}}}
  ],
  "additionalProperties": false
}
EOF
cat > open.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "allOf": [
    {"properties": {"name": {"type": "string"}}},
    {"properties": {"port": {"type": "integer"}}}
  ],
  "unevaluatedProperties": false
}
EOF
printf 'name: api\nport: 80\n'            > fine.yaml
printf 'name: api\nport: 80\nextra: 1\n'  > extra.yaml
echo "--- additionalProperties"
schema-check closed.schema.json fine.yaml extra.yaml || true
echo "--- unevaluatedProperties"
schema-check open.schema.json fine.yaml extra.yaml
```

Read the first block of output carefully. `additionalProperties` sees no `properties` beside it, so every key counts as additional, and the perfectly good `fine.yaml` is rejected. `unevaluatedProperties` instead asks which keys *any* keyword in the schema has already handled, so `name` and `port` are accepted and `extra.yaml` is the only file rejected. Note that its message, `must NOT have unevaluated properties`, does not name the key the way the `additionalProperties` message does, so you have to find the extra key yourself.

The rule of thumb: use `additionalProperties: false` in a flat schema where `properties` is right beside it, and `unevaluatedProperties: false` at the top of a schema that uses `allOf`, `$ref`, or `if/then/else` to build the shape. Ajv's strict mode also asks for `"type": "object"` beside either keyword, which is why both schemas above declare it.

## Validation does not apply defaults

A schema can say `"default": 8080`. That keyword is an annotation, a hint for tools that generate forms or documentation. It does not insert anything into the data, and it does not make a missing required key valid.

```run
# title: default does not rescue a missing key
# expect-exit: 1
cat > def.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {"port": {"type": "integer", "default": 8080}},
  "required": ["port"]
}
EOF
echo '{}' > empty.json
schema-check def.schema.json empty.json
```

If your program needs a default, apply it in code after validating. Ajv has an optional `useDefaults` setting that fills them in, but `schema-check` does not enable it, and a contract that quietly rewrites its input is harder to reason about than one that only reports.

## A habit for larger schemas

Build up a schema one keyword at a time and keep a small set of files that should pass and a set that should fail. After each change, run `schema-check` against both sets. A schema you have only seen accept good data may be accepting everything, as the lesson 15 pitfall showed. Putting the failing examples in version control next to the schema is the cheapest regression test a contract can have, and [the capstone](/lessons/capstone) does exactly that.

## Pointing an editor at a schema

Editors can validate as you type. The YAML language server, used by the Red Hat YAML extension for VS Code, reads a modeline comment at the top of a YAML file:

```yaml
# yaml-language-server: $schema=./service.schema.json
name: api
port: 8080
```

That comment is an editor feature. A YAML parser treats it as a comment, so the data is unchanged and nothing validates unless the editor or a command such as `schema-check` runs.

## Exercises

```exercise
---title---
Share one definition
---prompt---
Write a schema with a `$defs` entry called `name` (a lowercase string, `^[a-z]+$`). Use it for both `first` and `last`. Validate a YAML file where only `last` is wrong, and confirm the message points at `/last`.
---hint---
Both properties become `{"$ref": "#/$defs/name"}`.
---solution---
Only `/last` is reported because the rule is evaluated separately for each place in the data that refers to it.
---script---
cat > n.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$defs": {"name": {"type": "string", "pattern": "^[a-z]+$"}},
  "type": "object",
  "properties": {
    "first": {"$ref": "#/$defs/name"},
    "last":  {"$ref": "#/$defs/name"}
  }
}
EOF
printf 'first: ada\nlast: Lovelace\n' > n.yaml
schema-check n.schema.json n.yaml || echo "(exit status $?)"
```

```exercise
---title---
anyOf or oneOf?
---prompt---
A notification needs `email` or `phone`, and having both is fine. Write the schema and test three files: email only, both, neither. Which keyword did you use, and what would `oneOf` have changed?
---hint---
Two branches that each require one key. "Both is fine" decides the keyword.
---solution---
`anyOf` passes email-only and both, and rejects neither. With `oneOf`, the "both" file would also be rejected because two branches match.
---script---
cat > notify.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "anyOf": [{"required": ["email"]}, {"required": ["phone"]}]
}
EOF
echo '{"email": "a@example.com"}' > e.json
echo '{"email": "a@example.com", "phone": "555"}' > b.json
echo '{}' > n.json
schema-check notify.schema.json e.json b.json n.json || echo "(exit status $?)"
```
