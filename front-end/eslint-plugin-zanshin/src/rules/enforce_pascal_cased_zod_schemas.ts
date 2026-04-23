import { AST_NODE_TYPES, TSESTree } from '@typescript-eslint/utils';
import type { RuleContext } from '@typescript-eslint/utils/ts-eslint';
import { pascalCase } from 'change-case';
import { createRule } from './utils';

export const enforcePascalCasedZodSchemas = createRule({
  name: 'enforce-pascal-cased-zod-schemas',
  meta: {
    type: 'suggestion',
    docs: {
      description: 'Enforce Pascal Case for Zod schema variable names'
    },
    messages: {
      notPascalCased:
        "Zod schema variables should be PascalCased: '{{ variableName }}' should be '{{ pascalName }}'"
    },
    schema: []
  },

  defaultOptions: [],
  create(context) {
    const zodAliases = findZodImportAliases(context);

    return {
      VariableDeclaration(node: TSESTree.VariableDeclaration) {
        for (const declaration of node.declarations) {
          /**
            When ESLint analyzes variable declarations it handles various ways variables can be declared:
             1. Simple identifiers: const myVar = z.string()
             2. Object destructuring: const { prop1, prop2 } = someObject
             3. Array destructuring: const [first, second] = someArray
            The following line is checking if the current variable declaration is a simple identifier (case #1).
            If it's any other pattern (like destructuring), it skips this declaration with continue
           */
          if (declaration.id.type !== AST_NODE_TYPES.Identifier) continue;
          const variableName = declaration.id.name;
          if (isZodSchema(declaration, zodAliases)) {
            const pascalName = pascalCase(variableName);
            if (variableName !== pascalName) {
              context.report({
                node,
                messageId: 'notPascalCased',
                data: {
                  variableName,
                  pascalName
                }
              });
            }
          }
        }
      }
    };
  }
});

function findZodImportAliases(context: Readonly<RuleContext<'notPascalCased', []>>): Set<string> {
  const aliases = new Set<string>();

  // Default 'z' import
  aliases.add('z');

  // Find all import statements
  const sourceCode = context.sourceCode;
  const ast = sourceCode.ast;

  // Walk through all import declarations
  const importDeclarations = ast.body.filter(
    (node): node is TSESTree.ImportDeclaration => node.type === AST_NODE_TYPES.ImportDeclaration
  );

  for (const importDeclaration of importDeclarations) {
    // Check if this is an import from 'zod'
    if (importDeclaration.source.value === 'zod') {
      for (const specifier of importDeclaration.specifiers) {
        // Handle cases like: import { z } from 'zod';
        if (
          specifier.type === AST_NODE_TYPES.ImportSpecifier &&
          specifier.imported.type === AST_NODE_TYPES.Identifier &&
          specifier.imported.name !== 'z'
        ) {
          // Add the local name (alias if present)
          aliases.add(specifier.local.name);
        }

        // Handle cases like: import * as z from 'zod';
        if (specifier.type === AST_NODE_TYPES.ImportNamespaceSpecifier) {
          aliases.add(specifier.local.name);
        }
      }
    }
  }

  return aliases;
}

function isZodSchema(declarator: TSESTree.VariableDeclarator, zodAliases: Set<string>): boolean {
  // Look for variable initializations that use Zod
  if (!declarator.init) return false;

  // Check for direct z.object() or myZod.array() calls
  if (
    declarator.init.type === AST_NODE_TYPES.CallExpression &&
    declarator.init.callee.type === AST_NODE_TYPES.MemberExpression &&
    declarator.init.callee.object.type === AST_NODE_TYPES.Identifier &&
    zodAliases.has(declarator.init.callee.object.name)
  ) {
    return true;
  }

  // Check for chained methods on schema objects like .extend(), .array(), etc.
  if (
    declarator.init.type === AST_NODE_TYPES.CallExpression &&
    declarator.init.callee.type === AST_NODE_TYPES.MemberExpression &&
    declarator.init.callee.property.type === AST_NODE_TYPES.Identifier &&
    ['extend', 'array', 'optional', 'nullable', 'transform', 'refine'].includes(
      declarator.init.callee.property.name
    )
  ) {
    return true;
  }

  return false;
}
