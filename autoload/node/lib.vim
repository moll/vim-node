let s:ABSPATH = '^/'
let s:RELPATH = '\v^\.\.?(/|$)'
let s:MODULE = '\v^(/|\.\.?(/|$))@!'

" Damn Netrw can't handle HTTPS at all. It's 2013! Insecure bastard!
let s:CORE_URL_PREFIX = "http://rawgit.com/nodejs/node"
let s:CORE_MODULES = ["_debugger", "_http_agent", "_http_client",
	\ "_http_common", "_http_incoming", "_http_outgoing", "_http_server",
	\ "_linklist", "_stream_duplex", "_stream_passthrough", "_stream_readable",
	\ "_stream_transform", "_stream_writable", "_tls_legacy", "_tls_wrap",
	\ "assert", "buffer", "child_process", "cluster", "console", "constants",
	\ "crypto", "dgram", "dns", "domain", "events", "freelist", "fs", "http",
	\ "https", "module", "net", "node", "os", "path", "punycode", "querystring",
	\ "readline", "repl", "smalloc", "stream", "string_decoder", "sys",
	\ "timers", "tls", "tty", "url", "util", "vm", "zlib"]

" A vimscript implementation of the node.js module resolution algorithm.
" https://nodejs.org/api/modules.html#modules_all_together
"
" require(a:name) from module at path a:from
" 1. If a:name is a core module,
"		a. return the core module
"		b. STOP
" 2. If a:name begins with '/'
"		a. set a:from to be the filesystem root
" 3. If a:name begins with './' or '/' or '../'
"		a. LOAD_AS_FILE(a:from + a:name)
"		b. LOAD_AS_DIRECTORY(a:from + a:name)
" 4. LOAD_NODE_MODULES(a:name, dirname(a:from))
" 5. THROW "not found"
function! node#lib#find(name, from)
	if index(s:CORE_MODULES, a:name) != -1
		let l:version = node#lib#version()
		let l:version = empty(l:version) ? "master" : "v" . l:version
		let l:dir = a:name == "node" ? "src" : "lib"
		return s:CORE_URL_PREFIX ."/". l:version ."/". l:dir ."/". a:name .".js"
	endif

	let request = s:getModulePath(a:name, a:from)
	if !empty(request)
		let asFile = s:loadAsFile(request)
		if !empty(asFile) | return asFile | endif

		let asDirectory = s:loadAsDirectory(request)
		if !empty(asDirectory) | return asDirectory | endif
	endif

	let asNodeModule = s:loadNodeModules(a:name, s:dirname(a:from))
	if !empty(asNodeModule) | return asNodeModule | endif
endfunction

" LOAD_AS_FILE(X)
" 1. If X is a file, load X as JavaScript text.	STOP
" 2. If X.js is a file, load X.js as JavaScript text.	STOP
" 3. If X.json is a file, parse X.json to a JavaScript Object.	STOP
" 4. If X.node is a file, load X.node as binary addon.	STOP
function! s:loadAsFile(path)
	if a:path !~# '\v/(\.\.?/?)?$'
		let path_with_suffix = s:resolveSuffix(a:path)
		if !empty(path_with_suffix) | return path_with_suffix | endif
	endif
endfunction

" LOAD_INDEX(X)
" 1. If X/index.js is a file, load X/index.js as JavaScript text.	STOP
" 2. If X/index.json is a file, parse X/index.json to a JavaScript object. STOP
" 3. If X/index.node is a file, load X/index.node as binary addon.	STOP
function! s:loadIndex(path)
	return s:resolveSuffix(a:path . "/index")
endfunction

" LOAD_AS_DIRECTORY(X)
" 1. If X/package.json is a file,
"		a. Parse X/package.json, and look for "main" field.
"		b. let M = X + (json main field)
"		c. LOAD_AS_FILE(M)
"		d. LOAD_INDEX(M)
" 2. LOAD_INDEX(X)
function! s:loadAsDirectory(path)
	" Node.js checks for package.json in every directory, not just the
	" module's parent. According to:
	" http://nodejs.org/api/modules.html#modules_all_together
	if filereadable(a:path . "/package.json")
		" Turns out, even though Node says it does not support directories in
		" main, it does.
		" NOTE: If package.json's main is empty or refers to a non-existent file,
		" ./index.js is still tried.
		let main = s:mainFromPackage(a:path . "/package.json")

		if !empty(main) && main != ""
			let path = a:path . "/" . main
			let asFile = s:loadAsFile(path)
			if !empty(asFile) | return asFile | endif

			let asIndex = s:loadIndex(path)
			if !empty(asIndex) | return asIndex | endif
		endif
	endif

	return s:loadIndex(a:path)
endfunction

" LOAD_NODE_MODULES(X, START)
" 1. let DIRS=NODE_MODULES_PATHS(START)
" 2. for each DIR in DIRS:
"		a. LOAD_AS_FILE(DIR/X)
"		b. LOAD_AS_DIRECTORY(DIR/X)
function! s:loadNodeModules(x, start)
	let dirs = s:nodeModulePaths(a:start)
	for dir in dirs
		let path = dir . "/" . a:x
		let asFile = s:loadAsFile(path)
		if !empty(asFile) | return asFile | endif

		let asDirectory = s:loadAsDirectory(path)
		if !empty(asDirectory) | return asDirectory | endif
	endfor
endfunction

" NODE_MODULES_PATHS(START)
" 1. let PARTS = path split(START)
" 2. let I = count of PARTS - 1
" 3. let DIRS = []
" 4. while I >= 0,
"		a. if PARTS[I] = "node_modules" CONTINUE
"		b. DIR = path join(PARTS[0 .. I] + "node_modules")
"		c. DIRS = DIRS + DIR
"		d. let I = I - 1
" 5. return DIRS
function! s:nodeModulePaths(start)
	let parts = split(a:start, '/')

	" We want to keep the leading slash of an absolute path
	if a:start =~# s:ABSPATH
		let parts[0] = '/' . parts[0]
	endif

	let i = len(parts) - 1
	let dirs = []
	while i >= 0
		if parts[i] == 'node_modules' | continue | endif
		let dir = join(parts[0:i] + ['node_modules'], '/')
		let dirs += [dir]
		let i = i - 1
	endwhile

	" Add support for NODE_PATH
	let NODE_PATH = $NODE_PATH
	if !empty(NODE_PATH)
		let dirs += [NODE_PATH]
	endif

	" Add support for configured NODE_PATH
	if !empty(g:vim_node#node_path)
		let dirs += g:vim_node#node_path
	endif

	return dirs
endfunction

function! s:getModulePath(name, from)
	if a:name =~# s:ABSPATH
		return a:name
	elseif a:name =~# s:RELPATH
		let dir = isdirectory(a:from) ? a:from : s:dirname(a:from)
		return dir . "/" . a:name
	endif
endfunction

function! s:dirname(path)
	return fnamemodify(a:path, ':h')
endfunction

function! node#lib#version()
	if exists("b:node_version") | return b:node_version | endif
	if !executable("node") | let b:node_version = "" | return | endif
	let b:node_version = matchstr(system("node --version"), '^v\?\zs[0-9.]\+')
	return b:node_version
endfunction

function! s:mainFromPackage(path)
	for line in readfile(a:path)
		if line !~# '"main"\s*:' | continue | endif
		return matchstr(line, '"main"\s*:\s*"\zs[^"]\+\ze"')
	endfor
endfunction

function! s:resolveSuffix(path)
	for suffix in s:uniq([""] + g:node#suffixesadd + split(&l:suffixesadd, ","))
		let path = a:path . suffix
		if filereadable(path) | return path | endif
	endfor
endfunction

let s:GLOB_WILDIGNORE = 1

function! node#lib#glob(name)
	let matches = []

	if empty(a:name)
		let matches += s:CORE_MODULES
	endif

	if empty(a:name) || a:name =~# s:MODULE
		let root = b:node_root . "/node_modules"
		let matches += s:glob(empty(a:name) ? root : root . "/" . a:name, root)
	endif

	if a:name =~# s:ABSPATH
		let matches += s:glob(a:name, 0)
	endif

	if empty(a:name) || a:name =~# s:RELPATH
		let root = b:node_root
		let relatives = s:glob(empty(a:name) ? root : root . "/" . a:name, root)

		"call map(relatives, "substitute(v:val, '^\./\./', './', '')")
		if empty(a:name) | call map(relatives, "'./' . v:val") | endif
		call filter(relatives, "v:val !~# '^\\.//*node_modules/$'")

		let matches += relatives
	endif

	return matches
endfunction

function! s:glob(path, stripPrefix)
	" Remove a single trailing slash because we're adding one with the glob.
	let path = substitute(a:path, '/$', "", "")
	" Glob() got the ability to return a list only in Vim 7.3.465. Using split
	" for compatibility.
	let list = split(glob(fnameescape(path)."/*", s:GLOB_WILDIGNORE), "\n")

	" Add slashes to directories, like /bin/ls.
	call map(list, "v:val . (isdirectory(v:val) ? '/' : '')")

	if !empty(a:stripPrefix)
		" Counting and removing bytes intentionally as there's no substr function
		" that takes character count, only bytes.
		let	prefix_length = len(a:stripPrefix) + 1
		return map(list, "strpart(v:val, prefix_length)")
	endif

	return list
endfunction

function! s:uniq(list)
	let list = reverse(copy(a:list))
	return reverse(filter(list, "index(list, v:val, v:key + 1) == -1"))
endfunction
