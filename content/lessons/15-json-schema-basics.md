---
number: 15
slug: json-schema-basics
title: JSON Schema, the basics
module: Contracts and conversion
level: intermediate
minutes: 30
summary: A schema is a JSON document that says what other documents must look like. Write one, run it, and learn to read the errors.
objectives:
  - Write a draft 2020-12 schema using type, properties, required, and additionalProperties
  - Constrain values with enum, const, minimum, maximum, minLength, pattern, items, and minItems
  - Read schema-check output, including which part of the data each message points at
  - Validate a YAML file against a schema written in JSON
further:
  - title: JSON Schema draft 2020-12
    url: https://json-schema.org/draft/2020-12
  - title: Understanding JSON Schema
    url: https://json-schema.org/understanding-json-schema/
  - title: Ajv documentation
    url: https://ajv.js.org/
pitfall: |
  Unless a schema says `required`, a property may be missing. Unless it says `additionalProperties: false`, unknown properties are accepted. A schema that lists only `properties` therefore accepts `{}` and also `{"prot": 80}`, a misspelt port. Most "the schema passed but the config is wrong" reports are one of these two omissions.
---

A parser answers one question: is this text well-formed? It cannot tell you that `port` should be a number between 1 and 65535, or that `environment` must be one of three names. **JSON Schema** answers that second question. A schema is itself a JSON document. A validator reads the schema and a data document and reports every place where the data breaks the rules.

Schemas apply to the tree from [the first lesson](/lessons/one-data-model), not to the text. That is why a JSON Schema can validate a YAML file: parse the YAML into a tree, then validate the tree.

## A first schema

The course helper `schema-check` uses Ajv, which implements draft 2020-12 and asserts `format` keywords through the `ajv-formats` plugin. It prints one line per problem and exits 0 only when every file is valid.

```run
# title: A schema for a small service description
cat > service.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "name": {"type": "string", "minLength": 1},
    "port": {"type": "integer", "minimum": 1, "maximum": 65535},
    "env":  {"enum": ["dev", "staging", "prod"]}
  },
  "required": ["name", "port"],
  "additionalProperties": false
}
EOF
cat > good.json <<'EOF'
{"name": "api", "port": 8080, "env": "prod"}
EOF
schema-check service.schema.json good.json
echo "exit status: $?"
```

Every keyword is a small test, and a document must pass all of them. `type` checks the kind of value. `properties` attaches a sub-schema to each named key. `required` lists keys that must be present. `additionalProperties: false` rejects any key not named in `properties`. `enum` lists the allowed values.

## Reading the errors

With `allErrors` turned on, the validator reports every failure rather than stopping at the first. Each line is `file`, then a JSON Pointer to the offending part of the data, then the message. `(root)` means the whole document, and `/port` means the `port` key.

```run
# title: One bad document, several messages
# expect-exit: 1
cat > service.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "name": {"type": "string", "minLength": 1},
    "port": {"type": "integer", "minimum": 1, "maximum": 65535},
    "env":  {"enum": ["dev", "staging", "prod"]}
  },
  "required": ["name", "port"],
  "additionalProperties": false
}
EOF
cat > bad.json <<'EOF'
{"port": 70000, "env": "production", "colour": "blue"}
EOF
schema-check service.schema.json bad.json
```

Four problems, four lines. The message for `additionalProperties` names the offending key, and the message for `enum` lists the allowed values. A pointer such as `/items/2/qty` means "key `items`, element 2, key `qty`", counting from zero.

## Validating YAML

The tree is what gets validated, so the data file can be YAML. `schema-check` parses files ending in `.yaml` or `.yml` as YAML 1.2 first. The same schema file serves both formats.

```run
# title: The same schema, a YAML document
# expect-exit: 1
cat > service.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "name": {"type": "string"},
    "port": {"type": "integer"}
  },
  "required": ["name", "port"],
  "additionalProperties": false
}
EOF
cat > svc.yaml <<'EOF'
name: api
port: "8080"
EOF
schema-check service.schema.json svc.yaml
```

The string `"8080"` is not an integer, even though it looks like one. Quoting made it a string in the tree, and the schema checks the tree. Under YAML's own rules the unquoted `port: 8080` would have been a number.

## More constraints

Strings, numbers, and arrays each have their own keywords:

| Keyword | Applies to | Meaning |
| --- | --- | --- |
| `minLength`, `maxLength` | string | Length in characters |
| `pattern` | string | A regular expression that may match anywhere in the string unless anchored with `^` and `$` |
| `minimum`, `maximum` | number | Inclusive bounds. `exclusiveMinimum` and `exclusiveMaximum` are strict |
| `multipleOf` | number | The value must be a whole multiple |
| `items` | array | A schema every element must satisfy |
| `minItems`, `maxItems`, `uniqueItems` | array | Size and uniqueness |
| `const` | any | Exactly one allowed value |
| `format` | string | Named shapes such as `email`, `uri`, `date`, `uuid` |

```run
# title: Arrays, patterns, and formats
# expect-exit: 1
cat > team.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "version": {"const": 1},
    "slug":    {"type": "string", "pattern": "^[a-z][a-z0-9-]*$"},
    "contact": {"type": "string", "format": "email"},
    "members": {"type": "array", "items": {"type": "string"}, "minItems": 2, "uniqueItems": true}
  },
  "required": ["version", "slug", "members"]
}
EOF
cat > team.yaml <<'EOF'
version: 2
slug: Platform Team
contact: not-an-email
members: [ada]
EOF
schema-check team.schema.json team.yaml
```

Without `ajv-formats`, many validators treat `format` as a comment and accept anything. Draft 2020-12 allows that, so a schema that relies on `format` is only as strict as the validator running it. Check yours with a deliberately bad value, as above.

## What a schema cannot do

A schema checks the shape of one document. It cannot check that a `port` is free on the host, that two services do not share a name unless you write `uniqueItems` for that, or that a referenced file exists. It also does not *fix* anything: validation never fills in defaults or converts types. Lesson 16 returns to that.

## Exercises

```exercise
---title---
Close the typo hole
---prompt---
This schema accepts `{"prot": 80}`. Change it, without removing any property, so that a document must contain `port` and cannot contain any key the schema does not list. Show one document it accepts and one it rejects.
---hint---
Two keywords are missing from the schema: one forces a key to be present and one forbids unknown keys.
---solution---
Add `"required": ["port"]` and `"additionalProperties": false`. The typo `prot` is then reported twice: `port` is missing and `prot` is not allowed.
---script---
cat > s.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {"port": {"type": "integer"}},
  "required": ["port"],
  "additionalProperties": false
}
EOF
echo '{"port": 80}' > ok.json
echo '{"prot": 80}' > typo.json
schema-check s.json ok.json typo.json || echo "(exit status $?)"
```

```exercise
---title---
Pick the right keyword
---prompt---
Write a schema for a YAML file with `level` (one of `debug`, `info`, `warn`, `error`) and `retries` (a whole number from 0 to 5). Check it against a file with `level: trace` and `retries: 9`. Predict how many messages you will see.
---hint---
`enum` for the level, `type: integer` with `minimum` and `maximum` for the retries.
---solution---
Two messages: one for `/level` listing the allowed values, one for `/retries` saying it must be at most 5.
---script---
cat > log.schema.json <<'EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "level": {"enum": ["debug", "info", "warn", "error"]},
    "retries": {"type": "integer", "minimum": 0, "maximum": 5}
  }
}
EOF
printf 'level: trace\nretries: 9\n' > log.yaml
schema-check log.schema.json log.yaml || echo "(exit status $?)"
```
