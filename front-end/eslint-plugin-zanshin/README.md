# eslint-plugin-zanshin

Custom ESLint rules for the Zanshin front-end codebase.

## Package layout

- `src/index.ts` - plugin entry that exports all rules
- `src/rules/*.ts` - rule implementations
- `src/rules/*.test.ts` - rule tests
- `dist/` - Node-friendly build output consumed by ESLint

## Build and usage

This plugin is built to plain JavaScript and imported by `front-end/eslint.config.mjs`.

```sh
cd front-end/eslint-plugin-zanshin
npm run build
```

The main front-end lint command runs this build step automatically before ESLint.

## Type-aware lint requirements

Some rules need TypeScript checker services to determine whether imports are type-only or runtime values.  
The front-end ESLint config enables:

- `parserOptions.projectService: true`
- `parserOptions.tsconfigRootDir: import.meta.dirname`

This improves accuracy but makes linting slower.

## Active rules

- `zanshin/no-path-escaping`
- `zanshin/use-relative-path-for-same-package-imports`
- `zanshin/enforce-named-react-packages-imports`
- `zanshin/merge-type-and-value-imports`
- `zanshin/no-type-assertion`
- `zanshin/enforce-pascal-cased-zod-schemas`
- `zanshin/no-imports-from-node-modules-or-index`
- `zanshin/cyclic-import-path-normalizer`

## Running tests

```sh
cd front-end/eslint-plugin-zanshin
bun test
```

## Adding a new rule

1. Add `src/rules/my_rule_name.ts`
2. Add `src/rules/my_rule_name.test.ts`
3. Export it from `src/index.ts`
4. Enable it in `front-end/eslint.config.mjs`
5. Rebuild plugin and rerun lint/tests
