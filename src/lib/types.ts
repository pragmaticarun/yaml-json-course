export type Link = { title: string; url: string };

export type CapturedExample = {
  id: string;
  title: string;
  script: string;
  stdout: string;
  stderr: string;
  exitCode: number;
  download: string;
  truncated: boolean;
};

export type CapturedExercise = {
  id: string;
  title: string;
  prompt: string;
  hint: string;
  hint2?: string;
  solution: string;
  script: string;
  stdout: string;
  stderr: string;
  exitCode: number;
  download: string;
};

export type Heading = { level: number; id: string; text: string };

export type Lesson = {
  slug: string;
  number: number;
  title: string;
  module: string;
  level: "beginner" | "intermediate" | "advanced";
  minutes: number;
  summary: string;
  objectives: string[];
  further: Link[];
  pitfall: string;
  markdown: string;
  headings: Heading[];
  examples: CapturedExample[];
  exercises: CapturedExercise[];
  wordCount: number;
};

export type CourseMeta = {
  title: string;
  sourceHash: string;
  node: string;
  yaml: string;
  ajv: string;
  jq: string;
  python: string;
  bash: string;
  uname: string;
};

export type Course = { meta: CourseMeta; lessons: Lesson[] };
