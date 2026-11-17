export const metadata = { title: "Cheat sheet" };

const ROWS: [string, string, string][] = [
  ["Mapping", '{"a": 1}', "a: 1"],
  ["Sequence", "[1, 2]", "- 1\n- 2"],
  ["String", '"hi"', "hi  (or \"hi\", 'hi')"],
  ["Number", "8080", "8080"],
  ["Boolean", "true / false", "true / false  (quote yes, no, on, off)"],
  ["Null", "null", "null  (also ~ or empty)"],
  ["Comment", "not allowed", "# to end of line"],
  ["Multi-line text", '"a\\nb"', "|  keeps newlines,  >  folds them"],
  ["Reuse", "not available", "&name to define, *name to reuse"],
  ["Several documents", "one value per file", "separate with ---"],
];

export default function CheatSheetPage() {
  return (
    <div className="mx-auto max-w-4xl">
      <h1 className="font-serif text-4xl">Cheat sheet</h1>
      <p className="mt-3 leading-7 text-[var(--muted)]">
        The same ideas in both notations. Lessons 1 to 14 explain and demonstrate each row.
      </p>
      <div className="mt-6 overflow-x-auto">
        <table className="w-full border-collapse text-sm">
          <thead>
            <tr>
              {["Idea", "JSON", "YAML"].map((h) => (
                <th key={h} className="border border-[var(--line)] bg-[var(--bg-muted)] px-2 py-1 text-left font-medium">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {ROWS.map(([idea, json, yaml]) => (
              <tr key={idea}>
                <th scope="row" className="border border-[var(--line)] px-2 py-1 text-left font-medium align-top">
                  {idea}
                </th>
                <td className="border border-[var(--line)] px-2 py-1 align-top">
                  <pre className="whitespace-pre-wrap font-mono text-[13px]">{json}</pre>
                </td>
                <td className="border border-[var(--line)] px-2 py-1 align-top">
                  <pre className="whitespace-pre-wrap font-mono text-[13px]">{yaml}</pre>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <h2 className="mt-10 font-serif text-3xl">Values that surprise people</h2>
      <ul className="mt-3 list-disc space-y-1 pl-5 leading-7">
        <li>YAML 1.1 loaders read <code>no</code>, <code>yes</code>, <code>on</code>, <code>off</code> as booleans. YAML 1.2 does not.</li>
        <li>A leading zero such as <code>010</code> is octal in YAML 1.1 and decimal 10 in YAML 1.2.</li>
        <li><code>3.10</code> is the number 3.1. Quote version strings.</li>
        <li>JSON numbers have no size limit in the grammar, but JavaScript reads them as doubles.</li>
        <li>Duplicate keys: JSON parsers usually keep the last one silently; many YAML parsers reject them.</li>
      </ul>
    </div>
  );
}
