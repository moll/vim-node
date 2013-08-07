## Unreleased
- Adds `Node` autocommand.  
  Use it with `autocmd User Node` to customize settings for files in Node projects.

## 0.5.0 (Aug 5, 2013)
- Adds `&include` pattern so Vim can recognize included/required files, e.g. for looking up keywords with `[I`.
- Cleans `&path` from `/usr/include` for JavaScript files.
- Adds a new superb `gf` handler to handle all relative and module paths, incl. support for `require(".")` to open `./index.js`. This is spot on how Node.js finds your requires.
- Adds `<Plug>NodeGotoFile` should you want to remap Node.vim's file opener.
- Opens files before directories should both, e.g. `./foo.js` and `./foo`, exist. This matches Node.js's behavior.
- Adds a full automated integration test suite to Node.vim which is freaking amazing!

## 0.2.0 (Jul 28, 2013)
- Adds full support for navigating to module files by using `gf` on `require("any-module")`.
- Adds `.json` to `&suffixesadd` so you could use `gf` on `require("./package")` to open package.json.

## 0.1.1 (Jul 28, 2013)
- Removes an innocent but forgotten debugging line.

## 0.1.0 (Jul 28, 2013)
- First release to get the nodeballs rolling.
- Sets the filetype to JavaScript for files with Node's shebang (`#!`).
- Adds `.js` to `&suffixesadd` so you could use `gf` on `require("./foo")` to open `foo.js`.
