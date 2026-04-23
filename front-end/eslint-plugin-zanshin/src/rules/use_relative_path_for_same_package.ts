import { dirname, join, relative } from 'path';
import { fileURLToPath } from 'url';
import {
  ALIAS_TO_SRC_SUBPATH,
  buildImportStatement,
  classifySpecifiers,
  createRule,
  getOptionalParserServices,
  getPackageAliasForFile,
  overrideFilenameSchema,
  resolveLintedFilename,
} from './utils';

export const useRelativePathForSamePackage = createRule({
  name: 'use-relative-path-for-same-package-imports',
  meta: {
    type: 'problem',
    docs: {
      description:
        'Within a package, imports must use relative paths instead of the @zanshin/<pkg> alias.',
    },
    messages: {
      aliasInSamePackage:
        'Alias import used within the same package. Replace {{ importPath }} with {{ suggestedFix }}',
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

    const services = getOptionalParserServices(context);

    return {
      ImportDeclaration(node) {
        const importPath = node.source.value;

        const aliasMatch = importPath.match(/^(@(?:zanshin)\/[^/]+)(\/.*)?$/);
        if (!aliasMatch) return;

        const aliasPrefix = aliasMatch[1];
        const aliasSubPath = aliasMatch[2] ?? '';

        const srcSubpath = ALIAS_TO_SRC_SUBPATH[aliasPrefix];
        if (!srcSubpath) return;

        // Find the src/ root from the current file's path
        const srcRootMatch = lintedFilename.match(/^(.*\/src)\//);
        if (!srcRootMatch) return;
        const srcRoot = srcRootMatch[1];

        const targetAbsPath = join(srcRoot, srcSubpath) + aliasSubPath;
        const currentFileAlias = getPackageAliasForFile(lintedFilename);

        if (currentFileAlias !== aliasPrefix) return;

        let relativePath = relative(dirname(lintedFilename), targetAbsPath);
        if (!relativePath.startsWith('.')) relativePath = './' + relativePath;

        const classifications = classifySpecifiers(
          node,
          services,
          targetAbsPath,
        );
        context.report({
          node,
          messageId: 'aliasInSamePackage',
          data: { importPath, suggestedFix: relativePath },
          fix: (fixer) =>
            fixer.replaceText(
              node,
              buildImportStatement(node, relativePath, classifications),
            ),
        });
      },
    };
  },
});
