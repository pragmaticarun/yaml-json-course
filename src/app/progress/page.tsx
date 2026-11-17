"use client";

import Link from "next/link";
import { Button } from "@/components/ui/button";
import { useProgress } from "@/components/progress";
import { useEffect, useState } from "react";
import { withBase } from "@/lib/utils";

type Row = { slug: string; title: string; number: number; module: string };

export default function ProgressPage() {
  const { done, toggle, clear, ready } = useProgress();
  const [rows, setRows] = useState<Row[]>([]);
  const [state, setState] = useState<"loading" | "ready" | "error">("loading");

  useEffect(() => {
    fetch(withBase("/search-index.json"))
      .then((response) => {
        if (!response.ok) throw new Error(String(response.status));
        return response.json();
      })
      .then((items: (Row & { kind: string })[]) => {
        setRows(
          items
            .filter((item) => item.kind === "lesson")
            .map(({ slug, title, number, module }) => ({ slug, title, number, module }))
            .sort((a, b) => a.number - b.number),
        );
        setState("ready");
      })
      .catch(() => setState("error"));
  }, []);

  const finished = rows.filter((row) => done.has(row.slug)).length;

  return (
    <div className="mx-auto max-w-3xl">
      <h1 className="font-serif text-4xl">Progress stays in this browser</h1>
      <p className="mt-3 leading-7">
        Completion is stored in <code>localStorage</code> under <code>yaml-json-course-v1</code>.
        Nothing is sent to a server. Clearing site data, or opening another browser, starts the
        list over.
      </p>
      <p className="mt-3 font-mono text-sm">
        {ready ? `${finished} / ${rows.length || "—"} lessons marked` : "Loading local progress"}
      </p>
      <div className="mt-3">
        <Button variant="secondary" type="button" onClick={clear}>
          Clear local progress
        </Button>
      </div>
      {state === "loading" ? (
        <p className="mt-6 text-sm text-[var(--muted)]">Loading the lesson index.</p>
      ) : state === "error" ? (
        <p className="mt-6 text-sm text-[var(--muted)]">
          The lesson index could not be loaded. Refresh the page. Progress already stored in this
          browser is unchanged.
        </p>
      ) : (
        <ul className="mt-6 space-y-2">
          {rows.map((row) => (
            <li
              key={row.slug}
              className="flex items-center gap-3 rounded-lg border border-[var(--line)] bg-[var(--bg-elev)] px-3 py-2"
            >
              <input
                type="checkbox"
                checked={done.has(row.slug)}
                onChange={() => toggle(row.slug)}
                aria-label={`Mark ${row.title} complete`}
              />
              <Link href={`/lessons/${row.slug}`} className="hover:underline">
                {row.title}
              </Link>
              <span className="ml-auto text-xs text-[var(--muted)]">{row.module}</span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
