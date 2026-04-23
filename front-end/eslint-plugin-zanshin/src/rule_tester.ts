import { RuleTester } from '@typescript-eslint/rule-tester';
import { afterAll, describe, it } from 'bun:test';
import { join } from 'path';
import tseslint from 'typescript-eslint';

RuleTester.afterAll = afterAll;
RuleTester.it = it;
RuleTester.itOnly = it.only;
RuleTester.describe = describe;

export function createRuleTester() {
  return new RuleTester({
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {
        projectService: {
          allowDefaultProject: ['*.ts*'],
          defaultProject: 'tsconfig.json',
        },
        tsconfigRootDir: join(__dirname, '../'),
      },
    },
  });
}

// Rule tester that uses the app's tsconfig so path aliases ( @zanshin/*)
// are resolved — required for type-detection tests in no_path_escaping.
export function createAppRuleTester() {
  return new RuleTester({
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {
        projectService: {
          allowDefaultProject: ['*.ts*'],
          defaultProject: 'tsconfig.json',
        },
        // From src/rule_tester.ts: go up src/ → eslint-plugin-zanshin/ → front-end/app/
        tsconfigRootDir: join(__dirname, '../../app'),
      },
    },
  });
}
