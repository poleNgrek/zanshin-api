import { AST_NODE_TYPES } from '@typescript-eslint/utils';
import { describe } from 'bun:test';
import { createRuleTester } from '../rule_tester';
import { cyclicImportPathNormalizer } from './cyclic_import_path_normalizer';

describe('cyclic-import-path-normalizer', () => {
  const ruleTester = createRuleTester();

  ruleTester.run('cyclic-import-path-normalizer', cyclicImportPathNormalizer, {
    valid: [
      {
        code: 'import { assert } from "../../hello"',
      },
      {
        code: 'import { assert } from "../hello"',
      },
      {
        code: 'import { assert } from "./hello"',
      },
      {
        code: 'import { assert } from "@zanshin/functions"',
      },
      {
        code: 'import { FeaturePreview } from "./FeaturePreview"',
      },
    ],

    invalid: [
      {
        code: 'import { assert } from "../.././dawd"',
        output: 'import { assert } from "../../dawd"',

        errors: [
          {
            messageId: 'denormalizedPath',
            type: AST_NODE_TYPES.ImportDeclaration,
            data: {
              denormalizedPath: '../.././dawd',
              suggestedFix: '../../dawd',
            },
          },
        ],
      },
      {
        code: 'import { assert } from "../.././dawd/../dawd"',
        output: 'import { assert } from "../../dawd"',

        errors: [
          {
            messageId: 'denormalizedPath',
            type: AST_NODE_TYPES.ImportDeclaration,
            data: {
              denormalizedPath: '../.././dawd/../dawd',
              suggestedFix: '../../dawd',
            },
          },
        ],
      },
      {
        code: 'import { assert } from "./.././"',
        output: 'import { assert } from "../"',
        errors: [
          {
            messageId: 'denormalizedPath',
            type: AST_NODE_TYPES.ImportDeclaration,
            data: { denormalizedPath: './.././', suggestedFix: '../' },
          },
        ],
      },
    ],
  });
});
