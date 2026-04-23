import { normalize } from 'path';
import { createRule } from './utils';

export const cyclicImportPathNormalizer = createRule({
  name: 'cyclic-import-path-normalizer',
  meta: {
    type: 'problem',
    docs: {
      description: 'Normalize cyclic import paths'
    },
    messages: {
      denormalizedPath: 'Denormalized path detected. Replace {{ denormalizedPath }} with {{ suggestedFix }}'
    },
    schema: [], // No options,
    fixable: 'code'
  },

  defaultOptions: [],
  create: function (context) {
    return {
      ImportDeclaration(node) {
        const importPath = node.source.value;
        if (typeof importPath !== 'string') return;

        let normalizedPath = normalize(importPath);
        if (importPath.startsWith('./') && !normalizedPath.startsWith('.')) {
          normalizedPath = `./${normalizedPath}`;
        }

        if (importPath !== normalizedPath) {
          context.report({
            node: node,
            messageId: 'denormalizedPath',
            data: { denormalizedPath: importPath, suggestedFix: normalizedPath },
            fix: function (fixer) {
              return fixer.replaceText(node.source, JSON.stringify(normalizedPath));
            }
          });
        }
      }
    };
  }
});
