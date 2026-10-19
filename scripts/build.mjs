// Netlify build: copies only the website into dist/ and adds content.json for the iOS app.
// Keeps everything else in the repo (the app, scripts, unreleased audio) off the public site.
import { cpSync, mkdirSync, rmSync } from "node:fs";
import { execFileSync } from "node:child_process";

const SITE = ["index.html", "404.html", "css", "js", "audio"];
rmSync("dist", { recursive: true, force: true });
mkdirSync("dist");
for (const path of SITE) {
  try { cpSync(path, `dist/${path}`, { recursive: true }); } catch (e) { if (e.code !== "ENOENT") throw e; }
}
execFileSync("node", ["scripts/export-content.mjs", "dist/content.json"], { stdio: "inherit" });
