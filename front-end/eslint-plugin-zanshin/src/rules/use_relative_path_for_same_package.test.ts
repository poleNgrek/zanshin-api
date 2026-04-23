import { AST_NODE_TYPES } from '@typescript-eslint/utils';
import { describe } from 'bun:test';
import { createRuleTester } from '../rule_tester';
import { useRelativePathForSamePackage } from './use_relative_path_for_same_package';

describe('use-relative-path-for-same-package-imports', () => {
  const ruleTester = createRuleTester();

  ruleTester.run(
    'use-relative-path-for-same-package-imports',
    useRelativePathForSamePackage,
    {
      valid: [
        {
          // Relative import within same package — already correct
          code: "import { Button } from './button'",
          options: [{ overrideFilename: '/components/index.tsx' }],
        },
        {
          // Cross-package alias import — should NOT be flagged by this rule
          code: "import { openSnackbar } from '@zanshin/forms/open_snackbar'",
          options: [{ overrideFilename: '/components/button.tsx' }],
        },
        {
          // Cross-zanshin-package alias — not same package, so correct to use alias
          code: "import { FlexRow } from '@zanshin/components/wrappers'",
          options: [{ overrideFilename: '/zanshin/fetch/public/send.tsx' }],
        },
        {
          // External npm package — not managed
          code: "import { useState } from 'react'",
          options: [{ overrideFilename: '/components/button.tsx' }],
        },
        {
          // @zanshin/types is a real npm workspace package, not a path-alias package
          code: "import { MyType } from '@zanshin/types'",
          options: [{ overrideFilename: '/components/button.tsx' }],
        },
      ],

      invalid: [
        {
          // Inside @zanshin/components at root — must use ./button
          code: "import { Button } from '@zanshin/components/button'",
          output: "import { Button } from './button'",
          options: [{ overrideFilename: '/components/index.tsx' }],
          errors: [
            {
              messageId: 'aliasInSamePackage',
              type: AST_NODE_TYPES.ImportDeclaration,
            },
          ],
        },
        {
          // Inside @zanshin/components/sub — must use ../button
          code: "import { Button } from '@zanshin/components/button'",
          output: "import { Button } from '../button'",
          options: [{ overrideFilename: '/components/sub/widget.tsx' }],
          errors: [
            {
              messageId: 'aliasInSamePackage',
              type: AST_NODE_TYPES.ImportDeclaration,
            },
          ],
        },
        {
          // Inside @zanshin/fetch — must use relative
          code: "import { sendMutation } from '@zanshin/fetch/public/send_mutation'",
          output: "import { sendMutation } from './public/send_mutation'",
          options: [{ overrideFilename: '/zanshin/fetch/index.ts' }],
          errors: [
            {
              messageId: 'aliasInSamePackage',
              type: AST_NODE_TYPES.ImportDeclaration,
            },
          ],
        },
        {
          // `import type` preserved through fix
          code: "import type { Button } from '@zanshin/components/button'",
          output: "import type { Button } from './button'",
          options: [{ overrideFilename: '/components/index.tsx' }],
          errors: [
            {
              messageId: 'aliasInSamePackage',
              type: AST_NODE_TYPES.ImportDeclaration,
            },
          ],
        },
        {
          // Inline `type` specifier preserved through fix
          code: "import { type SomeType, Button } from '@zanshin/components/button'",
          output: "import { type SomeType, Button } from './button'",
          options: [{ overrideFilename: '/components/index.tsx' }],
          errors: [
            {
              messageId: 'aliasInSamePackage',
              type: AST_NODE_TYPES.ImportDeclaration,
            },
          ],
        },
        {
          // All-inline-type specifiers → promotes to `import type`
          code: "import { type SomeType, type AnotherType } from '@zanshin/components/button'",
          output: "import type { SomeType, AnotherType } from './button'",
          options: [{ overrideFilename: '/components/index.tsx' }],
          errors: [
            {
              messageId: 'aliasInSamePackage',
              type: AST_NODE_TYPES.ImportDeclaration,
            },
          ],
        },
      ],
    },
  );
});
