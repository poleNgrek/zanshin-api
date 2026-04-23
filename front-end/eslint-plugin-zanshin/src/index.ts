import { cyclicImportPathNormalizer } from './rules/cyclic_import_path_normalizer';
import { enforceNamedReactPackagesImports } from './rules/enforce_named_react_packages_imports';
import { enforcePascalCasedZodSchemas } from './rules/enforce_pascal_cased_zod_schemas';
import { mergeTypeAndValueImports } from './rules/merge_type_and_value_imports';
import { noImportsFromNodeModulesOrIndex } from './rules/no_imports_from_node_modules_or_index';
import { noPathEscaping } from './rules/no_path_escaping';
import { noTypeAssertion } from './rules/no_type_assertion';
import { useRelativePathForSamePackage } from './rules/use_relative_path_for_same_package';

export const rules = {
  'cyclic-import-path-normalizer': cyclicImportPathNormalizer,
  'no-imports-from-node-modules-or-index': noImportsFromNodeModulesOrIndex,
  'merge-type-and-value-imports': mergeTypeAndValueImports,
  'no-type-assertion': noTypeAssertion,
  'no-path-escaping': noPathEscaping,
  'use-relative-path-for-same-package-imports': useRelativePathForSamePackage,
  'enforce-pascal-cased-zod-schemas': enforcePascalCasedZodSchemas,
  'enforce-named-react-packages-imports': enforceNamedReactPackagesImports,
};
