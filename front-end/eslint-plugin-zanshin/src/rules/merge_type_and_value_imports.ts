import type { TSESTree } from '@typescript-eslint/utils';
import { createRule } from './utils';

/**
 * Supported merge shapes (any number of each kind):
 *   import type { A } + import { B }              ✅ Merge
 *   import type { A } + import type { B }          ✅ Merge (2 type imports)
 *   import { A }      + import { B }               ✅ Merge (2 value imports)
 *   import type { A } + import { B } + import { C} ✅ Merge (N type + M value)
 *
 * Always skipped:
 *   import Foo / import * as Foo                   ⛔ default or namespace specifier
 *   import './foo'                                 ⛔ side-effect (no specifiers)
 */

export const mergeTypeAndValueImports = createRule({
  name: 'merge-type-and-value-imports',
  meta: {
    type: 'problem',
    docs: {
      description:
        'Merge multiple `import` and/or `import type` statements from the same module into a single statement.'
    },
    messages: {
      duplicateImport: "Multiple imports from '{{source}}' can be merged into one."
    },
    schema: [],
    fixable: 'code'
  },

  defaultOptions: [],
  create(context) {
    const importsBySource = new Map<string, TSESTree.ImportDeclaration[]>();

    return {
      ImportDeclaration(node) {
        const source = node.source.value;
        const existing = importsBySource.get(source);
        if (existing) {
          existing.push(node);
        } else {
          importsBySource.set(source, [node]);
        }
      },

      'Program:exit'() {
        for (const [source, nodes] of importsBySource) {
          if (nodes.length < 2) continue;

          // Skip side-effect imports (`import './foo'`) — they have no specifiers
          // and their side-effect semantics must be preserved.
          if (nodes.some((n) => n.specifiers.length === 0)) continue;

          // Skip if any import uses a default or namespace specifier — those
          // cannot be safely merged into a named `import { ... }` statement.
          const hasDefaultOrNamespace = (n: TSESTree.ImportDeclaration) =>
            n.specifiers.some(
              (s) => s.type === 'ImportDefaultSpecifier' || s.type === 'ImportNamespaceSpecifier'
            );
          if (nodes.some(hasDefaultOrNamespace)) continue;

          // Sort all nodes by source position so we keep the first one and
          // remove the rest.
          const sorted = [...nodes].sort((a, b) => a.range[0] - b.range[0]);
          const [first, ...rest] = sorted;

          context.report({
            node: rest[rest.length - 1],
            messageId: 'duplicateImport',
            data: { source },
            fix(fixer) {
              const sourceCode = context.sourceCode;

              // Collect all specifier texts, tagging each as type-only or not.
              const allSpecifiers: { text: string; isType: boolean }[] = [];
              for (const importNode of sorted) {
                const declIsTypeOnly = importNode.importKind === 'type';
                for (const spec of importNode.specifiers) {
                  const text = sourceCode.getText(spec);
                  const isType =
                    declIsTypeOnly ||
                    ('importKind' in spec && spec.importKind === 'type') ||
                    text.startsWith('type ');
                  // Strip any existing inline `type ` prefix — we'll re-add it as needed below.
                  const bareText = text.startsWith('type ') ? text.slice(5) : text;
                  allSpecifiers.push({ text: bareText, isType });
                }
              }

              // If every specifier is type-only, use `import type { ... }` (cleaner).
              // Otherwise use `import { ..., type Foo, ... }` with per-specifier `type` keywords.
              const allAreTypes = allSpecifiers.every((s) => s.isType);
              const specifierList = allSpecifiers
                .map((s) => (allAreTypes || !s.isType ? s.text : `type ${s.text}`))
                .join(', ');
              const importKeyword = allAreTypes ? 'import type' : 'import';
              const quote = first.source.raw[0];
              const merged = `${importKeyword} { ${specifierList} } from ${quote}${source}${quote};`;

              // Replace the first import with the merged statement, then delete
              // every subsequent import (including its trailing newline).
              const fixes = [fixer.replaceText(first, merged)];
              for (const node of rest) {
                const srcText = sourceCode.getText();
                const charAfter = srcText[node.range[1]];
                const deleteEnd = charAfter === '\n' ? node.range[1] + 1 : node.range[1];
                fixes.push(fixer.removeRange([node.range[0], deleteEnd]));
              }
              return fixes;
            }
          });
        }
      }
    };
  }
});
