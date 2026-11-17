---
number: 9
slug: yaml-structure
title: Block structure and indentation
module: YAML
level: beginner
minutes: 25
summary: Mappings, sequences, and nesting in block style. The indentation rules are short, and nearly every beginner error is one of three mistakes.
objectives:
  - Write nested mappings and sequences in block style and predict the resulting tree
  - Explain how "- " counts toward indentation, and why a sequence may sit at the same column as its key
  - Spot the difference between a list item with a mapping inside and a list of plain strings
  - Read the error a parser gives for a tab, a mis-aligned key, and a mis-aligned list item
further:
  - title: YAML 1.2.2 specification, chapter 6 (Basic Structures), indentation spaces
    url: https://yaml.org/spec/1.2.2/#61-indentation-spaces
  - title: YAML 1.2.2 specification, chapter 8 (Block Style Productions)
    url: https://yaml.org/spec/1.2.2/#chapter-8-block-style-productions
  - title: The yaml npm package documentation
    url: https://eemeli.org/yaml/
pitfall: |
  A mis-indented list item is not always an error. If a "- " line is indented deeper than the previous item, the parser may read it as a continuation of the previous string, and the file still loads. The tree is wrong and nothing complains. Convert to JSON and look at the result whenever a list has an unexpected number of items.
---

In lesson 1 you saw that YAML and JSON describe the same tree. This lesson is about the block notation that makes YAML look like YAML: no braces, no brackets, structure carried by line breaks and indentation.

## The three building blocks

A **block mapping** is a set of `key: value` lines that start in the same column. A **block sequence** is a set of `- item` lines that start in the same column. A value can be a scalar, or another mapping or sequence on the following lines, indented further.

```run
# title: Mappings, sequences, and nesting
cat > app.yaml <<'EOF'
name: shop
owner:
  team: payments
  oncall: true
ports:
  - 80
  - 443
limits:
  cpu: 2
  memory: 512
EOF
yaml2json app.yaml | jq -c .
```

The `owner` key has no value on its own line, so its value is whatever block comes next, one level deeper. The `ports` key does the same with a sequence. There is no separate end marker: a block ends when a line appears at a shallower column.

## The indentation rules

The rules are short:

1. **Spaces only.** A tab cannot be used for indentation.
2. **Siblings share a column.** All keys of one mapping start at the same column. All items of one sequence do too.
3. **A child is indented more than its parent.** How much more is up to you, as long as you stay consistent within that block. Two spaces is the convention.
4. **`- ` counts as indentation.** The dash and the space after it take up two columns, and whatever follows the dash starts at the third.

The fourth rule explains the most common surprise. A sequence that is the value of a key is allowed to start at the *same column as the key*:

```run
# title: Indented and unindented sequences are the same tree
printf 'a:\n- 1\n- 2\nb:\n  - 3\n' > seqs.yaml
cat seqs.yaml
echo "----"
yaml2json seqs.yaml | jq -c .
```

Both spellings are valid. Style guides disagree about which to use, so follow whatever the file you are editing already does. Kubernetes manifests often leave sequences unindented; GitHub workflows usually indent them.

## Lists of mappings

When a list item is a mapping, the first key can sit on the same line as the dash. The remaining keys line up under it, which is the column after `- `:

```run
# title: Lists of mappings, and a sequence inside a sequence
cat > items.yaml <<'EOF'
- name: a
  size: 1
-
  name: b
  size: 2
EOF
yaml2json items.yaml | jq -c .
echo "---- a sequence directly inside a sequence ----"
printf -- '- - 1\n  - 2\n- - 3\n' | yaml2json | jq -c .
```

The first item uses the compact form and the second puts the dash alone. They produce the same kind of tree. The compact form is much more common because the dash points at the start of each record. A sequence directly inside a sequence also works, using two dashes on one line, as the last command shows.

## Flow collections inside block style

You can mix the two. A value in a block mapping may be written in flow style (`[...]` or `{...}`), which is handy for short lists:

```run
# title: Flow style inside block style
cat > mixed.yaml <<'EOF'
tags: [web, public]
resources: {cpu: 2, memory: 512}
empty_list: []
empty_map: {}
no_value:
EOF
yaml2json mixed.yaml | jq -c .
```

Note `no_value:`. A key with nothing after it becomes `null`, not an empty string and not an empty mapping. Lesson 11 returns to this.

## The three common mistakes

```run
# title: Three indentation errors
printf 'a:\n\tb: 1\n' > tab.yaml
printf 'a:\n  b: 1\n c: 2\n' > align.yaml
printf 'a:\n   - 1\n  - 2\n' > deeper.yaml
for f in tab align deeper; do
  echo "== $f.yaml"
  yamlcheck $f.yaml || true
done
```

The first file uses a tab, the second has a key at column 2 beside a sibling at column 3, and the third has a list item indented deeper than its neighbour. Each message gives a line and column and a short code from the `yaml` package. `TAB_AS_INDENT` and `BAD_INDENT` say what is wrong. The third message is less direct. The parser sees `- 1` start a sequence at column 4, then sees `- 2` at column 3, which cannot belong to that sequence and cannot be a key either. Its error names a block sequence used as an implicit map key. When a YAML error reads strangely, look at the indentation of the line it points at and the line above it.

The quiet version of the same mistake is worse. Here the second item is indented *one space further* than the first:

```run
# title: An over-indented item that still parses
printf 'a:\n  - 1\n   - 2\n' > quiet.yaml
yamlcheck quiet.yaml
yaml2json quiet.yaml | jq -c .
```

The file is valid, and `a` has one item, the string `"1 - 2"`. The extra-indented line was read as a continuation of the first item's text, folded onto one line with a space. Lesson 10 explains this folding rule. For now: if your list has the wrong number of items, convert it and look.

## Exercises

```exercise
---title---
Count the items
---prompt---
Write a file `team.yaml` for a team with a `name`, and a `members` list of three people, each with a `name` and a `role`. Use the compact form, with the first key on the dash line. Then use `yaml2json` and `jq` to print how many members there are.
---hint---
`jq '.members | length'` counts the items in the list.
---solution---
Each item starts with `- name: ...` and the `role` line is indented two spaces further, so that it lines up with `name`. If `role` lines up with the dash instead, the parser reports an error.
---script---
cat > team.yaml <<'EOF'
name: platform
members:
  - name: Ada
    role: lead
  - name: Grace
    role: engineer
  - name: Linus
    role: engineer
EOF
yaml2json team.yaml | jq '.members | length'
```

```exercise
---title---
Same tree, two layouts
---prompt---
Write `a.yaml` with a sequence under `steps` indented by two spaces, and `b.yaml` with the same sequence at the same column as `steps`. Show that both give identical JSON.
---hint---
Convert each one to JSON and compare the output with `cmp`.
---solution---
The sequence may start at the parent key's column, so both layouts produce the same tree.
---script---
printf 'steps:\n  - build\n  - test\n' > a.yaml
printf 'steps:\n- build\n- test\n' > b.yaml
yaml2json a.yaml > a.json
yaml2json b.yaml > b.json
cmp a.json b.json && echo "identical"
```

```exercise
---title---
Why is the count wrong?
---prompt---
A colleague's file has three list items but `jq '.deploy | length'` prints `2`. Run the script, then explain the cause and fix it so the count is 3.
---hint---
Print the converted JSON and look for an item that contains more text than you expect.
---solution---
The third line is indented one space deeper than the others, so it is folded into the second item as text. The fix is to indent every dash to the same column.
---script---
cat > deploy.yaml <<'EOF'
deploy:
  - build
  - test
   - ship
EOF
yaml2json deploy.yaml | jq -c .
yaml2json deploy.yaml | jq '.deploy | length'
sed -i 's/^   - ship/  - ship/' deploy.yaml
yaml2json deploy.yaml | jq '.deploy | length'
```
