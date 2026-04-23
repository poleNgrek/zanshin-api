import { AST_NODE_TYPES } from '@typescript-eslint/utils';
import { TSESTree } from '@typescript-eslint/utils';
import type { RuleFix } from '@typescript-eslint/utils/ts-eslint';
import { createRule } from './utils';

const REACT_PACKAGES = ['react', 'react-dom'];

/**
 * Given a TSQualifiedName that starts with a React namespace identifier, extract:
 *   - importName:      the top-level name to import from 'react'
 *                      React.ReactNode      → 'ReactNode'
 *                      React.JSX.Element    → 'JSX'
 *   - replacementText: what to write at the use site after stripping the root namespace
 *                      React.ReactNode      → 'ReactNode'
 *                      React.JSX.Element    → 'JSX.Element'
 *   - replaceRange:    the source range to replace (from the start of the root identifier
 *                      to the end of the whole qualified name)
 *
 * Returns null if the root identifier is not the expected namespace name.
 */
function extractReactNamespaceUsage(
  typeName: TSESTree.TSQualifiedName,
  rootName: string
): { importName: string; replacementText: string; replaceRange: [number, number] } | null {
  // Depth-1: React.Foo
  // typeName = TSQualifiedName { left: Identifier("React"), right: Identifier("Foo") }
  if (
    typeName.left.type === AST_NODE_TYPES.Identifier &&
    typeName.left.name === rootName &&
    typeName.right.type === AST_NODE_TYPES.Identifier
  ) {
    const importName = typeName.right.name;
    return {
      importName,
      replacementText: importName,
      replaceRange: [typeName.left.range[0], typeName.right.range[1]]
    };
  }

  // Depth-2: React.JSX.Element
  // typeName = TSQualifiedName {
  //   left: TSQualifiedName { left: Identifier("React"), right: Identifier("JSX") },
  //   right: Identifier("Element")
  // }
  if (
    typeName.left.type === 'TSQualifiedName' &&
    typeName.left.left.type === AST_NODE_TYPES.Identifier &&
    typeName.left.left.name === rootName &&
    typeName.left.right.type === AST_NODE_TYPES.Identifier &&
    typeName.right.type === AST_NODE_TYPES.Identifier
  ) {
    const subNamespace = typeName.left.right.name; // 'JSX'
    const member = typeName.right.name; // 'Element'
    return {
      importName: subNamespace,
      replacementText: `${subNamespace}.${member}`,
      replaceRange: [typeName.left.left.range[0], typeName.right.range[1]]
    };
  }

  return null;
}

/**
 * This ESLint rule enforces named imports for **React** and **ReactDOM**.
 *
 * ❌ **Bad:**
 *   import React from 'react';
 *   const [count, setCount] = React.useState(0);
 *   children?: React.ReactNode;
 *
 * ✅ **Good:**
 *   import { useState } from 'react';
 *   import type { ReactNode } from 'react';
 *   const [count, setCount] = useState(0);
 *   children?: ReactNode;
 */
export const enforceNamedReactPackagesImports = createRule({
  name: 'enforce-named-react-packages-imports',
  meta: {
    type: 'problem',
    docs: {
      description:
        'Enforce named imports for React and ReactDOM instead of default imports or namespace type references'
    },
    fixable: 'code',
    schema: [],
    messages: {
      useNamedImport: 'Use named imports for React and ReactDOM instead of default import.',
      noNamespaceType:
        "Use a named import instead of the React namespace type: replace 'React.{{ typeName }}' with '{{ typeName }}' and import it from 'react'."
    }
  },
  defaultOptions: [],
  create(context) {
    /** All import declarations for each React package */
    const allImportNodes = new Map<string, TSESTree.ImportDeclaration[]>();

    /** Imports that have a default specifier */
    const defaultImportNodes = new Map<string, { node: TSESTree.ImportDeclaration; localName: string }>();

    /**
     * Runtime members accessed via default import: React.useState → 'useState'
     * These become value imports.
     */
    const runtimeMembers = new Map<string, Set<string>>();

    /**
     * Type members accessed via the React namespace in type positions: React.ReactNode
     * These become type imports (or are merged into the existing named import).
     * Key: localName of the default import (e.g. 'React'), value: set of type names.
     */
    const typeNamespaceUsages = new Map<string, Set<string>>();

    /**
     * Bare React.Foo / React.JSX.Element usages in type positions with NO corresponding
     * default import. Reported separately with `noNamespaceType`.
     */
    const bareTypeUsages: {
      typeName: string; // what to import: 'ReactNode', 'JSX', ...
      replacementText: string; // what to write at the use site: 'ReactNode', 'JSX.Element', ...
      replaceRange: [number, number]; // range to replace in the source
      memberNode: TSESTree.TSQualifiedName;
      parent: TSESTree.TSTypeReference;
    }[] = [];

    REACT_PACKAGES.forEach((pkg) => {
      runtimeMembers.set(pkg, new Set<string>());
      allImportNodes.set(pkg, []);
    });

    return {
      ImportDeclaration(node) {
        const sourceValue = node.source.value;
        if (!REACT_PACKAGES.includes(sourceValue)) return;

        allImportNodes.get(sourceValue)?.push(node);

        const defaultImport = node.specifiers.find(
          (s): s is TSESTree.ImportDefaultSpecifier => s.type === AST_NODE_TYPES.ImportDefaultSpecifier
        );
        if (defaultImport) {
          defaultImportNodes.set(sourceValue, { node, localName: defaultImport.local.name });
          typeNamespaceUsages.set(defaultImport.local.name, new Set());
        }
      },

      /** Runtime member expressions: React.useState(0) */
      MemberExpression(node) {
        if (
          node.object.type === AST_NODE_TYPES.Identifier &&
          node.property.type === AST_NODE_TYPES.Identifier
        ) {
          for (const [pkg, { localName }] of defaultImportNodes.entries()) {
            if (node.object.name === localName) {
              runtimeMembers.get(pkg)?.add(node.property.name);
            }
          }
        }
      },

      /**
       * Type-position namespace usage: React.ReactNode, React.JSX.Element, etc.
       *
       * Handles both depth-1 (React.Foo) and depth-2 (React.JSX.Element).
       */
      TSTypeReference(node) {
        const typeName = node.typeName;
        if (typeName.type !== 'TSQualifiedName') return;

        // Try to extract a React namespace usage at depth-1 or depth-2
        // We need to find which root name to check against.
        // First, get the leftmost identifier to see if this is rooted at a known namespace.
        function getLeftmostIdentifier(qn: TSESTree.TSQualifiedName): TSESTree.Identifier | null {
          if (qn.left.type === AST_NODE_TYPES.Identifier) return qn.left;
          if (qn.left.type === 'TSQualifiedName') return getLeftmostIdentifier(qn.left);
          return null;
        }

        const leftmost = getLeftmostIdentifier(typeName);
        if (!leftmost) return;
        const rootName = leftmost.name;

        // Check if this matches a known default-import local name (e.g. 'React')
        if (typeNamespaceUsages.has(rootName)) {
          const usage = extractReactNamespaceUsage(typeName, rootName);
          if (usage) typeNamespaceUsages.get(rootName)!.add(usage.importName);
          return;
        }

        // No default import — bare React.Foo / React.JSX.Element type usage
        if (rootName === 'React') {
          const usage = extractReactNamespaceUsage(typeName, rootName);
          if (!usage) return;

          // Deduplicate by source range
          const alreadySeen = bareTypeUsages.some(
            (u) => u.replaceRange[0] === usage.replaceRange[0] && u.replaceRange[1] === usage.replaceRange[1]
          );
          if (!alreadySeen) {
            bareTypeUsages.push({
              typeName: usage.importName,
              replacementText: usage.replacementText,
              replaceRange: usage.replaceRange,
              memberNode: typeName,
              parent: node
            });
          }
        }
      },

      'Program:exit'() {
        const sourceCode = context.sourceCode;

        // ── Part 1: Handle default imports ────────────────────────────────────
        // (existing behaviour + now also handles type namespace usages)

        const allFixes: { range: [number, number]; text: string }[] = [];
        const importFixes: { nodes: TSESTree.ImportDeclaration[]; text: string; pkg: string }[] = [];

        for (const [pkg, { node: _defaultImportNode, localName }] of defaultImportNodes.entries()) {
          const allNodes = allImportNodes.get(pkg) ?? [];

          // Collect existing named imports, tracking which are already marked `type`
          const existingValueImports = new Set<string>();
          const existingTypeImports = new Set<string>();
          for (const importNode of allNodes) {
            const declIsTypeOnly = importNode.importKind === 'type';
            for (const spec of importNode.specifiers) {
              if (spec.type === AST_NODE_TYPES.ImportSpecifier) {
                const name =
                  spec.imported.type === AST_NODE_TYPES.Identifier ? spec.imported.name : spec.imported.value;
                if (declIsTypeOnly || spec.importKind === 'type') {
                  existingTypeImports.add(name);
                } else {
                  existingValueImports.add(name);
                }
              }
            }
          }

          // Runtime members accessed via default import → values
          const runtimeSet = runtimeMembers.get(pkg) ?? new Set<string>();
          runtimeSet.forEach((n) => existingValueImports.add(n));

          // Type members from the React namespace (React.ReactNode etc.) → type-only
          const typeSet = typeNamespaceUsages.get(localName) ?? new Set<string>();
          // A name is type-only if it is only ever used as a type and not as a value
          typeSet.forEach((n) => {
            if (!existingValueImports.has(n)) existingTypeImports.add(n);
          });

          // Build the import statement
          const allValueNames = Array.from(existingValueImports).sort();
          const allTypeNames = Array.from(existingTypeImports).sort();
          const allNames = [...allValueNames, ...allTypeNames];

          let newImport = '';
          if (allNames.length > 0) {
            if (allValueNames.length === 0) {
              // All imports are types → `import type { ... }`
              newImport = `import type { ${allTypeNames.join(', ')} } from '${pkg}';`;
            } else if (allTypeNames.length === 0) {
              // All imports are values → plain `import { ... }`
              newImport = `import { ${allValueNames.join(', ')} } from '${pkg}';`;
            } else {
              // Mixed → `import { TypeA, TypeB, valueA, valueB }` with inline `type` on type-only
              const specParts = [...allValueNames, ...allTypeNames.map((n) => `type ${n}`)].sort((a, b) =>
                a.replace(/^type /, '').localeCompare(b.replace(/^type /, ''))
              );
              newImport = `import { ${specParts.join(', ')} } from '${pkg}';`;
            }
          }

          importFixes.push({ nodes: allNodes, text: newImport, pkg });

          // Walk AST for all React.xxx / React.JSX.Element usages (runtime and type positions)
          function walk(node: TSESTree.Node): void {
            // Runtime: React.useState(0) — MemberExpression
            if (
              node.type === AST_NODE_TYPES.MemberExpression &&
              node.object.type === AST_NODE_TYPES.Identifier &&
              node.property.type === AST_NODE_TYPES.Identifier &&
              node.object.name === localName
            ) {
              allFixes.push({
                range: [node.object.range[0], node.property.range[1]],
                text: node.property.name
              });
              // Don't recurse — children are already covered
              return;
            }

            // Type positions: TSQualifiedName — handles both depths via the helper.
            // If the helper matches (depth-1 or depth-2), emit the fix and stop recursing
            // into this node's children to avoid overlapping fixes from the inner
            // TSQualifiedName (e.g. React.JSX inside React.JSX.Element).
            if (node.type === 'TSQualifiedName') {
              const qn = node as TSESTree.TSQualifiedName;
              const usage = extractReactNamespaceUsage(qn, localName);
              if (usage) {
                allFixes.push({
                  range: usage.replaceRange,
                  text: usage.replacementText
                });
                // Stop — don't recurse into the inner TSQualifiedName
                return;
              }
            }

            for (const key in node) {
              if (key === 'parent' || key === 'range' || key === 'loc' || key === 'type') continue;
              const value = (node as unknown as Record<string, unknown>)[key];
              if (Array.isArray(value)) {
                for (const child of value) {
                  if (child && typeof child === 'object' && (child as TSESTree.Node).type)
                    walk(child as TSESTree.Node);
                }
              } else if (value && typeof value === 'object' && (value as TSESTree.Node).type) {
                walk(value as TSESTree.Node);
              }
            }
          }

          sourceCode.ast.body.forEach(walk);
        }

        for (const { nodes, pkg } of importFixes) {
          const defaultImportInfo = defaultImportNodes.get(pkg);
          if (!defaultImportInfo) continue;

          context.report({
            node: defaultImportInfo.node,
            messageId: 'useNamedImport',
            fix(fixer) {
              const combinedFixes: RuleFix[] = [];

              for (const { nodes: nodesToFix, text: newImportText } of importFixes) {
                if (nodesToFix.length > 0) {
                  combinedFixes.push(fixer.replaceTextRange(nodesToFix[0].range, newImportText));
                  for (let i = 1; i < nodesToFix.length; i++) {
                    const n = nodesToFix[i];
                    const startLine = sourceCode.getIndexFromLoc({ line: n.loc.start.line, column: 0 });
                    const endLine = sourceCode.getIndexFromLoc({ line: n.loc.end.line + 1, column: 0 });
                    combinedFixes.push(fixer.removeRange([startLine, endLine]));
                  }
                }
              }

              for (const { range, text } of allFixes) {
                combinedFixes.push(fixer.replaceTextRange(range, text));
              }

              return combinedFixes;
            }
          });
        }

        // ── Part 2: Bare React.Foo type usages with no default import ─────────
        // e.g.  children?: React.ReactNode;  without any `import React` in the file.

        if (bareTypeUsages.length === 0) return;

        // Deduplicate type names across all bare usages
        const bareTypeNames = Array.from(new Set(bareTypeUsages.map((u) => u.typeName))).sort();

        // Find an existing value named import from 'react' to merge into, if any.
        const existingReactImport = (allImportNodes.get('react') ?? []).find(
          (n) =>
            n.importKind !== 'type' && n.specifiers.some((s) => s.type === AST_NODE_TYPES.ImportSpecifier)
        );

        // Pre-compute the new import text
        let newImportText: string;
        if (existingReactImport) {
          const alreadyImported = new Set(
            existingReactImport.specifiers
              .filter((s): s is TSESTree.ImportSpecifier => s.type === AST_NODE_TYPES.ImportSpecifier)
              .map((s) =>
                s.imported.type === AST_NODE_TYPES.Identifier ? s.imported.name : s.imported.value
              )
          );
          const newTypeSpecs = bareTypeNames.filter((n) => !alreadyImported.has(n));

          const existingSpecTexts = existingReactImport.specifiers
            .filter((s): s is TSESTree.ImportSpecifier => s.type === AST_NODE_TYPES.ImportSpecifier)
            .map((s) => {
              const name = s.imported.type === AST_NODE_TYPES.Identifier ? s.imported.name : s.imported.value;
              const alias = s.local.name !== name ? ` as ${s.local.name}` : '';
              const typeKw = s.importKind === 'type' ? 'type ' : '';
              return `${typeKw}${name}${alias}`;
            });

          const allSpecTexts = [...existingSpecTexts, ...newTypeSpecs.map((n) => `type ${n}`)].sort((a, b) =>
            a.replace(/^type /, '').localeCompare(b.replace(/^type /, ''))
          );

          const quote = existingReactImport.source.raw[0];
          newImportText = `import { ${allSpecTexts.join(', ')} } from ${quote}react${quote};`;
        } else {
          newImportText = `import type { ${bareTypeNames.join(', ')} } from 'react';\n`;
        }

        // Report ONCE for the first bare-type usage node, with a combined fix that:
        //   - rewrites every React.Foo → Foo use site
        //   - rewrites (or prepends) the import in a single operation
        // This avoids ESLint dropping conflicting fixes across multiple reports.
        context.report({
          node: bareTypeUsages[0].parent,
          messageId: 'noNamespaceType',
          data: { typeName: bareTypeUsages[0].replacementText },
          fix(fixer) {
            const fixes: RuleFix[] = [];

            // Replace every React.Foo / React.JSX.Element use site
            for (const { replacementText, replaceRange } of bareTypeUsages) {
              fixes.push(fixer.replaceTextRange(replaceRange, replacementText));
            }

            // Rewrite or prepend the import
            if (existingReactImport) {
              fixes.push(fixer.replaceTextRange(existingReactImport.range, newImportText));
            } else {
              fixes.push(fixer.replaceTextRange([0, 0], newImportText));
            }

            return fixes;
          }
        });
      }
    };
  }
});
