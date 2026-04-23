import { basename, dirname, join, normalize, relative } from 'path';
import { fileURLToPath } from 'url';
import {
  buildImportStatement,
  classifySpecifiers,
  createRule,
  extractPathUpToFirstDirAfterSrc,
  getOptionalParserServices,
  overrideFilenameSchema,
  resolveLintedFilename,
} from './utils';

export const noPathEscaping = createRule({
  name: 'no-path-escaping',
  meta: {
    type: 'problem',
    docs: {
      description:
        'Disallow relative imports that cross a package boundary. Cross-package imports must use the @zanshin/<pkg> alias.',
    },
    messages: {
      pathEscaping:
        'Incorrect import  Replace {{ importPath }} with {{ suggestedFix }}',
    },
    fixable: 'code',
    schema: overrideFilenameSchema,
    defaultOptions: [{ overrideFilename: 'default' }],
  },
  defaultOptions: [],
  create(context) {
    const ruleDirname = dirname(fileURLToPath(import.meta.url));
    const lintedFilename = resolveLintedFilename(
      context,
      context.options as Array<{ overrideFilename?: string }>,
      ruleDirname,
    );

    let services = getOptionalParserServices(context);

    return {
      ImportDeclaration(node) {
        const importPath = node.source.value;
        const isRelative =
          importPath.startsWith('./') || importPath.startsWith('../');
        if (!isRelative) return;

        const absoluteTarget = join(
          dirname(lintedFilename),
          normalize(importPath),
        );

        // ── Case A: target is directly in src/ (packageless) ─────────────────
        if (basename(dirname(absoluteTarget)) === 'src') {
          const isEscaping = /^.*\/src\//.test(importPath);
          if (!isEscaping) return;

          const correctedPath = relative(
            dirname(lintedFilename),
            absoluteTarget,
          );
          const classifications = classifySpecifiers(
            node,
            services,
            absoluteTarget,
          );
          context.report({
            node,
            messageId: 'pathEscaping',
            data: { importPath, suggestedFix: correctedPath },
            fix: (fixer) =>
              fixer.replaceText(
                node,
                buildImportStatement(node, correctedPath, classifications),
              ),
          });
          return;
        }

        // ── Case B: target is in a named package ──────────────────────────────
        const importPackagePath =
          extractPathUpToFirstDirAfterSrc(absoluteTarget);
        if (!importPackagePath) return;

        const importPackageName = basename(importPackagePath);

        const isFilePackageless = basename(dirname(lintedFilename)) === 'src';
        const currentPackagePath = isFilePackageless
          ? dirname(lintedFilename) + '/'
          : extractPathUpToFirstDirAfterSrc(lintedFilename);
        const currentPackageName = currentPackagePath
          ? basename(currentPackagePath)
          : null;

        // Same package → relative is correct
        if (currentPackageName === importPackageName) return;

        const aliasPrefix = `@zanshin/${importPackageName}`;
        const subPath = relative(importPackagePath, absoluteTarget);
        const correctedPath = subPath
          ? `${aliasPrefix}/${subPath}`
          : aliasPrefix;

        const classifications = classifySpecifiers(
          node,
          services,
          absoluteTarget,
        );
        context.report({
          node,
          messageId: 'pathEscaping',
          data: { importPath, suggestedFix: correctedPath },
          fix: (fixer) =>
            fixer.replaceText(
              node,
              buildImportStatement(node, correctedPath, classifications),
            ),
        });
      },
    };
  },
});
