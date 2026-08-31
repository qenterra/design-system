import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import process from "node:process";

const packageRoot = resolve(process.argv[2] ?? "");
if (!process.argv[2]) {
  throw new Error("Usage: node tests/package-css-smoke.mjs PACKAGE_ROOT");
}

const packageJson = JSON.parse(await readFile(resolve(packageRoot, "package.json"), "utf8"));
const declaredFiles = new Set(packageJson.files ?? []);
const requiredFiles = [
  "LICENSE",
  "README.md",
  "dist/icons.json",
  "dist/recipes.css",
  "dist/tokens.css",
  "dist/tokens.json",
];

for (const filename of requiredFiles) {
  if (!declaredFiles.has(filename) && !declaredFiles.has(filename.split("/")[0])) {
    throw new Error(`Package file is not declared: ${filename}`);
  }
  await readFile(resolve(packageRoot, filename));
}

for (const target of Object.values(packageJson.exports ?? {})) {
  await readFile(resolve(packageRoot, target));
}

const tokens = JSON.parse(await readFile(resolve(packageRoot, "dist/tokens.json"), "utf8"));
const tokenFamilies = Object.entries(tokens);
if (tokenFamilies.length === 0) {
  throw new Error("tokens.json has no token families");
}
for (const [name, family] of tokenFamilies) {
  if (family?.meta?.version !== packageJson.version) {
    throw new Error(`${name} token version does not match package version`);
  }
}

const icons = JSON.parse(await readFile(resolve(packageRoot, "dist/icons.json"), "utf8"));
if (icons.version !== packageJson.version || !Array.isArray(icons.icons) || icons.icons.length === 0) {
  throw new Error("icons.json is missing matching versioned icon metadata");
}

console.log(`CSS package smoke check passed for ${packageJson.name}@${packageJson.version}`);
