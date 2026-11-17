---
number: 10
slug: yaml-scalars
title: Strings, quoting, and multi-line text
module: YAML
level: intermediate
minutes: 30
summary: YAML has five ways to write a string. Know when plain text is safe, what forces quotes, and how the block styles | and > treat line breaks.
objectives:
  - Choose between plain, single-quoted, and double-quoted scalars
  - List the characters and sequences that make a plain scalar invalid or change its meaning
  - Predict the exact string produced by a literal (|) or folded (>) block, including the final newline
  - Use the chomping indicators - and + and an indentation indicator
further:
  - title: YAML 1.2.2 specification, chapter 7 (Flow Style Productions), scalars
    url: https://yaml.org/spec/1.2.2/#chapter-7-flow-style-productions
  - title: YAML 1.2.2 specification, section 8.1 (Block Scalar Styles)
    url: https://yaml.org/spec/1.2.2/#81-block-scalar-styles
  - title: The yaml npm package documentation
    url: https://eemeli.org/yaml/
pitfall: |
  A block scalar ends with exactly one newline by default. A shell command in a "run: |" block therefore ends in a newline, which is harmless. A value that is compared as a string, such as a token or a certificate, is not harmless: use |- when the newline must not be there.
---

JSON has one way to write a string. YAML has five: plain, single-quoted, double-quoted, literal block, and folded block. They all produce the same kind of value, a string, but they differ in what they let you type. This lesson gets you from "I quote everything to be safe" to knowing when each style is the right tool.

## Plain, single-quoted, double-quoted

```run
# title: Three styles for the same kind of value
cat > styles.yaml <<'EOF'
plain: hello world
single: 'it''s fine'
double: "tab\there, caf\u00e9, \x41"
single_backslash: 'no\tescape here'
EOF
yaml2json styles.yaml
```

Read the output against the input:

- **Plain** has no quotes at all. The text is taken as written, with surrounding spaces trimmed.
- **Single-quoted** has exactly one escape: two single quotes in a row mean one quote. A backslash is just a backslash, which is why `'no\tescape here'` came out with a literal `\t`. JSON shows that as `\\t`.
- **Double-quoted** supports backslash escapes such as `\t`, `\xNN`, and `\uNNNN`, much like JSON strings. Use it when you need a tab, a newline, or a non-printing character.

Single quotes are the better default when the text contains backslashes, such as a regular expression or a Windows path. Nothing needs escaping except the quote itself.

A workable habit: write plain scalars for ordinary words and identifiers, single quotes when the text has backslashes or looks like something else, and double quotes only when you need an escape. Quoting is also how you tell the parser "this is a string" when plain text would be read as another type. That second use matters more than it seems, and lesson 11 is built around it.

## What forces quotes

A plain scalar is not just "anything". The parser treats some characters specially at the start of a value, and some sequences anywhere:

```run
# title: Which plain scalars survive
cat > forces.yaml <<'EOF'
colon_quoted: "a: b"
hash_quoted: "a #b"
inline_hash: a#b
comment_after: a #b
at_quoted: "@user"
EOF
yaml2json forces.yaml | jq -c .
echo "---- the unquoted forms ----"
for v in '@user' 'x: y' '- x' '[x' '*' '%x'; do
  printf 'a: %s\n' "$v" > one.yaml
  printf '%s  ->  ' "$v"
  yamlcheck one.yaml | head -n 1 || true
done
```

The first block shows quoting working. `a#b` is fine because the comment marker `#` only counts when a space comes before it, so `comment_after: a #b` is the string `a` followed by a comment. The second part runs each risky value unquoted and prints the first message. Each one fails: `@` and `%` are reserved indicator characters, `x: y` looks like a nested mapping, `- x` looks like a list item on the key's line, `[x` opens a flow sequence that never closes, and a bare `*` is an alias with no name.

The practical rule: quote any value that starts with one of ``@ ` * & ! | > % { [ ' "`` , contains `: ` or ` #`, or that you would not want read as a number, boolean, or null. The last case is the subject of lesson 11.

## Literal blocks: keep the line breaks

A `|` after the key starts a **literal** block. The indented lines that follow become the value, line breaks and all. This is what you want for shell scripts, certificates, and anything where lines matter.

## Folded blocks: join lines into paragraphs

A `>` starts a **folded** block. A single line break becomes a space, a blank line becomes a real newline, and lines that are indented *more* than the rest keep their break. It suits long prose you want to wrap in the source file.

```run
# title: Literal and folded blocks
cat > blocks.yaml <<'EOF'
literal: |
  line one
    indented
  line three
folded: >
  folded text
  continues here

  new paragraph
EOF
yaml2json blocks.yaml | jq -c .
```

In the literal value the second line keeps its two extra spaces. In the folded value, `folded text` and `continues here` merged into one line, and the blank line became `\n`.

## Chomping: controlling the trailing newlines

By default (called *clip*) a block scalar ends with exactly one newline, no matter how many blank lines follow it. Two indicators on the header change that:

- `|-` or `>-` (*strip*) removes the final newline.
- `|+` or `>+` (*keep*) keeps every trailing blank line.

An *indentation indicator* is a digit, as in `|2`. It sets the indentation explicitly, which you need when the first line of the content starts with spaces that would otherwise be taken as indentation.

```run
# title: Clip, strip, keep, and an indentation indicator
cat > chomp.yaml <<'EOF'
clip: |
  one newline
strip: |-
  no trailing newline
keep: |+
  keeps newlines


indicator: |2
    two extra spaces
EOF
yaml2json chomp.yaml | jq -c .
```

`keep` ended in three newlines: the one that ends the line, plus the two blank lines. `indicator` begins with two spaces because the indicator `2` said the indentation is two columns and the line has four.

## Multi-line plain scalars

A plain scalar can also wrap across lines, using the same folding rule as `>`:

```run
# title: A plain scalar that spans lines
cat > multi.yaml <<'EOF'
multi: first line
  second line

  after blank
EOF
yaml2json multi.yaml | jq -c .
```

The first break became a space and the blank line became a newline. This is how the quiet bug in lesson 9 happened: an over-indented `- 2` was read as more text for the previous item. Using a block style when text spans lines makes your intent explicit.

For how text turns into JSON strings and which escapes JSON has, see [JSON strings](/lessons/json-strings).

## Exercises

```exercise
---title---
Quote the right ones
---prompt---
Each of these needs quoting to load as the string shown in the comment. Write `quote.yaml` with correct values and print it as JSON: a Windows path `C:\temp\new` (backslashes must stay), the text `note: remember` (contains a colon and space), and the text `@home`.
---hint---
Single quotes keep backslashes literal. Either quote style works for the other two.
---solution---
Use single quotes for the path so `\t` and `\n` are not treated as escapes. With double quotes the path would contain a tab and a newline.
---script---
cat > quote.yaml <<'EOF'
path: 'C:\temp\new'
note: 'note: remember'
handle: '@home'
EOF
yaml2json quote.yaml | jq -c .
```

```exercise
---title---
Exactly one trailing newline, or none
---prompt---
Write `script.yaml` with two keys holding the same shell command `echo hi`: `with_nl` using a literal block that ends in a newline, and `without_nl` using one that does not. Print the lengths of both strings with `jq`.
---hint---
`jq '.with_nl | length'` counts characters. The strip indicator is a minus.
---solution---
The clip form gives `echo hi\n`, 8 characters. The strip form gives `echo hi`, 7.
---script---
cat > script.yaml <<'EOF'
with_nl: |
  echo hi
without_nl: |-
  echo hi
EOF
yaml2json script.yaml | jq -c '{with_nl: (.with_nl | length), without_nl: (.without_nl | length)}'
```

```exercise
---title---
A paragraph in the source, one line in the value
---prompt---
Write `desc.yaml` where `description` is a long sentence you wrap across three source lines, but which must load as a single line with no newline at all. Print it with `jq -r`.
---hint---
A folded block joins lines with spaces. You also need to strip the final newline.
---solution---
Use `>-`. The folded style joins the three lines with single spaces and the minus removes the trailing newline.
---script---
cat > desc.yaml <<'EOF'
description: >-
  This sentence is wrapped across
  three lines in the source file
  but loads as one.
EOF
yaml2json desc.yaml | jq -r .description
```
