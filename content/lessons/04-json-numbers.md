---
number: 4
slug: json-numbers
title: Numbers, precision, and big IDs
module: JSON
level: intermediate
minutes: 25
summary: JSON has one number type and says nothing about its size or precision. What you get back depends on the language that reads it, and large integers are where tools quietly disagree.
objectives:
  - Describe what the JSON grammar says about numbers and what it leaves to the reader
  - Show a 64-bit integer losing precision in node and jq 1.6 but not in Python
  - Explain why 1.0 and 1 may or may not survive a round trip
  - Choose between a number and a string for an identifier, and read big values with Decimal
further:
  - title: RFC 8259, section 6 (Numbers)
    url: https://www.rfc-editor.org/rfc/rfc8259#section-6
  - title: Python json module, parse_float and parse_int
    url: https://docs.python.org/3/library/json.html#encoders-and-decoders
  - title: jq manual (arbitrary-precision numbers and literals)
    url: https://jqlang.org/manual/
pitfall: |
  The grammar lets you write any number of digits. RFC 8259 only advises that interoperable software should expect no more precision than an IEEE 754 double provides. A 19-digit ID that is fine in Python or a database can be silently rounded by a JavaScript client or by the jq 1.6 installed here. Send identifiers as strings.
---

The number grammar is short: an optional minus sign, an integer part with no leading zeros, an optional fraction, and an optional exponent. `0`, `-12`, `3.14`, and `6.02e23` are numbers. `01`, `.5`, `5.`, `+1`, and `0x1F` are not (lesson [The whole JSON grammar](/lessons/json-grammar)).

There is **one** number type. JSON does not distinguish an integer from a float, or a 32-bit value from a 64-bit one. It also does not say how many digits you may use. The text `9007199254740993` is a legal number. What a program does with it is the reader's decision.

## Three readers, one document

The next script reads one document in jq, node, and Python and prints what each holds. The `id` is 2^53 + 1, the first positive integer that a 64-bit double cannot store exactly.

```run
# title: One document, three number models
cat > n.json <<'EOF'
{"id": 9007199254740993, "big": 12345678901234567890123, "f": 1.0, "e": 1E2, "pi": 3.14159265358979323846264}
EOF
echo "--- jq -c"; jq -c . n.json
echo "--- node"
node -e 'console.log(JSON.stringify(JSON.parse(require("fs").readFileSync("n.json","utf8"))))'
echo "--- python"
python3 -c 'import json; print(json.dumps(json.load(open("n.json"))))'
```

Read the three lines against the input:

- **node and jq 1.6** hold every number as a 64-bit double. `id` came back as `9007199254740992`, one lower than what was written, with no warning. `big` was rounded to the nearest double. `pi` lost its trailing digits in all three tools, because the digits after the 17th are beyond any double.
- **Python** reads a number without a fraction or exponent as an arbitrary-precision `int`, so `id` and `big` came back exactly.
- `1.0` and `1E2` have a fraction or exponent, so Python reads them as floats and writes `1.0` and `100.0`. node and jq print `1` and `100`, because for them the two spellings were always the same number.

Notice what this means for round trips. Python preserved the text of `id` and `big` because it treats integers specially, not because JSON promises it.

## Doing arithmetic with doubles

Double precision is a property of the arithmetic too, not only the parser.

```run
# title: The same sums in node and Python
echo "node:"
node -e 'console.log(0.1 + 0.2); console.log(2**53 + 1); console.log(Number.MAX_SAFE_INTEGER)'
echo "python:"
python3 -c 'print(0.1 + 0.2); print(2**53 + 1); print(float(2**53 + 1))'
echo "jq:"
jq -n -c '[0.1 + 0.2, 9007199254740993 + 0]'
```

`0.1 + 0.2` is `0.30000000000000004` everywhere, because none of these languages can store 0.1 exactly in binary. `2**53 + 1` is where they split. node's `Number` rounds it, and the constant `Number.MAX_SAFE_INTEGER` tells you the largest integer below which every integer is exact. Python's `int` has no such limit, but converting that value to `float` rounds it, as the last line of its output shows. jq 1.6 does the sum with doubles.

## Identifiers: use strings

Twitter's API famously returns each tweet ID twice, as `id` (a number) and `id_str` (a string), because JavaScript clients corrupted the numeric form. The lesson generalises: if a value is an identifier rather than a quantity, you never add or compare it by size, so a string loses nothing and cannot be rounded.

```run
# title: An ID as a number and as a string
cat > ids.json <<'EOF'
{"as_number": 9007199254740993, "as_string": "9007199254740993"}
EOF
echo "jq reads the number:"; jq '.as_number' ids.json
echo "jq reads the string:"; jq '.as_string' ids.json
echo "converting the string to a number in jq 1.6:"; jq '.as_string | tonumber' ids.json
echo "node, comparing:"
node -e '
const d = JSON.parse(require("fs").readFileSync("ids.json", "utf8"));
console.log(String(d.as_number), d.as_string, String(d.as_number) === d.as_string);
'
```

The string survives untouched. The number does not: its digits are different after parsing, and the comparison in node prints `false`. Converting a string to a number reintroduces the rounding, because `tonumber` in jq 1.6 produces a double.

## Keeping exact decimals in Python

Python's `json` module lets you choose how numbers are built. `parse_float=Decimal` keeps the digits you typed, including trailing zeros, which matters for prices and measurements.

```run
# title: parse_float with Decimal
python3 - <<'EOF'
import json
from decimal import Decimal

text = '{"price": 1.10, "qty": 3}'
print("default:     ", json.loads(text))
print("with Decimal:", json.loads(text, parse_float=Decimal))
EOF
```

`1.10` stays `Decimal('1.10')`. Writing a `Decimal` back out takes an extra step, because `json.dumps` does not know the type. Pass a `default=` function or convert to a string. Many teams solve the problem on the wire instead and send money as an integer count of cents, or as a string such as `"1.10"`.

## Out-of-range numbers

A document may contain `1e400`, which is a legal number that no double can hold. Readers handle it in different ways. The next script shows the three here.

```run
# title: A number too large for a double
echo '{"s": 1e400}' > huge.json
echo "jq:     $(jq -c . huge.json)"
echo "node:   $(node -e 'const d = JSON.parse(require("fs").readFileSync("huge.json","utf8")); console.log(d.s, JSON.stringify(d))')"
echo "python: $(python3 -c 'import json; d = json.load(open("huge.json")); print(d["s"], json.dumps(d))')"
```

jq 1.6 clamps to the largest finite double. node reads it as `Infinity`, and `JSON.stringify` then writes `null`, because JSON has no way to write infinity. Python reads `inf` and `json.dumps` writes `Infinity`, which is not valid JSON (lesson [The whole JSON grammar](/lessons/json-grammar)). In each case a legal input turned into something else without an error.

## Exercises

```exercise
---title---
Find the first integer that breaks
---prompt---
In node, find out whether `Number.MAX_SAFE_INTEGER + 1` and `Number.MAX_SAFE_INTEGER + 2` are equal. Then write the number 9007199254740993 as a JSON document and print what `jq .` gives back.
---hint---
Compare them with `===`. For the second part, use `echo` to write the document and pipe it to jq.
---solution---
Both sums round to the same double, so the comparison is `true`. After that, jq 1.6 prints `9007199254740992`, which is a different number from the one you wrote.
---script---
node -e 'const m = Number.MAX_SAFE_INTEGER; console.log(m + 1 === m + 2)'
echo '9007199254740993' | jq .
```

```exercise
---title---
Does the round trip keep the decimal?
---prompt---
Take the array `[1.0, 1.50, 100]`. Print it unchanged through `jq -c .` and through Python's `json.dumps(json.load(...))`. Are the outputs the same? Say why in one sentence.
---hint---
Look at how each tool treats a number with a fraction when the fraction is zero.
---solution---
They differ. jq 1.6 prints `[1,1.5,100]`, which normalises the numbers to doubles and drops the trailing zeros. Python keeps the float type, so `1.0` stays `1.0` and `1.50` becomes `1.5`, because the float has no memory of the trailing zero.
---script---
echo '[1.0, 1.50, 100]' > r.json
jq -c . r.json
python3 -c 'import json; print(json.dumps(json.load(open("r.json"))))'
```
