import { AST_NODE_TYPES } from '@typescript-eslint/utils';
import { describe } from 'bun:test';
import { createRuleTester } from '../rule_tester';
import { enforcePascalCasedZodSchemas } from './enforce_pascal_cased_zod_schemas';

describe('', () => {
  const ruleTester = createRuleTester();

  ruleTester.run('enforce-pascal-cased-zod-schemas', enforcePascalCasedZodSchemas, {
    valid: [
      {
        code: 'const BasicUserSchema = z.array(z.object({ id: z.string(), fullName: z.string()}))'
      },
      {
        code: 'const HazardClassValue = z.union([z.string(), z.number(), z.boolean()]).nullish();'
      },
      {
        code: "const IframeNavigationSchema = z.object({ type: z.literal('iframe-navigation'), url: z.string(), canGoBack: z.boolean(), canGoForward: z.boolean()})"
      },
      {
        code: 'const User = z.object({ name: z.string(), age: z.number() })'
      },
      {
        code: 'export const Address = z.object({ street: z.string(), city: z.string() })'
      },
      {
        code: 'const NumberRangeSchema = z.number().gt(0).lt(100);'
      },
      {
        code: 'const Validation = z.union([z.string(), z.number()])'
      },
      {
        code: 'const Category = baseCategory.extend({ subcategories: z.lazy(() => Category.array()) })'
      },
      {
        code: "const normalVariable = 'not a schema'" // Should be ignored as it's not a schema
      },
      {
        code: `
        import { z as zood } from 'zod';
        const User = zood.object({ name: zood.string() });
      `
      },
      {
        code: `
        import * as myZod from 'zod';
        const Product = myZod.object({ price: myZod.number() });
      `
      }
    ],
    invalid: [
      {
        code: 'export const stateRecord = z.record(z.unknown());',
        errors: [
          {
            messageId: 'notPascalCased',
            type: AST_NODE_TYPES.VariableDeclaration,
            data: {
              variableName: 'stateRecord',
              pascalName: 'StateRecord'
            }
          }
        ]
      },
      {
        code: 'const extendedCategorySchema: z.ZodType<Category> = baseCategory.extend({ subcategories: z.lazy(() => category.array()) });',
        errors: [
          {
            messageId: 'notPascalCased',
            type: AST_NODE_TYPES.VariableDeclaration,
            data: {
              variableName: 'extendedCategorySchema',
              pascalName: 'ExtendedCategorySchema'
            }
          }
        ]
      },
      {
        code: `
      import * as meinZod from 'zod';
      const user = meinZod.object({ name: meinZod.string() });
      `,
        errors: [
          {
            messageId: 'notPascalCased',
            type: AST_NODE_TYPES.VariableDeclaration,
            data: {
              variableName: 'user',
              pascalName: 'User'
            }
          }
        ]
      }
    ]
  });
});
