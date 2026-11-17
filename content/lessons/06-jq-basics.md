---
number: 6
slug: jq-basics
title: jq basics
module: JSON
level: intermediate
minutes: 30
summary: jq is a small language for taking JSON apart. Learn paths, the iterator, pipes, select, and the options that make it usable in shell scripts.
objectives:
  - Read a value with a path and iterate over an array with .[]
  - Combine filters with the pipe and keep matches with select
  - Handle missing fields with //, the ? operator, and the -e exit status
  - Pass shell values into a filter safely with --arg and --argjson
further:
  - title: jq manual
    url: https://jqlang.org/manual/
  - title: jq manual, basic filters
    url: https://jqlang.org/manual/#basic-filters
pitfall: |
  A jq filter is not a shell string. Never splice a shell variable into the filter text, as in "select(.name==\"$name\")". A quote in the value breaks the filter, or changes what it does. Pass values with --arg, which hands them over as data.
---

`jq` reads JSON, runs a **filter** over it, and prints the result. Every filter takes one input and produces zero or more outputs. Everything in jq, from selecting a field to building a report, is a filter combined with other filters.

The installed jq here is **1.6**. The examples were run on it, and the manual at jqlang.org covers newer versions too, so check `jq --version` when a feature from the manual is missing.

All the examples in this lesson use the same input, a small team description. Each script recreates it first.

## Paths and the iterator

A dot is the identity filter, and it prints its input, pretty-printed. `.team` reads a field. `.members[0]` reads an array element, and `.members[]` produces **every** element, one output each.

```run
# title: Fields, elements, and the iterator
cat > people.json <<'EOF'
{"team":"core","members":[
 {"name":"Ada","role":"lead","langs":["c","python"],"active":true},
 {"name":"Bo","role":"dev","langs":["go"],"active":false},
 {"name":"Cy","role":"dev","langs":[],"active":true,"email":"cy@example.com"}
]}
EOF
echo "--- .team";                 jq '.team' people.json
echo "--- .team with -r";         jq -r '.team' people.json
echo "--- .members[0].name";      jq '.members[0].name' people.json
echo "--- .members[].name";       jq '.members[].name' people.json
echo "--- slice [1:], -c";        jq -c '.members[1:] | map(.name)' people.json
echo "--- last element, -c";      jq -c '.members[-1]' people.json
```

`-r` is **raw output**. Without it strings print with their JSON quotes (`"core"`), and with it they print as plain text (`core`), which is what you want to pass to another command. `-c` is **compact output**: one line per result instead of the indented layout. `.members[1:]` is a slice, like Python's, and a negative index counts from the end.

## Pipes and select

The pipe `|` sends each output of the left filter into the right filter. `.members[] | .name` is the same as `.members[].name`. The filter `select(condition)` passes its input through when the condition is true and produces nothing when it is false, so it works as a filter on a stream.

```run
# title: Filtering with select
cat > people.json <<'EOF'
{"team":"core","members":[
 {"name":"Ada","role":"lead","langs":["c","python"],"active":true},
 {"name":"Bo","role":"dev","langs":["go"],"active":false},
 {"name":"Cy","role":"dev","langs":[],"active":true,"email":"cy@example.com"}
]}
EOF
echo "--- active members";  jq -c '.members[] | select(.active) | .name' people.json
echo "--- active devs";     jq -c '.members[] | select(.role == "dev" and .active) | {name}' people.json
echo "--- sizes";           jq -c 'keys, (.members | length), (.members[0] | keys)' people.json
```

`{name}` is shorthand for `{name: .name}`. `keys` returns an object's keys in **sorted** order, not file order. `length` of an array is its element count.

## Missing fields and errors

Asking an object for a key it lacks gives `null`, not an error. Asking the wrong *kind* of value for a key or index, such as indexing a number, is an error. The `//` operator supplies a default, and `?` suppresses an error.

```run
# title: Missing fields, defaults, and errors
cat > people.json <<'EOF'
[{"name":"Ada"},{"name":"Cy","email":"cy@example.com"}]
EOF
echo "--- .email on each";     jq -c '.[].email' people.json
echo "--- with a default";     jq -c '.[] | .email // "none"' people.json
echo '{"a":1}' > num.json
echo "--- indexing a number";  jq '.a[0]' num.json 2>&1 || echo "(exit status $?)"
echo "--- with ?";             jq '.a[0]?' num.json; echo "(exit status $?)"
```

The first command shows `null` for the entry with no email. The default operator replaced it with `"none"`. Indexing the number `1` with `[0]` is an error: jq prints `jq: error ... Cannot index number with number` and exits with status 5. Adding `?` swallows the error. The filter produces no output at all and the exit status is 0, which is convenient, but it also hides real mistakes, so use it deliberately.

## Exit status for scripts

By default jq's exit status says whether it could run, not what it found. With `-e` (`--exit-status`), jq exits with 1 when the last output was `false` or `null`, and with 4 when there was no output at all. That lets an `if` in a shell script test the data.

```run
# title: Using jq -e in a shell condition
cat > people.json <<'EOF'
[{"name":"Ada","active":true},{"name":"Bo","active":false}]
EOF
if jq -e '.[] | select(.name == "Zed")' people.json > /dev/null; then
  echo "Zed found"
else
  echo "Zed not found (jq exit status $?)"
fi
jq -r '.[] | [.name, (.active | tostring)] | @tsv' people.json
```

`@tsv` and `@csv` format an array as a tab- or comma-separated row. They are the safe way to print columns, because they quote and escape the values, unlike `echo "$a,$b"`.

## Passing values in

`--arg name value` binds `$name` to a **string**. `--argjson name json` binds it to a parsed JSON value, so numbers stay numbers. Neither needs any quoting inside the filter.

```run
# title: --arg and --argjson
cat > people.json <<'EOF'
[{"name":"Ada","role":"lead","age":36},{"name":"Bo","role":"dev","age":29}]
EOF
role=dev
jq -r --arg r "$role" '.[] | select(.role == $r) | .name' people.json
jq -c --argjson min 30 '.[] | select(.age >= $min) | .name' people.json
jq -n -c --arg n 3 '$n | tonumber + 1'
```

The `-n` flag runs the filter with no input, which is useful when you only want to build a value. `--arg n 3` creates the string `"3"`, so the last line converts it before doing arithmetic.

## Exercises

```exercise
---title---
Names of the dev-role members
---prompt---
Given `people.json` with a `members` array like the one in this lesson, print the names of members whose `role` is `dev`, one per line and without quotes.
---hint---
Combine the iterator, `select`, and `-r`.
---solution---
`.members[]` produces each member, `select(.role == "dev")` keeps the developers, and `.name` with `-r` prints the string without quotes.
---script---
cat > people.json <<'EOF'
{"members":[{"name":"Ada","role":"lead"},{"name":"Bo","role":"dev"},{"name":"Cy","role":"dev"}]}
EOF
jq -r '.members[] | select(.role == "dev") | .name' people.json
```

```exercise
---title---
Default for a missing field
---prompt---
For `[{"name":"Ada"},{"name":"Bo","nick":"bo"}]`, print each person's nickname, using their name when there is no `nick`.
---hint---
Use `//` to give `.nick` a fallback, and `-r` to print plain text.
---solution---
`.nick // .name` gives the nickname when it exists and is neither null nor false, and the name otherwise.
---script---
echo '[{"name":"Ada"},{"name":"Bo","nick":"bo"}]' > nicks.json
jq -r '.[] | .nick // .name' nicks.json
```

```exercise
---title---
Pass a variable safely
---prompt---
The shell variable `who` is set to `Ada`. Find the person with that name in `[{"name":"Ada","age":36},{"name":"Bo","age":29}]` and print their age. Do not put `$who` inside the filter text.
---hint---
Use `--arg` and refer to it as `$name` inside the filter.
---solution---
`--arg name "$who"` passes the value in as data. The filter compares `.name == $name` and the shell never touches the filter text.
---script---
who=Ada
echo '[{"name":"Ada","age":36},{"name":"Bo","age":29}]' > ages.json
jq --arg name "$who" '.[] | select(.name == $name) | .age' ages.json
```
