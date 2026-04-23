import type {
  ParserServicesWithTypeInformation,
  TSESTree,
} from '@typescript-eslint/utils';
import { AST_NODE_TYPES, ESLintUtils } from '@typescript-eslint/utils';
import type { RuleContext } from '@typescript-eslint/utils/ts-eslint';
import { dirname, join, relative } from 'path';
import {
  isImportSpecifier,
  SymbolFlags,
  type Program,
  type SourceFile,
  type TypeChecker,
} from 'typescript';

// ── Rule factory ──────────────────────────────────────────────────────────────

/**
 * Shared `createRule` factory used by every rule in this plugin.
 *
 * `ESLintUtils.RuleCreator` takes a function that maps a rule name to its
 * documentation URL. By centralising it here we guarantee that all rules
 * point to the same docs base URL and we avoid repeating the three-line
 * boilerplate in every rule file.
 */
export const createRule = ESLintUtils.RuleCreator(
  (name) => `https://docs.zanshin.com/front-end/eslint/rules/${name}.md`,
);

// Maps @zanshin/<pkg> to their src/ paths (relative to app/src/).
// Keep this in sync with front-end/app/tsconfig.json path aliases.
export const ALIAS_TO_SRC_SUBPATH: Record<string, string> = {
  '@zanshin/api': 'api',
  '@zanshin/components': 'components',
  '@zanshin/fixtures': '__fixtures__',
  '@zanshin/providers': 'providers',
  '@zanshin/schemas': 'schemas',
  '@zanshin/types': 'types',
  '@zanshin/utils': 'utils',
};

// Extract the path up to and including the first directory after src/ (or src/zanshin/).
// e.g. /project/app/src/components/foo/bar.tsx → /project/app/src/components/
export function extractPathUpToFirstDirAfterSrc(
  inputPath: string,
): string | undefined {
  const regex = /^.*\/src\/(zanshin\/)?[^/]+/;
  const match = inputPath.match(regex);
  if (match !== null) {
    return match[0] + '/';
  }
  return undefined;
}

// Given an absolute path that lives somewhere under .../src/, return the
// package alias prefix e.g. "@zanshin/components" or "@zanshin/fetch".
// Returns undefined if the path does not land inside a known alias package.
export function getAliasForAbsolutePath(absPath: string): string | undefined {
  const srcMatch = absPath.match(/^(.*\/src)\//);
  if (!srcMatch) return undefined;
  const srcRoot = srcMatch[1];
  const relToSrc = relative(srcRoot, absPath);
  for (const [alias, srcSubpath] of Object.entries(ALIAS_TO_SRC_SUBPATH)) {
    if (relToSrc === srcSubpath || relToSrc.startsWith(srcSubpath + '/')) {
      return alias;
    }
  }
  return undefined;
}

// Given an absolute file path, return the alias prefix of the package it belongs to.
// e.g. /project/app/src/components/button.tsx → "@zanshin/components"
// Returns undefined for files directly in src/ (packageless, e.g. app_bar.tsx)
export function getPackageAliasForFile(filePath: string): string | undefined {
  return getAliasForAbsolutePath(dirname(filePath) + '/dummy');
}

// ── Parser services ───────────────────────────────────────────────────────────

/**
 * Attempt to obtain TypeScript parser services from the ESLint rule context.
 *
 * Both `no_path_escaping` and `use_relative_path_for_same_package` need the
 * TypeScript type-checker to classify import specifiers as types or values, but
 * they must still work when no TypeScript project is configured (e.g. in plain
 * JS projects or unit tests that do not boot a full TS compiler). This helper
 * encapsulates the try/catch so neither rule has to repeat the boilerplate.
 *
 * @param context - The ESLint rule context supplied to `create()`.
 * @returns The fully-typed parser services when a TypeScript program is
 *          available, or `null` to signal that the rule should fall back to
 *          syntax-only analysis.
 */
export function getOptionalParserServices(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  context: RuleContext<any, any>,
): ParserServicesWithTypeInformation | null {
  try {
    const raw = ESLintUtils.getParserServices(
      context as Parameters<typeof ESLintUtils.getParserServices>[0],
      true,
    );
    if (raw.program) return raw as ParserServicesWithTypeInformation;
  } catch {
    // No TypeScript project configured — fall back to syntactic analysis.
  }
  return null;
}

// ── Type classification ───────────────────────────────────────────────────────

export type SpecifierClassification = {
  name: string;
  isTypeOnly: boolean;
  localName: string;
  node:
    | TSESTree.ImportSpecifier
    | TSESTree.ImportDefaultSpecifier
    | TSESTree.ImportNamespaceSpecifier;
};

// Flags that belong ONLY to runtime values — symbols with any of these flags
// are definitively values and cannot be safely placed under `import type`.
//
// NOTE: SymbolFlags.Class and SymbolFlags.Enum are intentionally excluded.
// Classes and enums are DUAL-NATURED — they exist both as runtime values and
// as TypeScript types (you can use `MyClass` in a type position like `: MyClass`
// or `extends MyClass`). Marking a class import as `import type` is valid and
// correct when the class is only used in type positions in the current file.
export const PURE_VALUE_FLAGS =
  SymbolFlags.Function |
  SymbolFlags.Variable |
  SymbolFlags.ValueModule |
  SymbolFlags.BlockScopedVariable |
  SymbolFlags.FunctionScopedVariable |
  SymbolFlags.Method |
  SymbolFlags.GetAccessor |
  SymbolFlags.SetAccessor |
  SymbolFlags.Property;

// Kept for backwards compatibility with existing callers; same as PURE_VALUE_FLAGS.
export const VALUE_FLAGS = PURE_VALUE_FLAGS;

// Given a TypeScript program and a resolved absolute path to the target module,
// return a map of exported name → classification:
//   true  = pure type (interface, type alias) — safe under `import type`
//   false = pure value (function, variable)   — must NOT be under `import type`
//   null  = dual-natured (class, enum)         — can be under `import type` when only used as a type
export function getExportTypeMap(
  program: Program,
  checker: TypeChecker,
  resolvedAbsPath: string,
): Map<string, boolean | null> | null {
  const candidates = [
    resolvedAbsPath,
    resolvedAbsPath + '.ts',
    resolvedAbsPath + '.tsx',
    resolvedAbsPath + '.d.ts',
  ];
  let sourceFile: SourceFile | undefined;
  for (const candidate of candidates) {
    sourceFile = program.getSourceFile(candidate);
    if (sourceFile) break;
  }
  if (!sourceFile) return null;

  const moduleSymbol = checker.getSymbolAtLocation(sourceFile);
  if (!moduleSymbol) return null;

  const map = new Map<string, boolean | null>();
  for (const sym of checker.getExportsOfModule(moduleSymbol)) {
    let resolved = sym;
    if (sym.flags & SymbolFlags.Alias) {
      try {
        resolved = checker.getAliasedSymbol(sym);
      } catch {
        resolved = sym;
      }
    }
    const f = resolved.flags;
    let classification: boolean | null;
    if (f & PURE_VALUE_FLAGS) {
      classification = false; // pure value
    } else if (f & (SymbolFlags.Class | SymbolFlags.Enum)) {
      classification = null; // dual-natured
    } else {
      classification = true; // pure type
    }
    map.set(sym.name, classification);
  }
  return map;
}

// Classify every specifier in an import declaration as type-only or value.
// Priority:
//  1. Syntactic `import type { ... }` or `import { type Foo }` — always authoritative
//  2. TypeScript checker via the resolved target file path    — most accurate
//  3. TypeScript checker via the TS node map                 — fallback for alias imports
//  4. Unknown → assume value (false)
export function classifySpecifiers(
  importNode: TSESTree.ImportDeclaration,
  services: ParserServicesWithTypeInformation | null,
  resolvedTargetPath: string | null,
): SpecifierClassification[] {
  const checker = services?.program?.getTypeChecker() ?? null;

  let exportTypeMap: Map<string, boolean | null> | null = null;
  if (checker !== null && services !== null && resolvedTargetPath !== null) {
    exportTypeMap = getExportTypeMap(
      services.program,
      checker,
      resolvedTargetPath,
    );
  }

  return importNode.specifiers.map((spec) => {
    let isTypeOnly = false;

    if (importNode.importKind === 'type') {
      isTypeOnly = true;
    } else if (spec.type === 'ImportSpecifier' && spec.importKind === 'type') {
      isTypeOnly = true;
    } else if (spec.type === 'ImportSpecifier') {
      const importedName =
        spec.imported.type === 'Identifier'
          ? spec.imported.name
          : spec.imported.value;
      if (exportTypeMap !== null) {
        const fromMap = exportTypeMap.get(importedName);
        // true = pure type, null = dual (class/enum treated as non-type for path-fix purposes)
        if (fromMap === true) isTypeOnly = true;
      } else if (checker !== null && services !== null) {
        try {
          const tsNode = services.esTreeNodeToTSNodeMap.get(spec);
          if (tsNode && isImportSpecifier(tsNode)) {
            const symbol = checker.getSymbolAtLocation(tsNode.name);
            if (symbol) {
              let resolved = symbol;
              if (symbol.flags & SymbolFlags.Alias)
                resolved = checker.getAliasedSymbol(symbol);
              // Only mark as type-only for pure types (not dual-natured class/enum)
              isTypeOnly =
                (resolved.flags & PURE_VALUE_FLAGS) === 0 &&
                (resolved.flags & (SymbolFlags.Class | SymbolFlags.Enum)) === 0;
            }
          }
        } catch {
          // fall through
        }
      }
    }

    const name =
      spec.type === 'ImportSpecifier'
        ? spec.imported.type === 'Identifier'
          ? spec.imported.name
          : spec.imported.value
        : spec.type === 'ImportDefaultSpecifier'
        ? 'default'
        : '*';

    return { name, isTypeOnly, localName: spec.local.name, node: spec };
  });
}

// Build a complete import statement string from classifications + new path.
export function buildImportStatement(
  importNode: TSESTree.ImportDeclaration,
  newPath: string,
  classifications: SpecifierClassification[],
): string {
  const quote = importNode.source.raw[0];

  if (importNode.specifiers.length === 0) {
    return `import ${quote}${newPath}${quote}`;
  }

  const allTypeOnly =
    classifications.length > 0 && classifications.every((c) => c.isTypeOnly);
  const namedSpecs = classifications.filter(
    (c) => c.node.type === 'ImportSpecifier',
  );
  const defaultSpec = classifications.find(
    (c) => c.node.type === 'ImportDefaultSpecifier',
  );
  const namespaceSpec = classifications.find(
    (c) => c.node.type === 'ImportNamespaceSpecifier',
  );

  if (namespaceSpec) {
    const typeKw = allTypeOnly ? 'type ' : '';
    return `import ${typeKw}* as ${namespaceSpec.localName} from ${quote}${newPath}${quote}`;
  }

  const parts: string[] = [];
  if (defaultSpec) parts.push(defaultSpec.localName);
  if (namedSpecs.length > 0) {
    const specTexts = namedSpecs.map((c) => {
      const typePrefix = !allTypeOnly && c.isTypeOnly ? 'type ' : '';
      const alias = c.localName !== c.name ? ` as ${c.localName}` : '';
      return `${typePrefix}${c.name}${alias}`;
    });
    parts.push(`{ ${specTexts.join(', ')} }`);
  }

  const typeKw = allTypeOnly ? 'type ' : '';
  return `import ${typeKw}${parts.join(', ')} from ${quote}${newPath}${quote}`;
}

// The overrideFilename schema — shared by no-path-escaping and use-relative-path rules
// so they can be tested without real files on disk.
export const overrideFilenameSchema = {
  type: 'array' as const,
  minItems: 0,
  maxItems: 1,
  items: {
    type: 'object' as const,
    properties: { overrideFilename: { type: 'string' as const } },
    default: 'default',
    additionalProperties: false,
  },
};

export function resolveLintedFilename(
  context: { filename: string },
  opts: Array<{ overrideFilename?: string }>,
  dirname: string,
): string {
  const overrideFilename = opts[0]?.overrideFilename ?? 'default';
  if (overrideFilename !== 'default') {
    return join(dirname, '../../../app/src', overrideFilename);
  }
  return context.filename;
}
