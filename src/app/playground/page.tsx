"use client";

import { useMemo, useState } from "react";
import YAML from "yaml";
import { Button } from "@/components/ui/button";

type Version = "1.2" | "1.1";

const SAMPLES: Record<string, string> = {
  "Norway problem": "countries:\n  - GB\n  - NO\n  - SE\nenabled: yes\nport: 010\nversion: 3.10\n",
  "Anchors and merge": "base: &base\n  retries: 3\n  timeout: 30\nweb:\n  <<: *base\n  timeout: 60\n",
  "Multi-line text": "script: |\n  echo one\n  echo two\nnote: >\n  folded text\n  becomes one line\n",
  "Duplicate key": "name: first\nname: second\n",
};

function convert(text: string, version: Version) {
  const docs = YAML.parseAllDocuments(text, { version, merge: version === "1.1" });
  const list = Array.isArray(docs) ? docs : [docs];
  const messages: string[] = [];
  for (const doc of list) {
    for (const e of doc.errors) {
      const pos = e.linePos?.[0];
      messages.push(`${pos ? `line ${pos.line}, col ${pos.col}: ` : ""}${e.code}: ${e.message.split("\n")[0]}`);
    }
  }
  if (messages.length) return { json: "", messages };
  try {
    const values = list.map((d) => d.toJS());
    return { json: JSON.stringify(values.length === 1 ? values[0] : values, null, 2), messages };
  } catch (err) {
    return { json: "", messages: [(err as Error).message] };
  }
}

export default function PlaygroundPage() {
  const [text, setText] = useState(SAMPLES["Norway problem"]);
  const [version, setVersion] = useState<Version>("1.2");
  const result = useMemo(() => convert(text, version), [text, version]);

  return (
    <div className="mx-auto max-w-5xl">
      <h1 className="font-serif text-4xl">Playground</h1>
      <p className="mt-3 max-w-3xl leading-7 text-[var(--muted)]">
        Type YAML on the left and read the JSON tree a parser builds from it. Switch the
        version to see how YAML 1.1 rules change the same text. This runs the{" "}
        <code>yaml</code> npm package in your browser; nothing is sent anywhere.
      </p>
      <div className="mt-4 flex flex-wrap items-center gap-2 text-sm">
        {Object.keys(SAMPLES).map((name) => (
          <Button key={name} variant="secondary" size="sm" type="button" onClick={() => setText(SAMPLES[name])}>
            {name}
          </Button>
        ))}
        <fieldset className="ml-auto flex items-center gap-3">
          <legend className="sr-only">YAML version</legend>
          {(["1.2", "1.1"] as Version[]).map((v) => (
            <label key={v} className="flex items-center gap-1">
              <input type="radio" name="version" checked={version === v} onChange={() => setVersion(v)} />
              YAML {v}
            </label>
          ))}
        </fieldset>
      </div>
      <div className="mt-4 grid gap-4 md:grid-cols-2">
        <div>
          <label htmlFor="yaml-in" className="text-[11px] uppercase tracking-wider text-[var(--muted)]">
            YAML
          </label>
          <textarea
            id="yaml-in"
            value={text}
            onChange={(event) => setText(event.target.value)}
            spellCheck={false}
            className="mt-1 h-80 w-full rounded-md border border-[var(--line)] bg-[var(--code-bg)] p-3 font-mono text-[13px] leading-relaxed text-[var(--code-ink)]"
          />
        </div>
        <div>
          <p className="text-[11px] uppercase tracking-wider text-[var(--muted)]">JSON</p>
          <pre
            aria-live="polite"
            className="mt-1 h-80 overflow-auto rounded-md border border-[var(--line)] bg-[var(--code-bg)] p-3 text-[13px] leading-relaxed text-[var(--code-ink)]"
          >
            {result.messages.length ? result.messages.join("\n") : result.json}
          </pre>
        </div>
      </div>
    </div>
  );
}
