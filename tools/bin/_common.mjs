// Shared helpers for the course CLIs. Each CLI is a thin wrapper around a
// published library so the lessons show that library's real behaviour.
import fs from "node:fs";

export function readInput(path) {
  try {
    if (!path || path === "-") return { name: "<stdin>", text: fs.readFileSync(0, "utf8") };
    return { name: path, text: fs.readFileSync(path, "utf8") };
  } catch (err) {
    process.stderr.write(`${path}: ${err.code === "ENOENT" ? "no such file" : err.message}\n`);
    process.exit(2);
  }
}

export function parseArgs(argv, flags) {
  const opts = {};
  const rest = [];
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg in flags) {
      if (flags[arg] === "value") opts[arg] = argv[++i];
      else opts[arg] = true;
    } else if (arg.startsWith("-") && arg !== "-") {
      process.stderr.write(`unknown option ${arg}\n`);
      process.exit(2);
    } else rest.push(arg);
  }
  return { opts, rest };
}

export function formatYamlError(name, err) {
  const pos = err.linePos?.[0];
  const where = pos ? `${name}:${pos.line}:${pos.col}` : name;
  const first = String(err.message).split("\n")[0].replace(/ at line \d+, column \d+:?$/, "");
  return `${where}: ${err.code ?? "error"}: ${first}`;
}
