import { getCourse } from "@/lib/content";

export const metadata = { title: "About this course" };

export default function AboutPage() {
  const { meta } = getCourse();
  return (
    <div className="mx-auto max-w-3xl leading-7">
      <h1 className="font-serif text-4xl">About this course</h1>
      <p className="mt-3">
        Every example on the lesson pages was run by the site build in an empty scratch
        directory. The build stops if an example exits with a different status than the lesson
        declares, so the output you read is what the tool printed.
      </p>
      <h2 className="mt-8 font-serif text-3xl">Versions used</h2>
      <dl className="mt-3 grid grid-cols-[10rem_1fr] gap-y-1 text-sm">
        {[
          ["yaml (npm)", meta.yaml],
          ["Ajv (npm)", meta.ajv],
          ["jq", meta.jq],
          ["Node.js", meta.node],
          ["Python", meta.python],
          ["Bash", meta.bash],
          ["Build host", meta.uname],
        ].map(([k, v]) => (
          <div key={k} className="contents">
            <dt className="text-[var(--muted)]">{k}</dt>
            <dd className="font-mono">{v}</dd>
          </div>
        ))}
      </dl>
      <h2 className="mt-8 font-serif text-3xl">The helper commands</h2>
      <p className="mt-3">
        <code>yaml2json</code>, <code>json2yaml</code>, <code>yamlcheck</code>, and{" "}
        <code>schema-check</code> live in <code>tools/bin</code>. Each wraps one library, so a
        lesson that says &ldquo;the parser rejects this&rdquo; is describing that library, not
        every YAML implementation. Where a lesson makes a claim about another implementation
        (for example PyYAML&rsquo;s YAML 1.1 behaviour), it is marked as documented fact and was
        not executed here.
      </p>
      <h2 className="mt-8 font-serif text-3xl">Limits</h2>
      <ul className="mt-3 list-disc space-y-1 pl-5">
        <li>Output comes from one machine and one set of versions. Other versions may differ.</li>
        <li>Only the <code>yaml</code> package was used as a YAML parser, in 1.2 and 1.1 modes.</li>
        <li>Progress and theme are stored in your browser and never leave it.</li>
      </ul>
    </div>
  );
}
