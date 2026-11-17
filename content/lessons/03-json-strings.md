---
number: 3
slug: json-strings
title: Strings, escapes, and Unicode
module: JSON
level: beginner
minutes: 25
summary: A JSON string is a quoted run of Unicode characters with a short list of escapes. The surprises are in how languages count its length and what they do with bytes that are not valid text.
objectives:
  - Write the JSON escapes and decode a \uXXXX escape, including a surrogate pair
  - Explain why a control character must be escaped inside a string
  - Predict why one string has a different length in Python and in JavaScript
  - Recognise a byte order mark and invalid UTF-8 and know which tools tolerate them
further:
  - title: RFC 8259, section 7 (Strings) and section 8.1 (Character Encoding)
    url: https://www.rfc-editor.org/rfc/rfc8259#section-7
  - title: Python json module, character encodings and ensure_ascii
    url: https://docs.python.org/3/library/json.html#character-encodings
  - title: jq manual, command line options (--ascii-output)
    url: https://jqlang.org/manual/
pitfall: |
  "Length of a string" has three answers: bytes, code points, and UTF-16 code units. JSON does not pick one. Python counts code points and JavaScript counts UTF-16 units, so the same emoji gives different lengths in each. Never use a length check in one language to guarantee a limit enforced in another.
---

A JSON string starts and ends with a double quote. Between the quotes can be any Unicode character except the double quote, the backslash, and the control characters U+0000 through U+001F. Those must be written as escapes.

## The escapes

| Written | Meaning |
| --- | --- |
| `\"` | double quote |
| `\\` | backslash |
| `\/` | forward slash (allowed, never required) |
| `\b` `\f` `\n` `\r` `\t` | backspace, form feed, line feed, carriage return, tab |
| `\uXXXX` | the UTF-16 code unit with that four-digit hex value |

No other backslash sequence is legal. In particular there is no `\x41`, no `\'`, and no way to break a string over two lines.

The script below stores one string that uses most of them, then reads it three ways. `jq -r` prints the raw string without JSON quoting. `jq -c` prints it as JSON again. `jq -a` prints JSON with every non-ASCII character escaped.

```run
# title: One string, three views
printf '{"e":"caf\\u00e9 \\ud83d\\ude00 \\n tab\\t q\\" s\\\\ sl\\/"}\n' > s.json
echo "--- the file"; cat s.json
echo "--- jq -r (the decoded text)"; jq -r .e s.json
echo "--- jq -c (JSON again)"; jq -c . s.json
echo "--- jq -a (ASCII only)"; jq -a -c . s.json
```

Compare the file with the `jq -c` line. The escape `\u00e9` turned into the real character `é`, and the pair `\ud83d\ude00` became a single emoji. The optional `\/` became a plain `/`. Writing the escapes and writing the characters are two spellings of the same string.

## Surrogate pairs

`\uXXXX` names a UTF-16 code unit, which is 16 bits. Characters above U+FFFF, such as most emoji, do not fit, so JSON writes them as two escapes: a high surrogate (`\ud83d`) followed by a low surrogate (`\ude00`). Together they mean U+1F600. A decoder must combine them. A lone surrogate is not a character at all.

That history explains a famous inconsistency. Each example runs in its own empty directory, so this script recreates the same file first. It then measures the string in Python and in node.

```run
# title: The same string, two lengths
printf '{"e":"caf\\u00e9 \\ud83d\\ude00 \\n tab\\t q\\" s\\\\ sl\\/"}\n' > s.json
python3 - <<'EOF'
import json
text = json.load(open("s.json"))["e"]
print("python len:", len(text))
EOF
node -e '
const text = JSON.parse(require("fs").readFileSync("s.json", "utf8")).e;
console.log("node .length:", text.length);
console.log("node code points:", [...text].length);
'
```

Python counts code points, so the emoji is one. JavaScript's `.length` counts UTF-16 units, so the emoji is two. Spreading the string into an array walks code points, which brings node back to Python's answer. A length limit written in one language and checked in the other is a bug waiting for its first emoji.

## ensure_ascii

When Python writes JSON, `json.dumps` escapes every non-ASCII character by default (`ensure_ascii=True`). That keeps the output pure ASCII, which is safe over any channel, but it makes the text hard to read and larger. Pass `ensure_ascii=False` to write real UTF-8.

```run
# title: Python's ensure_ascii switch
printf '{"e":"caf\\u00e9 \\ud83d\\ude00 \\n tab\\t q\\" s\\\\ sl\\/"}\n' > s.json
python3 - <<'EOF'
import json
data = json.load(open("s.json"))
print(json.dumps(data))
print(json.dumps(data, ensure_ascii=False))
EOF
```

Both lines decode to the same string. jq goes the other way: it writes UTF-8 by default and escapes only when you pass `-a`, as the first example showed.

## Control characters must be escaped

A literal tab or newline inside a string is not allowed. The next script writes a document with a real tab character in the string and asks each parser what it thinks.

```run
# title: A literal tab inside a string
printf '{"a":"x\ty"}\n' > ctl.json
jq -c . ctl.json 2>&1 | head -1 || true
node -e 'try{JSON.parse(require("fs").readFileSync("ctl.json","utf8"))}catch(e){console.log("node:",e.message)}'
python3 - <<'EOF'
import json
try:
    json.load(open("ctl.json"))
except Exception as err:
    print("python:", err)
print("python, strict=False:", json.loads(open("ctl.json").read(), strict=False))
EOF
```

All three refuse by default. Python's `strict=False` switch lets control characters through. It exists for convenience with sloppy producers, and using it means your parser accepts text that other parsers will reject.

## Encoding: UTF-8, no byte order mark

RFC 8259 says JSON exchanged between systems must be UTF-8. It also says implementations must not add a byte order mark (BOM, the bytes `EF BB BF`) and may choose to ignore one. Two real-world problems follow: files saved by some Windows editors start with a BOM, and files that are not UTF-8 at all sneak in.

```run
# title: A BOM and an invalid byte
printf '\xef\xbb\xbf{"a":1}' > bom.json
printf '{"a":"\xff"}' > bad8.json
echo "--- BOM"
jq -c . bom.json
python3 -c 'import json; print(json.load(open("bom.json")))' 2>&1 | tail -1 || true
node -e 'try{JSON.parse(require("fs").readFileSync("bom.json","utf8"))}catch(e){console.log("node:",e.name)}'
echo "--- byte 0xFF inside a string"
jq -c . bad8.json
python3 -c 'import json; print(json.load(open("bad8.json")))' 2>&1 | tail -1 || true
```

The results split. The installed jq 1.6 accepts the BOM. Python and node both refuse it, and Python's message tells you to open the file as `utf-8-sig`. For the invalid byte, Python raises a decode error, while jq 1.6 prints a replacement character (`�`, U+FFFD) and carries on. Silent replacement loses data, so a pipeline that must not alter its input should decode strictly.

A lone surrogate is another gap in the specification: `"\ud83d"` is grammatically fine, but it is not a valid Unicode string. Python and JavaScript both load it, while jq 1.6 rejects it with a parse error about a bad surrogate pair escape. Do not rely on any behaviour for that input.

## Exercises

```exercise
---title---
Decode an escape by hand
---prompt---
Without running anything, what character does `"\u00e9"` stand for, and what two escapes would you write for U+1F600? Then confirm with jq.
---hint---
U+00E9 is a Latin letter with an accent. For the emoji, the pair is the one in the first example.
---solution---
`\u00e9` is `é`. U+1F600 is written as the surrogate pair `\ud83d\ude00`. `jq -r` decodes both, and `jq -a` turns the characters back into escapes.
---script---
printf '["\\u00e9","\\ud83d\\ude00"]\n' > decode.json
jq -r '.[]' decode.json
jq -a -c . decode.json
```

```exercise
---title---
Make a log line safe
---prompt---
A log message contains a newline and a double quote: `He said "stop"` followed by a line break and `now`. Build a JSON object `{"msg": ...}` from that text without writing any escape by hand, and print it on one line.
---hint---
`jq -n --arg msg "$text" '{msg: $msg}'` takes the shell variable as a string and escapes it.
---solution---
Let a JSON tool do the escaping. `--arg` passes the text in as a string, and `-c` prints the object on one line, with the newline written as `\n` and the quotes as `\"`.
---script---
text=$(printf 'He said "stop"\nnow')
jq -n -c --arg msg "$text" '{msg: $msg}'
```
