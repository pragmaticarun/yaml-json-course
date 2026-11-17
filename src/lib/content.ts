import fs from "fs";
import path from "path";
import type { Course } from "./types";

let cached: Course | null = null;

export function getCourse(): Course {
  if (cached) return cached;
  const file = path.join(process.cwd(), "content", "generated", "course.json");
  cached = JSON.parse(fs.readFileSync(file, "utf8")) as Course;
  return cached;
}

export function modulesOf(course: Course) {
  const modules = new Map<string, Course["lessons"]>();
  for (const lesson of course.lessons) {
    const list = modules.get(lesson.module) ?? [];
    list.push(lesson);
    modules.set(lesson.module, list);
  }
  return [...modules.entries()].map(([module, lessons]) => ({ module, lessons }));
}
