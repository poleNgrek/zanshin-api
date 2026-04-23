import { AST_NODE_TYPES } from '@typescript-eslint/utils';
import { describe, setDefaultTimeout } from 'bun:test';
import { join } from 'path';
import { createAppRuleTester, createRuleTester } from '../rule_tester';
import { noPathEscaping } from './no_path_escaping';

describe('no-path-escaping', () => {
  const ruleTester = createRuleTester();

  ruleTester.run('no-path-escaping', noPathEscaping, {
    valid: [
      {
        // Same-package relative import — allowed
        code: "import { Hello } from './hello.tsx'",
        options: [{ overrideFilename: '/components/hello.tsx' }],
      },
      {
        // Packageless file importing sibling — allowed
        code: "import { useLatestVersion } from './versioning'",
        options: [{ overrideFilename: 'app_bar.tsx' }],
      },
      {
        // Same-package relative going up one level — allowed
        code: "import { useLatestVersion } from './../versioning'",
        options: [{ overrideFilename: '/some-package/some_file.tsx' }],
      },
      {
        // Cross-package via alias — already correct, rule doesn't touch it
        code: "import { FlexRow } from '@zanshin/components'",
        options: [{ overrideFilename: '/hello/hello.tsx' }],
      },
      {
        // External npm package — not managed
        code: "import { Blah } from 'blah'",
        options: [{ overrideFilename: '/hello/hello.tsx' }],
      },
      {
        // @zanshin alias from different package — correct
        code: "import { openSnackbar } from '@zanshin/forms/open_snackbar'",
        options: [{ overrideFilename: '/components/button.tsx' }],
      },
      {
        // @zanshin alias from different zanshin package — correct
        code: "import { FlexRow } from '@zanshin/components/wrappers'",
        options: [{ overrideFilename: '/zanshin/fetch/public/send.tsx' }],
      },
      {
        // Side-effect import — not managed
        code: "import './styles.css'",
        options: [{ overrideFilename: '/components/button.tsx' }],
      },
    ],

    invalid: [
      {
        code: "import { Hello } from './../origami/hello.tsx'",
        output: "import { Hello } from '@zanshin/origami/hello.tsx'",
        options: [{ overrideFilename: '/components/hello.tsx' }],
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        code: "import { Hello } from '../../../src/../src/origami/test/hello.tsx'",
        output: "import { Hello } from '@zanshin/origami/test/hello.tsx'",
        options: [{ overrideFilename: '/tests/eslint_tests/test.tsx' }],
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        // Escaping into an zanshin package
        code: "import { Hello } from './../components/hello.tsx'",
        output: "import { Hello } from '@zanshin/components/hello.tsx'",
        options: [{ overrideFilename: '/zanshin/origami/origami.tsx' }],
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        code: "import { Origami } from '../../zanshin/origami/origami.tsx'",
        output: "import { Origami } from '@zanshin/origami/origami.tsx'",
        options: [{ overrideFilename: '/tests/eslint_tests/test.tsx' }],
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        // Path going through src/ — corrected to relative (packageless → packageless)
        code: "import { Origami } from '../../../src/origami'",
        output: "import { Origami } from '../../origami'",
        options: [{ overrideFilename: '/tests/eslint_tests/test.tsx' }],
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        code: "import { Origami } from './zanshin/origami'",
        output: "import { Origami } from '@zanshin/origami'",
        options: [{ overrideFilename: 'app_bar.tsx' }],
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        code: "import { PaperOrigami } from '../src/origami/paper'",
        output: "import { PaperOrigami } from '@zanshin/origami/paper'",
        options: [{ overrideFilename: 'app_bar.tsx' }],
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        // `import type` is preserved through the fix
        code: "import type { Hello } from './../origami/hello.tsx'",
        output: "import type { Hello } from '@zanshin/origami/hello.tsx'",
        options: [{ overrideFilename: '/components/hello.tsx' }],
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        // Inline `type` specifier preserved
        code: "import { type SomeType, SomeComponent } from './../origami/hello.tsx'",
        output:
          "import { type SomeType, SomeComponent } from '@zanshin/origami/hello.tsx'",
        options: [{ overrideFilename: '/components/hello.tsx' }],
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        // All-inline-type specifiers → promotes to `import type`
        code: "import { type SomeType, type AnotherType } from './../origami/hello.tsx'",
        output:
          "import type { SomeType, AnotherType } from '@zanshin/origami/hello.tsx'",
        options: [{ overrideFilename: '/components/hello.tsx' }],
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        // Renamed specifier preserved
        code: "import { Hello as Hi } from './../origami/hello.tsx'",
        output: "import { Hello as Hi } from '@zanshin/origami/hello.tsx'",
        options: [{ overrideFilename: '/components/hello.tsx' }],
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        // Namespace import
        code: "import * as Origami from './../origami/hello.tsx'",
        output: "import * as Origami from '@zanshin/origami/hello.tsx'",
        options: [{ overrideFilename: '/components/hello.tsx' }],
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
    ],
  });
});

// Type detection tests using real app files
describe('no-path-escaping type detection (app tsconfig)', () => {
  setDefaultTimeout(30000);
  const appRuleTester = createAppRuleTester();
  const APP_SRC = join(__dirname, '../../../app/src');

  appRuleTester.run('no-path-escaping type detection', noPathEscaping, {
    valid: [],
    invalid: [
      {
        filename: APP_SRC + '/hooks/hooks.tsx',
        code: "import { CommentType } from '../reports/components/report_comments/types'",
        output:
          "import type { CommentType } from '@zanshin/reports/components/report_comments/types'",
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        filename: APP_SRC + '/hooks/hooks.tsx',
        code: "import { CommentUserSchema } from '../reports/components/report_comments/types'",
        output:
          "import { CommentUserSchema } from '@zanshin/reports/components/report_comments/types'",
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
      {
        filename: APP_SRC + '/hooks/hooks.tsx',
        code: "import { CommentType, CommentUserSchema } from '../reports/components/report_comments/types'",
        output:
          "import { type CommentType, CommentUserSchema } from '@zanshin/reports/components/report_comments/types'",
        errors: [
          { messageId: 'pathEscaping', type: AST_NODE_TYPES.ImportDeclaration },
        ],
      },
    ],
  });
});
