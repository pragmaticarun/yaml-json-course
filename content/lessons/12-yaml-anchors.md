---
number: 12
slug: yaml-anchors
title: Anchors, aliases, and merge keys
module: YAML
level: intermediate
minutes: 25
summary: Anchors let one YAML node be reused in several places. Learn what an alias means, what disappears when you convert to JSON, and why the merge key behaves differently depending on the YAML version.
objectives:
  - Define a node with an anchor and reuse it with an alias
  - Explain why converting to JSON turns each alias into a copy
  - Use the merge key to share defaults, and predict which value wins
  - State which parsers merge `<<` and which treat it as an ordinary key
further:
  - title: YAML 1.2.2 specification, section 3.2.2.2 (Anchors and Aliases)
    url: https://yaml.org/spec/1.2.2/#3222-anchors-and-aliases
  - title: YAML 1.1 type repository, merge
    url: https://yaml.org/type/merge.html
  - title: The yaml npm package documentation
    url: https://eemeli.org/yaml/
pitfall: |
  The merge key `<<` is not part of the YAML 1.2 specification. It comes from a type defined for YAML 1.1. Many tools support it anyway, and many do not. A file that relies on `<<` can load as a clean config in one program and as a mapping with a literal key named "<<" in another, with no error in either.
---

JSON has no way to say "this value is the same as that one". If two services share a configuration, you write it twice. YAML adds a feature for this: mark a node with an **anchor** and refer to it later with an **alias**. This lesson covers what that does, what it does not do, and the related merge key that many files rely on.

## Anchor and alias

An anchor is `&name` placed before a node. An alias is `*name`, and it stands for the anchored node.

```run
# title: Define once, use twice
cat > anchors.yaml <<'EOF'
default_port: &port 8080
web:
  port: *port
admin:
  port: *port
list: &tags [a, b]
other: *tags
EOF
yaml2json anchors.yaml | jq -c .
```

An alias can refer to a scalar or to a whole collection. The rule is that the anchor must appear earlier in the file than the alias that uses it. A name with no anchor is an error. Check it with `yaml2json` here, because it is the conversion step that resolves aliases and reports the failure:

```run
# title: An alias with no anchor
# expect-exit: 1
printf 'a: *nope\n' > bad.yaml
yaml2json bad.yaml
```

## Aliases become copies in JSON

In a YAML parser's memory, an alias can point at the *same* object as its anchor. JSON has no such notion, so on conversion every alias becomes a full, independent copy. The output above shows `"other": ["a","b"]` written out twice, once under `list` and once under `other`. The sharing is gone.

Two consequences follow:

- Converting YAML to JSON and back does **not** restore the anchors. The result is longer and has no reuse. See [Converting between formats](/lessons/converting).
- Anchors are a feature of the *file*. If your program loads the YAML and edits one copy, whether the other changes depends on how the library represents aliases. Do not count on either behaviour.

You can reuse a name. A later anchor with the same name replaces the earlier one for aliases that come after it:

```run
# title: Re-defining an anchor name
printf 'a: &x 1\nb: *x\nc: &x 2\nd: *x\n' | yaml2json | jq -c .
```

`b` got 1 and `d` got 2. It parses, but it is a confusing thing to write.

## The merge key

Copying a whole mapping is useful, but the common need is "all of these defaults, with two changes". The merge key `<<` does that: its value is a mapping (or a list of mappings) whose keys are added to the current one.

The merge key is where YAML versions diverge, so the same file is read both ways:

```run
# title: The merge key under YAML 1.2 and YAML 1.1
cat > merge.yaml <<'EOF'
base: &base
  retries: 3
  timeout: 30
svc:
  <<: *base
  timeout: 60
EOF
echo "== YAML 1.2 (default)"
yaml2json merge.yaml | jq -c .
echo "== YAML 1.1"
yaml2json --yaml-1.1 merge.yaml | jq -c .
```

Under YAML 1.1, `svc` got `retries` from `base`, and its own `timeout: 60` took priority over the merged 30. Under 1.2 (the helper's default) nothing was merged: `svc` has a key literally named `<<`, whose value is a copy of `base`. No error is reported, which is why the pitfall above matters.

So what do real tools do? Support varies between libraries and between settings of one library. When you write a file that uses `<<`, find out what the program that loads it does, and test it, as this lesson does.

## Which value wins

With a list of mappings, earlier entries take priority. An explicit key in the mapping itself beats every merged one.

```run
# title: Merge order and overrides
cat > order.yaml <<'EOF'
p: &p {k: 1, other: 1}
q: &q {k: 2, extra: 2}
first_wins: {<<: [*p, *q]}
reversed:   {<<: [*q, *p]}
explicit:   {<<: *p, k: 9}
EOF
yaml2json --yaml-1.1 order.yaml | jq -c '{first_wins, reversed, explicit}'
```

`first_wins` has `k: 1` because `p` came first in the list, and `reversed` has `k: 2` for the same reason. Both have all three of `k`, `other`, and `extra`, since the merge adds keys that are missing. `explicit` has `k: 9`: the key written in the mapping itself overrides the merged one.

The merge is **shallow**. If the merged mapping contains a nested mapping or list and you set the same top-level key, the whole value is replaced, not combined:

```run
# title: Merging is shallow
cat > shallow.yaml <<'EOF'
defaults: &d
  env: {A: 1}
  tags: [x]
over:
  <<: *d
  env: {B: 2}
EOF
yaml2json --yaml-1.1 shallow.yaml | jq -c .over
```

`over.env` is `{"B": 2}`. The `A: 1` from the defaults is gone, and `tags` was kept. If you need a deep merge, do it explicitly in code, or with `jq`'s `*` operator ([jq transforms](/lessons/jq-transform)).

## When to use them

Anchors earn their place when the same block repeats three or more times and must stay identical, such as the shared steps in a CI file or the common settings of several services. They cost readability: a reader has to scroll up to find what `*base` means, and an edit to the anchor changes every use. Two or three repeated lines are usually clearer written out. If a tool validates the file against a schema ([JSON Schema basics](/lessons/json-schema-basics)), validate the *resolved* data, because that is what the program will see.

## Exercises

```exercise
---title---
Share a block of settings
---prompt---
Write `services.yaml` with an anchored mapping `common` holding `restart: always` and `log: json`. Then define services `api` and `worker` that both merge `common`, and give `worker` its own `log: text`. Convert with `--yaml-1.1` and print the result with `jq -c`.
---hint---
Use `<<: *common` as the first line inside each service, and write `log: text` after it.
---solution---
`api` inherits both keys. `worker` inherits `restart` and overrides `log`, because an explicit key wins over a merged one.
---script---
cat > services.yaml <<'EOF'
common: &common
  restart: always
  log: json
api:
  <<: *common
  port: 80
worker:
  <<: *common
  log: text
EOF
yaml2json --yaml-1.1 services.yaml | jq -c '{api, worker}'
```

```exercise
---title---
What does your parser see?
---prompt---
Convert the file below with and without `--yaml-1.1`. Describe what the two outputs say about a tool that would load this file without merge support.
---hint---
Look at which keys `job` has in each output.
---solution---
Without merge support, `job` has only its own key and a literal `<<` key. The inherited `image` key is not on `job` itself. It sits under the `<<` key, so a program that reads `job.image` would find nothing.
---script---
cat > job.yaml <<'EOF'
defaults: &d
  image: alpine
job:
  <<: *d
  cmd: echo hi
EOF
echo "== 1.2"; yaml2json job.yaml | jq -c .job
echo "== 1.1"; yaml2json --yaml-1.1 job.yaml | jq -c .job
```
