# YAML & JSON, from the grammar up

A static course on JSON and YAML: the shared data model, the JSON grammar, jq, YAML structure and types, anchors, multi-document streams, safe loading, JSON Schema, and the config files you meet at work (GitHub Actions, `tsconfig.json`, Compose, Kubernetes). Every example on a lesson page was executed when the site was built, and the page shows the real stdout, stderr, and exit status.

The site is a Next.js static export, deployed to GitHub Pages.

## Layout

| Path | What it is |
| --- | --- |
| `content/lessons/*.md` | Lessons. YAML frontmatter plus Markdown, with `run` and `exercise` blocks. |
| `content/generated/course.json` | Lessons plus captured output. Generated, committed. |
| `tools/bin/` | Four helper commands used by the examples (below). |
| `scripts/assemble.mjs` | Runs every example and writes the generated files. |
| `scripts/validate.mjs` | Structural checks (`npm test`). |
| `public/downloads/examples/` | Each example as a runnable script. Generated, committed. |
| `src/` | The site. |

## Helper commands

Thin wrappers around published libraries, so a lesson describes that library's real behaviour.

| Command | Does | Library |
| --- | --- | --- |
| `yaml2json [--yaml-1.1] [--all] [--max-alias-count N] [file]` | Parse YAML, print JSON | `yaml` |
| `json2yaml [file]` | Strict `JSON.parse`, print YAML | `yaml` |
| `yamlcheck [--yaml-1.1] file...` | Report parse errors as `file:line:col` | `yaml` |
| `schema-check schema.json data...` | Validate JSON or YAML against a JSON Schema (draft 2020-12) | Ajv |

`yamlcheck` reports parse errors only. Problems that appear when the data is built, such as an alias to an undefined anchor, are reported by `yaml2json` (lessons 18 and 20 show this).

The examples also use `jq`, `python3`, and `node`. The captured output in this tree came from the versions recorded on the site's About page. The examples were written against jq 1.6; jq 1.7 may print some results differently.

## Run it locally

Node 22 and npm.

```bash
npm ci
export PATH="$PWD/tools/bin:$PATH"
npm run dev        # http://127.0.0.1:41828
```

```bash
npm test           # checks that captures match the sources, links resolve
npm run build      # static site in out/
```

## Writing or changing a lesson

Lesson files start with frontmatter (`number`, `slug`, `title`, `module`, `level`, `minutes`, `summary`, `objectives`, `further`, `pitfall`).

- A fenced `run` block is a bash script. Optional header lines: `# title:` and `# expect-exit: N`.
- A fenced `exercise` block has `---title---`, `---prompt---`, `---hint---`, optional `---hint2---`, `---solution---`, and `---script---` sections. Use a four-backtick fence when the exercise itself contains a fenced block.

Check one lesson without writing anything:

```bash
node scripts/assemble.mjs --check content/lessons/01-one-data-model.md
```

Regenerate everything after editing lessons or `tools/bin`:

```bash
npm run generate
```

The generator fails if any example exits with a status other than the one declared, so prose cannot drift away from what the tools do. Commit the regenerated `content/generated/` and `public/` files; CI does not re-run the examples, because a different runner would replace the captured output with its own.

## GitHub Pages

`.github/workflows/pages.yml` runs `npm ci`, `npm test`, and `npm run build`, then deploys `out/` with the official Pages actions on pushes to `main`. The base path is chosen at build time, as `/<repository-name>` for a project site, or empty for `<owner>.github.io` or when the repository variable `BASE_PATH` is `/`.

In the repository settings, set **Pages → Source** to **GitHub Actions** once.

## Limits

- Output comes from one machine and one set of tool versions.
- Only the `yaml` package is used as a YAML parser. Statements about other implementations (for example PyYAML's YAML 1.1 behaviour) are documented facts, not executed here.
