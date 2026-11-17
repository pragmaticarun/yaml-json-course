#!/usr/bin/env node
// Execute every lesson example and exercise in a scratch directory and write
// content/generated/course.json, public/search-index.json and the downloads.
//
// Lesson files are Markdown with YAML frontmatter. Two fenced block types are
// special:
//   ```run       a bash script; header lines `# title:` and `# expect-exit:`
//   ```exercise  sections ---title--- ---prompt--- ---hint--- ---solution---
//                ---script--- and an optional `expect-exit: N` preamble
// Use a longer fence (````exercise) when the block itself contains ``` fences.
// Anything else is ordinary Markdown.

import { createHash } from "node:crypto";
import { execFileSync, spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import YAML from "yaml";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const LESSONS = path.join(ROOT, "content", "lessons");
const GENERATED = path.join(ROOT, "content", "generated");
const PUBLIC = path.join(ROOT, "public");
const DOWNLOADS = path.join(PUBLIC, "downloads", "examples");
const TOOLS = path.join(ROOT, "tools", "bin");
const MAX_OUTPUT = 12000;
const LEVELS = new Set(["beginner", "intermediate", "advanced"]);
// `--check a.md b.md` runs those lessons and prints captures without writing files.
const CHECK = process.argv[2] === "--check";

export function fail(message) {
  console.error(message);
  process.exit(1);
}

export function sourceHash() {
  const hash = createHash("sha256");
  const files = [
    ...fs.readdirSync(LESSONS).filter((f) => f.endsWith(".md")).sort().map((f) => path.join(LESSONS, f)),
    ...fs.readdirSync(TOOLS).sort().map((f) => path.join(TOOLS, f)),
  ];
  for (const file of files) {
    hash.update(path.relative(ROOT, file));
    hash.update("\0");
    hash.update(fs.readFileSync(file));
    hash.update("\0");
  }
  return hash.digest("hex");
}

function parseFrontmatter(file, text) {
  const match = /^---\n([\s\S]*?)\n---\n/.exec(text);
  if (!match) fail(`${file}: missing frontmatter`);
  const doc = YAML.parseDocument(match[1]);
  if (doc.errors.length) fail(`${file}: frontmatter: ${doc.errors[0].message}`);
  const data = doc.toJS();
  for (const key of ["number", "slug", "title", "module", "level", "minutes", "summary"]) {
    if (data[key] === undefined || data[key] === null || data[key] === "") fail(`${file}: frontmatter needs ${key}`);
  }
  if (!LEVELS.has(data.level)) fail(`${file}: level must be one of ${[...LEVELS].join(", ")}`);
  return { data, body: text.slice(match[0].length) };
}

function parseRun(text) {
  const meta = { title: "", expect: 0 };
  const lines = text.split("\n");
  let i = 0;
  for (; i < lines.length; i++) {
    const line = lines[i];
    if (line.startsWith("# title:")) meta.title = line.slice(8).trim();
    else if (line.startsWith("# expect-exit:")) meta.expect = Number(line.slice(14).trim());
    else if (line.trim() !== "") break;
  }
  return { meta, script: lines.slice(i).join("\n").replace(/\s+$/, "") + "\n" };
}

function parseExercise(file, text) {
  const parts = text.split(/^---(title|prompt|hint|hint2|solution|script)---[ \t]*$/m);
  const data = { expect: 0, title: "", prompt: "", hint: "", hint2: "", solution: "", script: "" };
  const pre = /^expect-exit:\s*(\d+)\s*$/m.exec(parts[0]);
  if (pre) data.expect = Number(pre[1]);
  for (let i = 1; i + 1 < parts.length; i += 2) data[parts[i]] = parts[i + 1].replace(/^\n+|\s+$/g, "");
  for (const key of ["title", "prompt", "hint", "solution", "script"]) {
    if (!data[key]) fail(`${file}: exercise "${data.title || "?"}" is missing ${key}`);
  }
  data.script += "\n";
  return data;
}

function clip(text) {
  if (text.length <= MAX_OUTPUT) return { text, truncated: false };
  return { text: text.slice(0, MAX_OUTPUT) + "\n[... truncated ...]\n", truncated: true };
}

function runScript(script) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "yjc-"));
  try {
    const result = spawnSync("bash", ["-e", "-o", "pipefail", "-c", script], {
      cwd: dir,
      encoding: "utf8",
      timeout: 30000,
      env: {
        PATH: `${TOOLS}:/usr/local/bin:/usr/bin:/bin`,
        HOME: dir,
        TMPDIR: dir,
        LC_ALL: "C.UTF-8",
        TZ: "UTC",
        NO_COLOR: "1",
        PYTHONDONTWRITEBYTECODE: "1",
      },
    });
    if (result.error) throw result.error;
    // Scratch paths differ on every run; replace them so captures are stable.
    const scrub = (s) => s.split(dir).join("/tmp/scratch");
    return { stdout: scrub(result.stdout), stderr: scrub(result.stderr), exitCode: result.status ?? -1 };
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function headingsOf(markdown) {
  const out = [];
  let fence = false;
  for (const line of markdown.split("\n")) {
    if (line.startsWith("```")) fence = !fence;
    if (fence) continue;
    const m = /^(#{2,3})\s+(.+)$/.exec(line);
    if (m) {
      const text = m[2].trim();
      const id = text.toLowerCase().replace(/[`'"’]/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
      out.push({ level: m[1].length, id, text: text.replace(/`/g, "") });
    }
  }
  return out;
}

function wordCount(markdown) {
  return markdown.replace(/```[\s\S]*?```/g, " ").split(/\s+/).filter(Boolean).length;
}

function writeDownload(name, script) {
  if (CHECK) return `/downloads/examples/${name}`;
  const header = `#!/usr/bin/env bash\n# From the YAML & JSON course. Expects the course tools on PATH:\n#   export PATH="$PWD/tools/bin:$PATH"   (run from a clone of the repo)\nset -eo pipefail\n`;
  fs.writeFileSync(path.join(DOWNLOADS, name), header + script, { mode: 0o755 });
  return `/downloads/examples/${name}`;
}

function buildLesson(file) {
  const raw = fs.readFileSync(path.join(LESSONS, file), "utf8");
  const { data, body } = parseFrontmatter(file, raw);
  const examples = [];
  const exercises = [];
  const markdown = body.replace(/^(`{3,})(run|exercise)\n([\s\S]*?)\n\1[ \t]*$/gm, (_, _fence, kind, inner) => {
    if (kind === "run") {
      const { meta, script } = parseRun(inner);
      const id = `${data.slug}-${String(examples.length + 1).padStart(2, "0")}`;
      const result = runScript(script);
      if (result.exitCode !== meta.expect) {
        fail(`${file}: example "${meta.title}" exited ${result.exitCode}, expected ${meta.expect}\n--- stdout\n${result.stdout}--- stderr\n${result.stderr}`);
      }
      const out = clip(result.stdout);
      const err = clip(result.stderr);
      const example = {
        id,
        title: meta.title,
        script,
        stdout: out.text,
        stderr: err.text,
        exitCode: result.exitCode,
        download: writeDownload(`${id}.sh`, script),
        truncated: out.truncated || err.truncated,
      };
      examples.push(example);
      return "```example\n" + JSON.stringify(example) + "\n```";
    }
    const ex = parseExercise(file, inner);
    const id = `${data.slug}-ex${String(exercises.length + 1).padStart(2, "0")}`;
    const result = runScript(ex.script);
    if (result.exitCode !== ex.expect) {
      fail(`${file}: exercise "${ex.title}" exited ${result.exitCode}, expected ${ex.expect}\n--- stdout\n${result.stdout}--- stderr\n${result.stderr}`);
    }
    const exercise = {
      id,
      title: ex.title,
      prompt: ex.prompt,
      hint: ex.hint,
      hint2: ex.hint2,
      solution: ex.solution,
      script: ex.script,
      stdout: clip(result.stdout).text,
      stderr: clip(result.stderr).text,
      exitCode: result.exitCode,
      download: writeDownload(`${id}.sh`, ex.script),
    };
    exercises.push(exercise);
    return "```exercise\n" + JSON.stringify(exercise) + "\n```";
  });
  return {
    slug: data.slug,
    number: data.number,
    title: data.title,
    module: data.module,
    level: data.level,
    minutes: data.minutes,
    summary: data.summary,
    objectives: data.objectives ?? [],
    further: data.further ?? [],
    pitfall: (data.pitfall ?? "").trim(),
    markdown,
    headings: headingsOf(body),
    examples,
    exercises,
    wordCount: wordCount(body),
  };
}

function version(cmd, args, pick = (s) => s.split("\n")[0]) {
  try {
    return pick(execFileSync(cmd, args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim());
  } catch {
    return "not installed";
  }
}

function pkgVersion(name) {
  return JSON.parse(fs.readFileSync(path.join(ROOT, "node_modules", name, "package.json"), "utf8")).version;
}

function check(files) {
  for (const file of files) {
    const lesson = buildLesson(path.basename(file));
    for (const item of [...lesson.examples, ...lesson.exercises]) {
      console.log(`\n=== ${item.id}: ${item.title} (exit ${item.exitCode})\n${item.script}--- stdout\n${item.stdout}--- stderr\n${item.stderr}`);
    }
    console.log(`\n${file}: ${lesson.examples.length} examples, ${lesson.exercises.length} exercises, ${lesson.wordCount} words`);
  }
}

function main() {
  fs.rmSync(DOWNLOADS, { recursive: true, force: true });
  fs.mkdirSync(DOWNLOADS, { recursive: true });
  fs.mkdirSync(GENERATED, { recursive: true });

  const files = fs.readdirSync(LESSONS).filter((f) => f.endsWith(".md")).sort();
  const lessons = [];
  for (const file of files) {
    process.stdout.write(`${file} ... `);
    const lesson = buildLesson(file);
    lessons.push(lesson);
    console.log(`${lesson.examples.length} examples, ${lesson.exercises.length} exercises`);
  }
  lessons.sort((a, b) => a.number - b.number);
  const seen = new Set();
  lessons.forEach((lesson, i) => {
    if (seen.has(lesson.slug)) fail(`duplicate slug ${lesson.slug}`);
    seen.add(lesson.slug);
    if (lesson.number !== i + 1) fail(`lesson numbers must run 1..n; ${lesson.slug} is ${lesson.number}`);
  });

  const meta = {
    title: "YAML & JSON, from the grammar up",
    sourceHash: sourceHash(),
    node: process.version,
    yaml: pkgVersion("yaml"),
    ajv: pkgVersion("ajv"),
    jq: version("jq", ["--version"]),
    python: version("python3", ["--version"]),
    bash: version("bash", ["--version"]),
    uname: version("uname", ["-srm"]),
  };

  const course = { meta, lessons };
  fs.writeFileSync(path.join(GENERATED, "course.json"), JSON.stringify(course, null, 1) + "\n");

  const index = lessons.map((l) => ({
    kind: "lesson",
    slug: l.slug,
    number: l.number,
    title: l.title,
    module: l.module,
    summary: l.summary,
    text: l.markdown.replace(/```[\s\S]*?```/g, " ").replace(/\s+/g, " ").slice(0, 4000),
  }));
  fs.writeFileSync(path.join(PUBLIC, "search-index.json"), JSON.stringify(index) + "\n");

  const ex = lessons.reduce((n, l) => n + l.examples.length, 0);
  const xs = lessons.reduce((n, l) => n + l.exercises.length, 0);
  console.log(`\n${lessons.length} lessons, ${ex} examples, ${xs} exercises`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  if (CHECK) check(process.argv.slice(3));
  else main();
}
