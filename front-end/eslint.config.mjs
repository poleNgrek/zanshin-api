import tsPlugin from "@typescript-eslint/eslint-plugin";
import tsParser from "@typescript-eslint/parser";
import reactHooks from "eslint-plugin-react-hooks";
import * as zanshinPlugin from "./eslint-plugin-zanshin/dist/index.js";

export default [
  {
    ignores: [
      "build/**",
      "public/build/**",
      "coverage/**",
      "node_modules/**",
      "eslint-plugin-zanshin/dist/**",
      "eslint-plugin-zanshin/src/**",
      ".cache/**",
      "test-results/**"
    ]
  },
  {
    files: ["**/*.{ts,tsx}"],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: "module"
      }
    },
    plugins: {
      "@typescript-eslint": tsPlugin,
      "react-hooks": reactHooks
    },
    rules: {
      ...tsPlugin.configs.recommended.rules,
      ...reactHooks.configs.recommended.rules,
      "react-hooks/set-state-in-effect": "error",
      "react-hooks/immutability": "error",
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/consistent-type-imports": "error",
      "@typescript-eslint/naming-convention": [
        "error",
        {
          selector: "variable",
          modifiers: ["const"],
          filter: {
            regex: "Schema$",
            match: true
          },
          format: ["PascalCase"]
        }
      ]
    }
  },
  {
    files: ["app/**/*.{ts,tsx}"],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: "module",
        projectService: true,
        tsconfigRootDir: import.meta.dirname
      }
    },
    plugins: {
      zanshin: zanshinPlugin
    },
    rules: {
      "zanshin/cyclic-import-path-normalizer": "error",
      "zanshin/no-imports-from-node-modules-or-index": "error",
      "zanshin/no-type-assertion": "off",
      "zanshin/no-path-escaping": "error",
      "zanshin/use-relative-path-for-same-package-imports": "error",
      "zanshin/merge-type-and-value-imports": "error",
      "zanshin/enforce-pascal-cased-zod-schemas": "error",
      "zanshin/enforce-named-react-packages-imports": "error"
    }
  }
];
