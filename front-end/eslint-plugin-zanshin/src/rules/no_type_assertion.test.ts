import { AST_NODE_TYPES } from '@typescript-eslint/utils';
import { describe } from 'bun:test';
import { createRuleTester } from '../rule_tester';
import { noTypeAssertion } from './no_type_assertion';

describe('', () => {
  const ruleTester = createRuleTester();

  ruleTester.run('no-type-assertion', noTypeAssertion, {
    valid: [
      { code: 'const foo = <const>42' },
      { code: 'const foo = <unknown>42' },
      { code: 'const foo = 42 as const' },
      { code: 'const foo = 42 as unknown' }
    ],
    invalid: [
      {
        code: 'const foo = <number>42',
        errors: [
          {
            messageId: 'angleBracketAssertion',
            type: AST_NODE_TYPES.TSTypeAssertion,
            data: { typeAssertion: '<number>42' }
          }
        ]
      },
      {
        code: 'const foo = 42 as number',
        errors: [
          {
            messageId: 'asAssertion',
            type: AST_NODE_TYPES.TSAsExpression,
            data: { typeAssertion: '42 as number' }
          }
        ]
      },
      {
        code: 'const foo = 42 as any',
        errors: [
          {
            messageId: 'asAssertion',
            type: AST_NODE_TYPES.TSAsExpression,
            data: { typeAssertion: '42 as any' }
          }
        ]
      },
      {
        code: `
                const foo: { a?: number } = { a: 42 };
                const bar = foo.a! + 1;
                `,
        errors: [
          {
            messageId: 'nonNullAssertion',
            type: AST_NODE_TYPES.TSNonNullExpression,
            data: { typeAssertion: 'foo.a!' }
          }
        ]
      },
      {
        code: `
                const foo: { a?: { b: number } } = { a: { b: 42 } };
                const bar = foo.a!.b + 1
                `,
        errors: [
          {
            messageId: 'nonNullAssertion',
            type: AST_NODE_TYPES.TSNonNullExpression,
            data: { typeAssertion: 'foo.a!' }
          }
        ]
      },
      {
        code: 'return err as string;',
        errors: [
          {
            messageId: 'asAssertion',
            type: AST_NODE_TYPES.TSAsExpression,
            data: { typeAssertion: 'err as string' }
          }
        ]
      }
    ]
  });
});
