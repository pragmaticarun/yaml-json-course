#!/usr/bin/env node
// Structural checks on the generated course. Does not re-run examples (the
// build host's tool versions would differ from the captured ones); it checks
// that the captures are current for the sources, and that the content is sound.

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { sourceHash } from "./assemble.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const problems = [];
const bad = (msg) => problems.push(msg);

const courseFile = path.join(ROOT, "content", "generated", "course.json");
if (!fs.existsSync(courseFile)) {
  console.error("content/generated/course.json is missing; run `npm run generate`");
  process.exit(1);
}
const course = JSON.parse(fs.readFileSync(courseFile, "utf8"));

if (course.meta.sourceHash !== sourceHash()) {
  bad("generated course.json is stale: lessons or tools/bin changed since `npm run generate`");
}

const slugs = new Set(course.lessons.map((l) => l.slug));
const pages = new Set(["playground", "cheatsheet", "progress", "about"]);
const URL_RE = /^https:\/\/[^\s]+$/;

for (const lesson of course.lessons) {
  const where = `lesson ${lesson.number} (${lesson.slug})`;
  if (lesson.examples.length < 2) bad(`${where}: needs at least 2 captured examples`);
  if (lesson.exercises.length < 1) bad(`${where}: needs at least 1 exercise`);
  if (lesson.objectives.length < 2) bad(`${where}: needs at least 2 objectives`);
  if (!lesson.summary || lesson.summary.length > 220) bad(`${where}: summary missing or over 220 chars`);
  for (const f of lesson.further) if (!URL_RE.test(f.url)) bad(`${where}: bad further-reading URL ${f.url}`);
  const prose = lesson.markdown.replace(/```[\s\S]*?```/g, "");
  for (const m of prose.matchAll(/\]\((\/[^)\s#]*)/g)) {
    const target = m[1].replace(/^\//, "").replace(/\/$/, "");
    if (target.startsWith("lessons/")) {
      if (!slugs.has(target.slice(8))) bad(`${where}: link to unknown lesson ${m[1]}`);
    } else if (!pages.has(target)) bad(`${where}: link to unknown page ${m[1]}`);
  }
  for (const ex of lesson.examples) {
    const file = path.join(ROOT, "public", ex.download);
    if (!fs.existsSync(file)) bad(`${where}: missing download ${ex.download}`);
  }
}

const index = path.join(ROOT, "public", "search-index.json");
if (!fs.existsSync(index)) bad("public/search-index.json is missing");
else if (JSON.parse(fs.readFileSync(index, "utf8")).length !== course.lessons.length) bad("search index is out of date");

if (problems.length) {
  console.error(problems.map((p) => `- ${p}`).join("\n"));
  process.exit(1);
}
console.log(`ok: ${course.lessons.length} lessons, ${course.lessons.reduce((n, l) => n + l.examples.length, 0)} examples`);
