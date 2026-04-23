import { Project, type SourceFile } from "ts-morph";
import { relative, resolve } from "node:path";

type Mode = "check" | "write";

function parseMode(): Mode {
  const modeArg = Bun.argv[2];
  if (modeArg === "check" || modeArg === "write") return modeArg;
  return "check";
}

function parsePatterns(): string[] {
  const patterns = Bun.argv.slice(3);
  if (patterns.length > 0) return patterns;
  return ["app/**/*.ts", "app/**/*.tsx", "tests/**/*.ts", "tests/**/*.tsx", ".storybook/**/*.ts"];
}

async function loadFiles(project: Project, patterns: string[]): Promise<SourceFile[]> {
  const seen = new Set<string>();
  for (const pattern of patterns) {
    for await (const file of new Bun.Glob(pattern).scan(".")) {
      if (file.includes("node_modules/") || file.includes("build/") || file.includes("public/build/")) continue;
      seen.add(file);
    }
  }

  return Array.from(seen).map((file) => project.addSourceFileAtPath(resolve(file)));
}

function normalizeImportsText(sourceFile: SourceFile): string {
  return sourceFile
    .getImportDeclarations()
    .map((decl) => decl.getText())
    .join("\n")
    .replace(/\s+/g, " ");
}

async function main() {
  const mode = parseMode();
  const patterns = parsePatterns();
  const project = new Project({ tsConfigFilePath: "tsconfig.json" });
  const sourceFiles = await loadFiles(project, patterns);

  const changedFiles: string[] = [];

  for (const sourceFile of sourceFiles) {
    if (sourceFile.getFullText().includes("organize-imports-ignore")) continue;

    const before = normalizeImportsText(sourceFile);
    sourceFile.organizeImports();
    const after = normalizeImportsText(sourceFile);
    if (before !== after) changedFiles.push(relative(process.cwd(), sourceFile.getFilePath()));
  }

  if (mode === "check") {
    if (changedFiles.length === 0) {
      console.log("Imports are organized.");
      return;
    }
    for (const file of changedFiles) console.log(file);
    process.exit(2);
  }

  if (changedFiles.length > 0) {
    await project.save();
  }
  console.log(changedFiles.length === 0 ? "No import changes needed." : `Organized imports in ${changedFiles.length} files.`);
}

await main();
