function! node#lib#find(name, from)
	return s:resolve(s:absolutize(a:name, a:from))
endfunction

let s:ABSPATH = '^/'
let s:RELPATH = '\v^\.\.?(/|$)'
let s:MODULE = '\v^(/|\.\.?(/|$))@!'

function! s:absolutize(name, from)
	if a:name =~# s:ABSPATH
		return a:name
	elseif a:name =~# s:RELPATH
		let dir = isdirectory(a:from) ? a:from : fnamemodify(a:from, ":h")
		return dir . "/" . a:name
	else
		return b:node_root . "/node_modules/" . a:name
	endif
endfunction

function! s:resolve(path)
	" Node checks for files *before* directories, so see if the path does not
	" end with a slash or dots and try to match it as a file.
	if a:path !~# '\v/(\.\.?/?)?$'
		let path_with_suffix = s:resolveSuffix(a:path)
		if !empty(path_with_suffix) | return path_with_suffix | endif
	endif

	if isdirectory(a:path) | return s:resolveFromDirectory(a:path) | endif
endfunction

function! s:resolveFromDirectory(path)
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
			let path = s:resolve(a:path . "/" . main)
			if !empty(path) | return path | endif
		endif
	endif

	" We need to check for ./index.js's existence here rather than leave it to
	" the caller, because otherwise we can't distinguish if this ./index was
	" from the directory defaulting to ./index.js or it was the package.json
	" which referred to ./index, which in itself could mean both ./index.js and
	" ./index/index.js.
	return s:resolveSuffix(a:path . "/index")
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
let s:GLOB_RET_LIST = 1

function! node#lib#glob(dir)
	let matches = []

	if a:dir =~# s:ABSPATH
		let matches += s:glob(a:dir, 0)
	endif

	if empty(a:dir) || a:dir =~# s:MODULE
		let root = b:node_root . "/node_modules"
		let matches += s:glob(empty(a:dir) ? root : root . "/" . a:dir, root)
	endif

	if empty(a:dir) || a:dir =~# s:RELPATH
		let root = b:node_root
		let relatives = s:glob(empty(a:dir) ? root : root . "/" . a:dir, root)

		"call map(relatives, "substitute(v:val, '^\./\./', './', '')")
		if empty(a:dir) | call map(relatives, "'./' . v:val") | endif
		call filter(relatives, "v:val !~# '^\\.//*node_modules/$'")

		let matches += relatives
	endif

	return [a:dir, b:node_root, matches]

	return matches
endfunction

function! s:glob(path, stripPrefix)
	" Remove a single trailing slash because we're adding one with the glob.
	let path = substitute(a:path, '/$', "", "")
	let list = glob(fnameescape(path)."/*", s:GLOB_WILDIGNORE, s:GLOB_RET_LIST)

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
