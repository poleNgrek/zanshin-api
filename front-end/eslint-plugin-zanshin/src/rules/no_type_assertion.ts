import { AST_NODE_TYPES } from '@typescript-eslint/utils';
import type { TSESTree } from '@typescript-eslint/utils';
import { createRule } from './utils';

/**
 * Returns true when a type annotation is an allowed exception to the no-assertion rule.
 *
 * Both `TSTypeAssertion` (<T>expr) and `TSAsExpression` (expr as T) share the
 * same two carve-outs — `as unknown` (safe widening) and `as const` (literal
 * narrowing). This helper centralises the check so the logic is not duplicated
 * in each AST visitor.
 */
function isAllowedTypeAnnotation(typeAnnotation: TSESTree.TypeNode): boolean {
  if (typeAnnotation.type === AST_NODE_TYPES.TSUnknownKeyword) {
    return true;
  }
  if (typeAnnotation.type === AST_NODE_TYPES.TSTypeReference) {
    const { typeName } = typeAnnotation;
    if (typeName.type === AST_NODE_TYPES.Identifier && typeName.name === 'const') {
      return true;
    }
  }
  return false;
}

export const noTypeAssertion = createRule({
  name: 'no-type-assertion',
  meta: {
    type: 'suggestion',
    docs: {
      description: 'disallow type assertions in TypeScript code'
    },
    messages: {
      angleBracketAssertion:
        'An illegal type assertion was detected:\n{{ typeAssertion }}\nPlease do not use anglebracket type assertion.',
      asAssertion:
        'An illegal type assertion was detected:\n{{ typeAssertion }}\nPlease do not use `as` operator for type assertion.',
      nonNullAssertion:
        'An illegal type assertion was detected:\n{{ typeAssertion }}\nPlease do not use non-null assertion operator.'
    },
    schema: [] // No options,
  },
  defaultOptions: [],
  create: function (context) {
    return {
      TSTypeAssertion(node) {
        if (isAllowedTypeAnnotation(node.typeAnnotation)) return;
        const culprit = context.sourceCode.getText(node);
        context.report({ node, messageId: 'angleBracketAssertion', data: { typeAssertion: culprit } });
      },
      TSAsExpression(node) {
        if (isAllowedTypeAnnotation(node.typeAnnotation)) return;
        const culprit = context.sourceCode.getText(node);
        context.report({ node, messageId: 'asAssertion', data: { typeAssertion: culprit } });
      },

      TSNonNullExpression(node) {
        const culprit = context.sourceCode.getText(node);
        context.report({ node, messageId: 'nonNullAssertion', data: { typeAssertion: culprit } });
      }
    };
  }
});
