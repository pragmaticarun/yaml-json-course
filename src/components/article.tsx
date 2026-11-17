import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { MarkdownView } from "@/components/markdown-view";
import { LessonActions } from "@/components/lesson-actions";
import type { Lesson } from "@/lib/types";

export function Article({
  lesson,
  prev,
  next,
}: {
  lesson: Lesson;
  prev: Lesson | null;
  next: Lesson | null;
}) {
  return (
    <article className="mx-auto max-w-3xl">
      <p className="text-[11px] uppercase tracking-[0.16em] text-[var(--muted)]">
        {lesson.module} · {lesson.level} · {lesson.minutes} min
      </p>
      <h1 className="mt-2 font-serif text-4xl leading-tight md:text-5xl">{lesson.title}</h1>
      <p className="mt-4 text-lg leading-8 text-[var(--muted)]">{lesson.summary}</p>
      <div className="mt-4 flex flex-wrap gap-2">
        <Badge>{lesson.examples.length} captured examples</Badge>
        <Badge>{lesson.exercises.length} exercises</Badge>
      </div>
      {lesson.objectives.length > 0 ? (
        <section className="mt-6 rounded-xl border border-[var(--line)] bg-[var(--bg-elev)] p-4">
          <h2 className="font-serif text-2xl">Objectives</h2>
          <ul className="mt-2 list-disc space-y-1 pl-5">
            {lesson.objectives.map((objective) => (
              <li key={objective}>{objective}</li>
            ))}
          </ul>
        </section>
      ) : null}
      <p className="mt-4 text-sm leading-6 text-[var(--muted)]">
        Each example ran in an empty scratch directory when the site was built. The stdout,
        stderr, and exit status shown are what came back, not what the author expected.
      </p>
      <div className="mt-6 lg:grid lg:grid-cols-[minmax(0,1fr)_180px] lg:gap-8">
        <MarkdownView markdown={lesson.markdown} />
        <aside className="mb-6 lg:sticky lg:top-20 lg:mb-0 lg:self-start">
          <p className="text-[11px] uppercase tracking-wider text-[var(--muted)]">On this page</p>
          <ul className="mt-2 space-y-1 text-sm">
            {lesson.headings
              .filter((heading) => heading.level === 2)
              .map((heading) => (
                <li key={heading.id}>
                  <a className="text-[var(--muted)] hover:text-[var(--ink)]" href={`#${heading.id}`}>
                    {heading.text}
                  </a>
                </li>
              ))}
          </ul>
        </aside>
      </div>
      {lesson.pitfall ? (
        <section className="mt-8 rounded-xl border border-[var(--line)] bg-[var(--bg-muted)] p-4">
          <h2 className="font-serif text-2xl">Watch for</h2>
          <p className="mt-2 whitespace-pre-wrap leading-7">{lesson.pitfall}</p>
        </section>
      ) : null}
      {lesson.further.length > 0 ? (
        <section className="mt-4">
          <h2 className="font-serif text-2xl">Further reading</h2>
          <ul className="mt-2 space-y-1">
            {lesson.further.map((item) => (
              <li key={item.url}>
                <a
                  className="text-[var(--accent)] underline underline-offset-2"
                  href={item.url}
                  rel="noreferrer"
                  target="_blank"
                >
                  {item.title}
                </a>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
      <div className="mt-6">
        <LessonActions slug={lesson.slug} />
      </div>
      <div className="mt-8 flex justify-between gap-3 text-sm">
        {prev ? (
          <Link href={`/lessons/${prev.slug}`} className="hover:underline">
            ← {prev.title}
          </Link>
        ) : (
          <span />
        )}
        {next ? (
          <Link href={`/lessons/${next.slug}`} className="hover:underline">
            {next.title} →
          </Link>
        ) : null}
      </div>
    </article>
  );
}
