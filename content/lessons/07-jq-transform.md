---
number: 7
slug: jq-transform
title: Reshaping JSON with jq
module: JSON
level: intermediate
minutes: 30
summary: Build new objects, summarise arrays, rewrite values, and edit a file safely. These are the jq patterns that replace most throwaway scripts.
objectives:
  - Construct new objects and arrays from an existing document
  - Summarise a list with map, add, group_by, sort_by, and reduce
  - Convert between objects and key/value lists with to_entries and from_entries
  - Update and delete values, and edit a file in place without destroying it
further:
  - title: jq manual
    url: https://jqlang.org/manual/
  - title: jq manual, reduce
    url: https://jqlang.org/manual/#reduce
pitfall: |
  jq has no in-place flag. Writing "jq ... file > file" makes the shell truncate the file before jq reads it, and jq then reads an empty input. The command still exits with status 0. Write to a temporary file and rename it over the original.
---

Lesson [jq basics](/lessons/jq-basics) used jq to read values out. This lesson uses it to produce new JSON. The same input is used throughout: four orders, each with a customer, a total, and a list of items. Every script recreates it.

## Building new values

An object construction `{a: .x, b: .y}` makes a new object from parts of the input. An array construction `[...]` collects every output of a filter into a list. `map(f)` is shorthand for `[.[] | f]`.

```run
# title: Object construction, map, and add
cat > orders.json <<'EOF'
[{"id":1,"cust":"ada","total":30,"items":["a","b"]},
 {"id":2,"cust":"bo","total":15,"items":["c"]},
 {"id":3,"cust":"ada","total":55.5,"items":[]},
 {"id":4,"cust":"cy","total":10,"items":["a"]}]
EOF
echo "--- reshape each order"
jq -c '.[] | {id, customer: .cust, n: (.items | length)}' orders.json
echo "--- sum of totals";   jq 'map(.total) | add' orders.json
echo "--- ids over 12";     jq -c 'map(select(.total > 12)) | map(.id)' orders.json
echo "--- all items";       jq -c '[.[] | .items[]]' orders.json
echo "--- text";            jq -r '.[] | "\(.id): \(.cust) owes \(.total)"' orders.json
```

`{id}` is shorthand for `{id: .id}`. The expression `"\(...)"` is string interpolation, handy with `-r` for readable lines.

## Grouping and summing

`group_by(.key)` sorts an array and splits it into runs that share a key. Each group is an array, so you can summarise it with another `map`. `sort_by` accepts several keys, and a negative sign reverses a number.

```run
# title: group_by, sort_by, and reduce
cat > orders.json <<'EOF'
[{"id":1,"cust":"ada","total":30},{"id":2,"cust":"bo","total":15},
 {"id":3,"cust":"ada","total":55.5},{"id":4,"cust":"cy","total":10}]
EOF
echo "--- per customer"
jq -c 'group_by(.cust) | map({cust: .[0].cust, orders: length, sum: (map(.total) | add)})' orders.json
echo "--- same totals with reduce"
jq -c 'reduce .[] as $o ({}; .[$o.cust] += $o.total)' orders.json
echo "--- biggest first"
jq -c 'sort_by(-.total) | map(.id)' orders.json
echo "--- add on one-key objects does NOT sum"
jq -c 'map({(.cust): .total}) | add' orders.json
```

`reduce SOURCE as $x (START; UPDATE)` folds a stream into one value. Here the start is `{}`, and `.[$o.cust] += $o.total` adds each order's total into the entry for its customer, creating it when it is missing.

Look at the last result. Using `add` on one-key objects *merges* them, so the later `ada` entry replaced the earlier one: `55.5` instead of `85.5`. `add` sums numbers and concatenates arrays, but on objects it merges. When you need a sum per key, use `group_by` or `reduce`.

## Objects as lists of entries

`to_entries` turns an object into `[{"key": ..., "value": ...}, ...]`, which you can filter and sort like any array. `from_entries` turns it back. `with_entries(f)` does the round trip for you, and `map_values(f)` changes every value.

```run
# title: to_entries, from_entries, with_entries
echo '{"a": 1, "b": 2}' > kv.json
echo "--- to_entries";    jq -c 'to_entries' kv.json
echo "--- filter by value"; jq -c 'to_entries | map(select(.value > 1)) | from_entries' kv.json
echo "--- with_entries";  jq -c 'with_entries(.value += 10)' kv.json
echo "--- map_values";    jq -c 'map_values(. * 2)' kv.json
```

Reach for `to_entries` whenever you need to filter an object by its keys or values. Most jq reports over a dictionary, such as "keys that start with `x_`", are one `to_entries | map(select(...)) | from_entries` away.

## Updates and deletes

`.path = value` sets a path. `.path |= f` applies a filter to the current value at that path. `del(.path)` removes one. Updates operate on a copy and print the result, since jq never modifies its input file.

```run
# title: Update with |=, set with =, delete with del
echo '[{"id":1,"total":30,"items":["a"]},{"id":2,"total":15,"items":[]}]' > orders.json
echo "--- double every total"; jq -c 'map(.total |= . * 2) | map(.total)' orders.json
echo "--- add a field";        jq -c '.[0].tags = ["x"] | .[0]' orders.json
echo "--- drop a field";       jq -c 'map(del(.items))' orders.json
```

## Slurping

By default jq runs the filter once per top-level value in its input. With `-s` (`--slurp`) it first collects every value into one array and runs the filter once. That turns a file of separate documents into something you can sum or sort (lesson [JSON Lines](/lessons/json-lines) builds on this).

```run
# title: --slurp
printf '{"n":1}\n{"n":2}\n{"n":3}\n' > lines.json
echo "--- without -s, once per value"; jq -c '.n' lines.json
echo "--- with -s, once overall";     jq -c -s '{count: length, sum: (map(.n) | add)}' lines.json
```

## Editing a file safely

Because the shell opens the output file before jq starts, redirecting onto the input is a mistake. The next script shows the failure, then the correct pattern.

```run
# title: The truncation trap and the safe edit
echo '{"name":"app","port":80}' > cfg.json
echo "--- the wrong way"
cp cfg.json wrong.json
jq '.port = 8080' wrong.json > wrong.json
echo "jq exit status: $?"
echo "wrong.json is now $(wc -c < wrong.json) bytes"
echo "--- the right way"
jq '.port = 8080' cfg.json > cfg.json.tmp && mv cfg.json.tmp cfg.json
cat cfg.json
```

The wrong version left a zero-byte file and no error. The safe version writes the new content beside the original and replaces it in one `mv`, which is atomic when both names are in the same directory. If jq fails, the `&&` stops before `mv`, and the original stays intact.

## Exercises

```exercise
---title---
Order count per customer
---prompt---
From `[{"cust":"ada"},{"cust":"bo"},{"cust":"ada"}]`, produce the single object `{"ada": 2, "bo": 1}`.
---hint---
Group by the customer, then build a one-key object per group. Because the keys are different after grouping, `add` merges them correctly.
---solution---
After `group_by(.cust)` each group has one customer, so the one-key objects `{ada: 2}` and `{bo: 1}` have different keys and `add` combines them into one object.
---script---
echo '[{"cust":"ada"},{"cust":"bo"},{"cust":"ada"}]' > c.json
jq -c 'group_by(.cust) | map({(.[0].cust): length}) | add' c.json
```

```exercise
---title---
Keep only the string settings
---prompt---
For `{"name":"app","port":80,"env":"prod","debug":false}`, print an object containing only the entries whose value is a string.
---hint---
`to_entries`, `select(.value | type == "string")`, then `from_entries`.
---solution---
The filter keeps the `name` and `env` entries and rebuilds an object from them.
---script---
echo '{"name":"app","port":80,"env":"prod","debug":false}' > s.json
jq -c 'to_entries | map(select(.value | type == "string")) | from_entries' s.json
```

```exercise
---title---
Bump a version in place
---prompt---
`package.json` contains `{"name":"app","version":"1.0.0"}`. Change the version to `1.0.1` in the same file, without losing the file if jq fails.
---hint---
Write to a temporary file and use `&&` before `mv`.
---solution---
Write the updated document to `package.json.tmp` and only rename it over the original if jq succeeded.
---script---
echo '{"name":"app","version":"1.0.0"}' > package.json
jq '.version = "1.0.1"' package.json > package.json.tmp && mv package.json.tmp package.json
cat package.json
```
