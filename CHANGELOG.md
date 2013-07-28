## Unreleased
- Adds full support for navigating to module files by using `gf` on `require("any-module")`.
- Adds `.json` to `&suffixesadd` so you could use `gf` on `require("./package")` to open package.json.

## 0.1.1 (Jul 28, 2013)
- Removes an innocent but forgotten debugging line.

## 0.1.0 (Jul 28, 2013)
- First release to get the nodeballs rolling.
- Sets the filetype to JavaScript for files with Node's shebang (`#!`).
- Adds `.js` to `&suffixesadd` so you could use `gf` on `require("./foo")` to open `foo.js`.
