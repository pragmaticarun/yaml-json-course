import Link from "next/link";
import { getCourse, modulesOf } from "@/lib/content";

export default function HomePage() {
  const course = getCourse();
  const modules = modulesOf(course);
  const exampleCount = course.lessons.reduce((n, l) => n + l.examples.length, 0);
  const exerciseCount = course.lessons.reduce((n, l) => n + l.exercises.length, 0);
  const minutes = course.lessons.reduce((n, l) => n + l.minutes, 0);

  return (
    <div className="mx-auto max-w-5xl">
      <p className="text-[11px] uppercase tracking-[0.18em] text-[var(--muted)]">
        yaml {course.meta.yaml} · ajv {course.meta.ajv} · {course.meta.jq}
      </p>
      <h1 className="mt-2 max-w-3xl font-serif text-4xl leading-tight md:text-6xl">
        YAML and JSON, from the grammar up.
      </h1>
      <p className="mt-4 max-w-2xl text-lg leading-8 text-[var(--muted)]">
        Both formats describe the same tree of maps, lists, and scalars. Learn that tree, then
        the syntax, the traps (the Norway problem, octal ports, silent duplicate keys), jq,
        JSON Schema, and the config files you meet at work. Every example was run when the
        site was built and its real output is shown.
      </p>
      <dl className="mt-6 grid grid-cols-2 gap-3 md:grid-cols-4">
        {[
          ["Lessons", String(course.lessons.length)],
          ["Captured examples", String(exampleCount)],
          ["Exercises", String(exerciseCount)],
          ["Hours", (minutes / 60).toFixed(1)],
        ].map(([label, value]) => (
          <div key={label} className="rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-3">
            <dt className="text-[11px] uppercase tracking-wide text-[var(--muted)]">{label}</dt>
            <dd className="font-serif text-3xl">{value}</dd>
          </div>
        ))}
      </dl>
      <div className="mt-6 flex flex-wrap gap-3 text-sm">
        <Link
          className="rounded-md bg-[var(--accent)] px-3 py-2 text-[var(--accent-ink)]"
          href={`/lessons/${course.lessons[0].slug}`}
        >
          Start lesson 1
        </Link>
        <Link className="rounded-md border border-[var(--line)] px-3 py-2" href="/playground">
          Playground
        </Link>
        <Link className="rounded-md border border-[var(--line)] px-3 py-2" href="/cheatsheet">
          Cheat sheet
        </Link>
      </div>
      <section className="mt-10">
        <h2 className="font-serif text-3xl">How the course is arranged</h2>
        <div className="mt-4 grid gap-4 md:grid-cols-2">
          {modules.map(({ module, lessons }) => (
            <section key={module} className="rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-4">
              <h3 className="font-serif text-2xl">{module}</h3>
              <ol className="mt-2 space-y-1 text-sm">
                {lessons.map((lesson) => (
                  <li key={lesson.slug}>
                    <Link className="hover:underline" href={`/lessons/${lesson.slug}`}>
                      <span className="mr-2 font-mono text-[11px] text-[var(--muted)]">
                        {String(lesson.number).padStart(2, "0")}
                      </span>
                      {lesson.title}
                    </Link>
                  </li>
                ))}
              </ol>
            </section>
          ))}
        </div>
      </section>
      <section className="mt-10 max-w-3xl leading-7">
        <h2 className="font-serif text-3xl">How to use it</h2>
        <p className="mt-3">
          Read a lesson, run the examples in a clone of the repository (the helper commands are
          in <code>tools/bin</code>), then try the exercises before opening the hints. The
          playground runs the same YAML parser in your browser. Progress is kept in this
          browser only.
        </p>
      </section>
    </div>
  );
}
