// Turns js/data.js (the one file you edit) into content.json, which the iOS app reads.
// Runs automatically on every Netlify deploy (see netlify.toml).
// Usage: node scripts/export-content.mjs [output paths...]   (default: content.json)
import { readFileSync, writeFileSync } from "node:fs";
import vm from "node:vm";

const sandbox = { window: {} };
vm.runInNewContext(readFileSync(new URL("../js/data.js", import.meta.url), "utf8"), sandbox);
const data = sandbox.window.ANNEALER;
if (!data || !Array.isArray(data.phases)) throw new Error("js/data.js did not define window.ANNEALER");

const json = JSON.stringify({ exportedAt: new Date().toISOString(), ...data }, null, 2) + "\n";
const outputs = process.argv.slice(2);
for (const out of outputs.length ? outputs : ["content.json"]) {
  writeFileSync(out, json);
  console.log("wrote", out);
}
