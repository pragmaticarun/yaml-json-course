---
number: 8
slug: json-lines
title: JSON Lines for logs and streams
module: JSON
level: intermediate
minutes: 25
summary: One JSON value per line turns a log or an export into something you can stream, grep, and append to. Learn the format, the jq and Python patterns for it, and what each tool does when one line is bad.
objectives:
  - Describe the JSON Lines format and why it suits logs and large exports
  - Filter and summarise a .jsonl file with jq, with and without --slurp
  - Read a .jsonl file line by line in Python and node, reporting the line number of a bad record
  - Predict how each tool behaves when one line in the middle is not valid JSON
further:
  - title: JSON Lines
    url: https://jsonlines.org/
  - title: jq manual, command line options (--slurp, --raw-input)
    url: https://jqlang.org/manual/
  - title: Python json module, json.loads
    url: https://docs.python.org/3/library/json.html#json.loads
pitfall: |
  A .jsonl file is not a JSON document. Parsing the whole file with a JSON parser fails after the first line. Tools such as jq that read a stream of values stop at the first line that is not valid, so one corrupt record can hide everything after it. Decide up front whether a bad line is skipped, reported, or fatal.
---

A normal JSON file holds one value, so a parser has to read the whole file before it can give you anything. A log with a million events as a single JSON array is awkward: you cannot append to it without rewriting the closing bracket, and you cannot read the first record until the last byte arrives.

**JSON Lines** (also called NDJSON, newline-delimited JSON) fixes that with one rule: each line is a complete JSON value, usually an object, and lines are separated by `\n`. Because a compact JSON value never contains a raw newline (lesson [Strings, escapes, and Unicode](/lessons/json-strings)), splitting on newlines is always safe. Appending a record is appending a line. `head`, `tail`, `grep`, and `wc -l` all work on it.

## Reading a stream with jq

jq already treats its input as a stream of values. A filter runs once for each one, and `-c` prints each result on its own line, so the output is JSON Lines again.

```run
# title: Filtering a .jsonl file
cat > log.jsonl <<'EOF'
{"t":1,"lvl":"info","msg":"start"}
{"t":2,"lvl":"error","msg":"boom"}
{"t":3,"lvl":"info","msg":"end"}
EOF
echo "--- one line per record, errors only"
jq -c 'select(.lvl == "error")' log.jsonl
echo "--- a column of messages"
jq -r '.msg' log.jsonl
echo "--- collect everything with -s"
jq -s -c '{records: length, levels: (map(.lvl) | unique)}' log.jsonl
echo "--- shell tools still work"
grep -c error log.jsonl
wc -l < log.jsonl
```

With `-s` (slurp), jq reads every record into one array first. That gives you `length`, `group_by`, and `add`, at the price of holding the whole file in memory. Without it, jq handles one record at a time, so memory stays flat on a very large file.

Pretty-printed objects are still valid input to jq, because it does not care about line boundaries. The format is a convention for *writers* and for line-based tools. A file written with an indented `jq .` is not JSON Lines, even though jq can read it.

## A bad line in the middle

Real logs contain truncated writes, stack traces, and stray text. Here is a file whose third line is not JSON.

```run
# title: jq meets a bad line
cat > log.jsonl <<'EOF'
{"t":1,"lvl":"info","msg":"start"}
{"t":2,"lvl":"error","msg":"boom"}
not json
{"t":4,"lvl":"info","msg":"end"}
EOF
jq -c . log.jsonl 2> err.txt || echo "(jq exit status $?)"
echo "--- stderr"
cat err.txt
echo "--- slurp"
jq -s -c . log.jsonl 2> err2.txt || echo "(jq exit status $?)"
cat err2.txt
```

Read the output carefully. jq printed the first two records, reported a parse error that names line 3, exited with status 4, and **never printed the fourth record**. The parser cannot resynchronise after a syntax error in a stream, so everything after the bad line is lost. With `-s` it is worse: no records at all are printed, because the array is never completed.

If you cannot guarantee clean input, read the file as plain text with `-R` (`--raw-input`) and decode each line yourself with `fromjson`. Wrapping it in `try` lets you decide what happens to a failure.

```run
# title: Skipping or reporting bad lines in jq
cat > log.jsonl <<'EOF'
{"t":1,"lvl":"info","msg":"start"}
{"t":2,"lvl":"error","msg":"boom"}
not json
{"t":4,"lvl":"info","msg":"end"}
EOF
echo "--- skip bad lines"
jq -R -c 'fromjson? | .msg' log.jsonl
echo "--- report bad lines in the output"
jq -R -c 'try fromjson catch "bad: \(.)"' log.jsonl
```

The first command drops line 3 and carries on, so all three valid records produce output. The second keeps a marker for the bad line in the output stream, which is easier to audit. Both read all four lines, unlike the plain version.

## The same job in Python and node

In a general-purpose language you control the loop, so you can number the lines and decide for each failure. Python's file object yields one line at a time, which keeps memory low.

```run
# title: Line-by-line parsing in Python
cat > log.jsonl <<'EOF'
{"t":1,"lvl":"info","msg":"start"}
{"t":2,"lvl":"error","msg":"boom"}
not json
{"t":4,"lvl":"info","msg":"end"}
EOF
python3 - <<'EOF'
import json

with open("log.jsonl") as handle:
    for number, line in enumerate(handle, start=1):
        line = line.strip()
        if not line:
            continue
        try:
            record = json.loads(line)
        except json.JSONDecodeError as err:
            print(f"line {number}: skipped ({err})")
            continue
        print(f"line {number}: {record['lvl']}")
EOF
```

Python reports the failure on line 3 and goes on to line 4. The same loop works in node when you split the text on newlines and call `JSON.parse` in a `try`. The next script also shows what happens if you hand the whole `.jsonl` file to a JSON parser as if it were one document.

```run
# title: Treating a .jsonl file as one document
cat > two.jsonl <<'EOF'
{"a":1}
{"a":2}
EOF
echo "python:"
python3 -c 'import json; json.load(open("two.jsonl"))' 2>&1 | tail -1 || true
echo "node:"
node -e 'JSON.parse(require("fs").readFileSync("two.jsonl","utf8"))' 2>&1 | grep -m1 SyntaxError || true
echo "split and parse in node:"
node -e '
const lines = require("fs").readFileSync("two.jsonl", "utf8").split("\n").filter(Boolean);
console.log(lines.map((line) => JSON.parse(line).a));
'
```

Both parsers read the first record and then fail on what follows it, with a message about extra data. This is the usual first symptom when a service is pointed at a `.jsonl` file and expects a JSON document.

## Writing JSON Lines

Writers must emit compact JSON and end every record with a newline, including the last. A file whose final line lacks the newline works in most readers, but `wc -l` will then count one fewer record than there are. Use `jq -c` or `json.dumps` with its default separators, and never pretty-print.

## Exercises

```exercise
---title---
Count errors per level
---prompt---
For a file of log records, each with a `lvl` field, print how many records there are per level, as a single object. Use the sample below.

`{"lvl":"info"}`, `{"lvl":"error"}`, `{"lvl":"info"}`, `{"lvl":"warn"}`, one per line.
---hint---
Slurp, group by `lvl`, then build a one-key object per group and `add` them.
---solution---
`-s` turns the lines into an array, `group_by(.lvl)` splits it, and each group becomes `{level: count}`. The keys are all different, so `add` merges the objects into one.
---script---
printf '{"lvl":"info"}\n{"lvl":"error"}\n{"lvl":"info"}\n{"lvl":"warn"}\n' > l.jsonl
jq -s -c 'group_by(.lvl) | map({(.[0].lvl): length}) | add' l.jsonl
```

```exercise
---title---
Convert an array to JSON Lines
---prompt---
Turn the array `[{"id":1},{"id":2},{"id":3}]` into three lines of compact JSON, and then back into an array.
---hint---
`.[]` with `-c` for the first direction, and `-s` for the second.
---solution---
`jq -c '.[]'` prints each element on its own line. Slurping those lines with `jq -s -c .` rebuilds the array.
---script---
echo '[{"id":1},{"id":2},{"id":3}]' > a.json
jq -c '.[]' a.json > a.jsonl
cat a.jsonl
jq -s -c . a.jsonl
```

```exercise
---title---
Find the bad line number
---prompt---
Write a Python or jq command that prints the number of every line in a file that is not valid JSON. Test it on a file whose second line is `oops`.
---hint---
In jq, `-R` reads lines as strings, and `input_line_number` gives the current line. In Python, use `enumerate` and `try`.
---solution---
The Python loop below prints the number for each line that raises `JSONDecodeError`. It does not stop at the first one.
---script---
printf '{"a":1}\noops\n{"a":3}\n' > check.jsonl
python3 - <<'EOF'
import json
for number, line in enumerate(open("check.jsonl"), start=1):
    try:
        json.loads(line)
    except json.JSONDecodeError:
        print("bad line:", number)
EOF
```
