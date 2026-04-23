import { describe } from 'bun:test';
import { createRuleTester } from '../rule_tester';
import { mergeTypeAndValueImports } from './merge_type_and_value_imports';

describe('merge-type-and-value-imports', () => {
  const ruleTester = createRuleTester();

  ruleTester.run('merge-type-and-value-imports', mergeTypeAndValueImports, {
    valid: [
      // Single value import — nothing to merge
      {
        code: `import { ComponentOne } from '../folder/some_file.tsx';`,
      },
      // Single type import — nothing to merge
      {
        code: `import type { SomeType } from '../folder/some_file.tsx';`,
      },
      // Two imports from DIFFERENT sources — should not be flagged
      {
        code: `
        import type { SomeType } from '../folder/file_a.tsx';
        import { ComponentOne } from '../folder/file_b.tsx';
      `,
      },
      // Already properly merged with inline type keywords — nothing to do
      {
        code: `import { foo, type Bar } from './utils';`,
      },
      // Side-effect import alongside a named import — not flagged (side-effect has no specifiers)
      {
        code: `
        import './side-effect';
        import { bar } from './side-effect';
      `,
      },
      // Side-effect import alongside a type import — not flagged
      {
        code: `
        import './side-effect';
        import type { Foo } from './side-effect';
      `,
      },
      // Namespace import alongside a type import — not flagged
      {
        code: `
        import * as ns from './utils';
        import type { Foo } from './utils';
      `,
      },
      // Default import alongside a type import — not flagged
      {
        code: `
        import defaultExport from './utils';
        import type { Foo } from './utils';
      `,
      },
    ],

    invalid: [
      // Type import first — specifiers appear in document order (type-first)
      {
        code: [
          `import type { SomeType, AnotherType } from '../folder/some_file.tsx';`,
          `import { ComponentOne, someFunction } from '../folder/some_file.tsx';`,
        ].join('\n'),
        errors: [
          {
            messageId: 'duplicateImport',
            data: { source: '../folder/some_file.tsx' },
          },
        ],
        output: `import { type SomeType, type AnotherType, ComponentOne, someFunction } from '../folder/some_file.tsx';\n`,
      },

      // Value import first — specifiers appear in document order (value-first)
      {
        code: [
          `import { ComponentOne, someFunction } from '../folder/some_file.tsx';`,
          `import type { SomeType, AnotherType } from '../folder/some_file.tsx';`,
        ].join('\n'),
        errors: [
          {
            messageId: 'duplicateImport',
            data: { source: '../folder/some_file.tsx' },
          },
        ],
        output: `import { ComponentOne, someFunction, type SomeType, type AnotherType } from '../folder/some_file.tsx';\n`,
      },

      // Single specifier each — type import first
      {
        code: [
          `import type { Foo } from './foo';`,
          `import { bar } from './foo';`,
        ].join('\n'),
        errors: [{ messageId: 'duplicateImport', data: { source: './foo' } }],
        output: `import { type Foo, bar } from './foo';\n`,
      },

      // Aliased specifiers are preserved — type import first
      {
        code: [
          `import type { SomeType as ST } from './types';`,
          `import { realFn as fn } from './types';`,
        ].join('\n'),
        errors: [{ messageId: 'duplicateImport', data: { source: './types' } }],
        output: `import { type SomeType as ST, realFn as fn } from './types';\n`,
      },

      // 2 value imports from same source
      {
        code: [
          `import { foo } from './utils';`,
          `import { bar } from './utils';`,
        ].join('\n'),
        errors: [{ messageId: 'duplicateImport', data: { source: './utils' } }],
        output: `import { foo, bar } from './utils';\n`,
      },

      // 2 type imports from same source — promoted to `import type { ... }`
      {
        code: [
          `import type { Foo } from './types';`,
          `import type { Bar } from './types';`,
        ].join('\n'),
        errors: [{ messageId: 'duplicateImport', data: { source: './types' } }],
        output: `import type { Foo, Bar } from './types';\n`,
      },

      // Real-world motivating case: two `import type` from same package → `import type`
      {
        code: [
          `import type { ReportItemRefCategoriesEnum } from '@zanshin/types';`,
          `import type { AllReferencableItemTypesEnum } from '@zanshin/types';`,
        ].join('\n'),
        errors: [
          {
            messageId: 'duplicateImport',
            data: { source: '@zanshin/types' },
          },
        ],
        output: `import type { ReportItemRefCategoriesEnum, AllReferencableItemTypesEnum } from '@zanshin/types';\n`,
      },

      // Mixed: one value, one type → `import { value, type Type }`
      {
        code: [
          `import { ReportItemRefCategoriesEnum } from '@zanshin/types';`,
          `import type { AllReferencableItemTypesEnum } from '@zanshin/types';`,
        ].join('\n'),
        errors: [
          {
            messageId: 'duplicateImport',
            data: { source: '@zanshin/types' },
          },
        ],
        output: `import { ReportItemRefCategoriesEnum, type AllReferencableItemTypesEnum } from '@zanshin/types';\n`,
      },

      // The original motivating case: 2 type + 2 value imports from same source
      {
        code: [
          `import type { ReactNode } from 'react';`,
          `import { useEffect } from 'react';`,
          `import { useMemo } from 'react';`,
          `import type { CSSProperties } from 'react';`,
        ].join('\n'),
        errors: [{ messageId: 'duplicateImport', data: { source: 'react' } }],
        output: `import { type ReactNode, useEffect, useMemo, type CSSProperties } from 'react';\n`,
      },

      // Inline `type` specifier in a non-type import alongside another non-type import
      // — both have importKind === 'value', still merged
      {
        code: [
          `import { type Foo } from './foo';`,
          `import { bar } from './foo';`,
        ].join('\n'),
        errors: [{ messageId: 'duplicateImport', data: { source: './foo' } }],
        output: `import { type Foo, bar } from './foo';\n`,
      },
    ],
  });
});
