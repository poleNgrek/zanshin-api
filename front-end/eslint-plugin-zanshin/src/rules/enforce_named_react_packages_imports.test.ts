import { AST_NODE_TYPES } from '@typescript-eslint/utils';
import { describe } from 'bun:test';
import { createRuleTester } from '../rule_tester';
import { enforceNamedReactPackagesImports } from './enforce_named_react_packages_imports';

describe('enforce-named-react-imports', () => {
  const ruleTester = createRuleTester();

  ruleTester.run('enforce-named-react-packages-imports', enforceNamedReactPackagesImports, {
    valid: [
      // React - Basic named imports
      {
        code: "import { useState, useEffect } from 'react';"
      },
      {
        code: "import { startTransition } from 'react';"
      },
      {
        code: "import { Component, PureComponent } from 'react';"
      },
      // React - Multiple named imports
      {
        code: "import { useState, useEffect, useCallback, useMemo } from 'react';"
      },
      // React - Renamed imports
      {
        code: "import { useState as useStateHook } from 'react';"
      },
      // React - Type imports (should be ignored)
      {
        code: "import type { FC } from 'react';"
      },
      // ReactDOM - Named imports
      {
        code: "import { createRoot } from 'react-dom';"
      },
      {
        code: "import { hydrateRoot, createRoot } from 'react-dom';"
      },
      // ReactDOM - Named imports from client
      {
        code: "import { createRoot } from 'react-dom/client';"
      },
      // No React import at all
      {
        code: "import { something } from 'other-library';"
      },
      // Empty file
      {
        code: ''
      },
      // React - Type namespace usage is allowed when using named imports
      {
        code: "import type { ReactNode } from 'react';\ntype Props = { children: ReactNode };"
      },
      {
        // React. type usage via default import is handled by the main default-import rule
        // — here we just confirm the valid: no default import, no bare React.* usage
        code: "import { useState } from 'react';\nconst [x] = useState(0);"
      }
    ],
    invalid: [
      // React - Basic default import with no usage - should remove the import
      {
        code: "import React from 'react';",
        output: '',
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // React - Default import with existing named imports
      {
        code: "import React, { useEffect } from 'react';",
        output: "import { useEffect } from 'react';",
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // React - Default import with React.useState usage
      {
        code: `import React from 'react';
const [count, setCount] = React.useState(0);`,
        output: `import { useState } from 'react';
const [count, setCount] = useState(0);`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // React - Default import with React.useEffect usage
      {
        code: `import React from 'react';
React.useEffect(() => {}, []);`,
        output: `import { useEffect } from 'react';
useEffect(() => {}, []);`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // React - Multiple React.* usages
      {
        code: `import React from 'react';
const [count, setCount] = React.useState(0);
React.useEffect(() => {}, []);
const memoized = React.useMemo(() => count * 2, [count]);`,
        output: `import { useEffect, useMemo, useState } from 'react';
const [count, setCount] = useState(0);
useEffect(() => {}, []);
const memoized = useMemo(() => count * 2, [count]);`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // React - React.createElement usage
      {
        code: `import React from 'react';
const element = React.createElement('div', null, 'Hello');`,
        output: `import { createElement } from 'react';
const element = createElement('div', null, 'Hello');`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // React - React.Component class
      {
        code: `import React from 'react';
class MyComponent extends React.Component {}`,
        output: `import { Component } from 'react';
class MyComponent extends Component {}`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // React - Mixed: default import with existing named imports and React.* usage
      {
        code: `import React, { useState } from 'react';
React.useEffect(() => {}, []);
const [count, setCount] = useState(0);`,
        output: `import { useEffect, useState } from 'react';
useEffect(() => {}, []);
const [count, setCount] = useState(0);`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // React - React.* in nested function
      {
        code: `import React from 'react';
function MyComponent() {
  React.useEffect(() => {
    React.useCallback(() => {}, []);
  }, []);
}`,
        output: `import { useCallback, useEffect } from 'react';
function MyComponent() {
  useEffect(() => {
    useCallback(() => {}, []);
  }, []);
}`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // React - React.createContext
      {
        code: `import React from 'react';
const MyContext = React.createContext(null);`,
        output: `import { createContext } from 'react';
const MyContext = createContext(null);`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // ReactDOM - Basic default import with no usage - should remove the import
      {
        code: "import ReactDOM from 'react-dom';",
        output: '',
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // ReactDOM - Default import with ReactDOM.render usage
      {
        code: `import ReactDOM from 'react-dom';
const root = document.getElementById('root');
ReactDOM.render(null, root);`,
        output: `import { render } from 'react-dom';
const root = document.getElementById('root');
render(null, root);`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // ReactDOM - Default import with ReactDOM.createRoot usage
      {
        code: `import ReactDOM from 'react-dom';
const root = ReactDOM.createRoot(document.getElementById('root'));`,
        output: `import { createRoot } from 'react-dom';
const root = createRoot(document.getElementById('root'));`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // ReactDOM - Default import with ReactDOM.hydrate usage
      {
        code: `import ReactDOM from 'react-dom';
const root = document.getElementById('root');
ReactDOM.hydrate(null, root);`,
        output: `import { hydrate } from 'react-dom';
const root = document.getElementById('root');
hydrate(null, root);`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // ReactDOM - Multiple ReactDOM.* usages
      {
        code: `import ReactDOM from 'react-dom';
const root = ReactDOM.createRoot(document.getElementById('root'));
ReactDOM.flushSync(() => {
  console.log('flushed');
});`,
        output: `import { createRoot, flushSync } from 'react-dom';
const root = createRoot(document.getElementById('root'));
flushSync(() => {
  console.log('flushed');
});`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // ReactDOM - Default with existing named imports
      {
        code: "import ReactDOM, { createPortal } from 'react-dom';",
        output: "import { createPortal } from 'react-dom';",
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // ReactDOM - Mixed usage with named and default
      {
        code: `import ReactDOM, { createPortal } from 'react-dom';
const root = ReactDOM.createRoot(document.getElementById('root'));
const portal = createPortal(null, document.body);`,
        output: `import { createPortal, createRoot } from 'react-dom';
const root = createRoot(document.getElementById('root'));
const portal = createPortal(null, document.body);`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // Both React and ReactDOM with default imports
      {
        code: `import React from 'react';
import ReactDOM from 'react-dom';
const [count, setCount] = React.useState(0);
const root = document.getElementById('root');
ReactDOM.render(null, root);`,
        output: `import { useState } from 'react';
import { render } from 'react-dom';
const [count, setCount] = useState(0);
const root = document.getElementById('root');
render(null, root);`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          },
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // ReactDOM - findDOMNode (legacy API)
      {
        code: `import ReactDOM from 'react-dom';
const node = ReactDOM.findDOMNode(this);`,
        output: `import { findDOMNode } from 'react-dom';
const node = findDOMNode(this);`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },
      // ReactDOM - unmountComponentAtNode
      {
        code: `import ReactDOM from 'react-dom';
ReactDOM.unmountComponentAtNode(document.getElementById('root'));`,
        output: `import { unmountComponentAtNode } from 'react-dom';
unmountComponentAtNode(document.getElementById('root'));`,
        errors: [
          {
            messageId: 'useNamedImport',
            type: AST_NODE_TYPES.ImportDeclaration
          }
        ]
      },

      // ── React namespace type usages (React.ReactNode etc.) ────────────────

      // Default import present: React.ReactNode in type position → import type { ReactNode }
      {
        code: `import React from 'react';
type Props = { children: React.ReactNode };`,
        output: `import type { ReactNode } from 'react';
type Props = { children: ReactNode };`,
        errors: [{ messageId: 'useNamedImport', type: AST_NODE_TYPES.ImportDeclaration }]
      },

      // Default import present: mix of runtime + type usage
      {
        code: `import React from 'react';
const [x, setX] = React.useState(0);
type Props = { children: React.ReactNode };`,
        output: `import { type ReactNode, useState } from 'react';
const [x, setX] = useState(0);
type Props = { children: ReactNode };`,
        errors: [{ messageId: 'useNamedImport', type: AST_NODE_TYPES.ImportDeclaration }]
      },

      // Default import present: multiple type usages only → import type { ... }
      {
        code: `import React from 'react';
type Props = { children: React.ReactNode; style: React.CSSProperties };`,
        output: `import type { CSSProperties, ReactNode } from 'react';
type Props = { children: ReactNode; style: CSSProperties };`,
        errors: [{ messageId: 'useNamedImport', type: AST_NODE_TYPES.ImportDeclaration }]
      },

      // No default import: bare React.ReactNode, merges into existing value import
      // with inline `type` specifier — alphabetical sort, types mixed with values
      {
        code: `import { useState } from 'react';
const [open, setOpen] = useState(false);
type Props = { children: React.ReactNode; style: React.CSSProperties };`,
        output: `import { type CSSProperties, type ReactNode, useState } from 'react';
const [open, setOpen] = useState(false);
type Props = { children: ReactNode; style: CSSProperties };`,
        // Single report covering all bare type usages in the file
        errors: [
          {
            messageId: 'noNamespaceType',
            data: { typeName: 'ReactNode' },
            type: AST_NODE_TYPES.TSTypeReference
          }
        ]
      },

      // No default import: bare React.ReactNode in type position, merges with inline `type`
      {
        code: `import { useState } from 'react';
type Props = { children: React.ReactNode };`,
        output: `import { type ReactNode, useState } from 'react';
type Props = { children: ReactNode };`,
        errors: [
          {
            messageId: 'noNamespaceType',
            data: { typeName: 'ReactNode' },
            type: AST_NODE_TYPES.TSTypeReference
          }
        ]
      },

      // No default import, no existing react import at all → new `import type { ... }`
      {
        code: 'type Props = { children: React.ReactNode };',
        output: "import type { ReactNode } from 'react';\ntype Props = { children: ReactNode };",
        errors: [
          {
            messageId: 'noNamespaceType',
            data: { typeName: 'ReactNode' },
            type: AST_NODE_TYPES.TSTypeReference
          }
        ]
      },

      // No default import, multiple bare React.Foo types, no existing import → single report
      {
        code: 'type Props = { children: React.ReactNode; style: React.CSSProperties };',
        output:
          "import type { CSSProperties, ReactNode } from 'react';\ntype Props = { children: ReactNode; style: CSSProperties };",
        errors: [
          {
            messageId: 'noNamespaceType',
            data: { typeName: 'ReactNode' },
            type: AST_NODE_TYPES.TSTypeReference
          }
        ]
      },

      // ── React.JSX.Element (depth-2 qualified name) ────────────────────────

      // Default import + React.JSX.Element → import type { JSX }, use site becomes JSX.Element
      {
        code: `import React from 'react';
type Props = { child: React.JSX.Element };`,
        output: `import type { JSX } from 'react';
type Props = { child: JSX.Element };`,
        errors: [{ messageId: 'useNamedImport', type: AST_NODE_TYPES.ImportDeclaration }]
      },

      // Default import + mix of depth-1 and depth-2
      {
        code: `import React from 'react';
type Props = { child: React.JSX.Element; node: React.ReactNode };`,
        output: `import type { JSX, ReactNode } from 'react';
type Props = { child: JSX.Element; node: ReactNode };`,
        errors: [{ messageId: 'useNamedImport', type: AST_NODE_TYPES.ImportDeclaration }]
      },

      // Default import + runtime + depth-2 type
      {
        code: `import React from 'react';
const [x, setX] = React.useState(0);
type Props = { child: React.JSX.Element };`,
        output: `import { type JSX, useState } from 'react';
const [x, setX] = useState(0);
type Props = { child: JSX.Element };`,
        errors: [{ messageId: 'useNamedImport', type: AST_NODE_TYPES.ImportDeclaration }]
      },

      // Bare React.JSX.Element, no existing react import → prepend import type { JSX }
      {
        code: 'type Props = { child: React.JSX.Element };',
        output: "import type { JSX } from 'react';\ntype Props = { child: JSX.Element };",
        errors: [
          {
            messageId: 'noNamespaceType',
            data: { typeName: 'JSX.Element' },
            type: AST_NODE_TYPES.TSTypeReference
          }
        ]
      },

      // Bare React.JSX.Element with existing value import → inline type JSX
      {
        code: `import { useState } from 'react';
type Props = { child: React.JSX.Element };`,
        output: `import { type JSX, useState } from 'react';
type Props = { child: JSX.Element };`,
        errors: [
          {
            messageId: 'noNamespaceType',
            data: { typeName: 'JSX.Element' },
            type: AST_NODE_TYPES.TSTypeReference
          }
        ]
      },

      // Bare mix of depth-1 and depth-2 → single report, single combined fix
      {
        code: 'type Props = { child: React.JSX.Element; node: React.ReactNode };',
        output:
          "import type { JSX, ReactNode } from 'react';\ntype Props = { child: JSX.Element; node: ReactNode };",
        errors: [
          {
            messageId: 'noNamespaceType',
            data: { typeName: 'JSX.Element' },
            type: AST_NODE_TYPES.TSTypeReference
          }
        ]
      }
    ]
  });
});
