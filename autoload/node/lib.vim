function! node#lib#find(name, from)
	return s:resolve(s:absolutize(a:name, a:from))
endfunction

function! s:absolutize(name, from)
	if a:name =~# '^/'
		return a:name
	elseif a:name =~# '^\v\.\.?(/|$)'
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
let s:GLOB_RETURN_LIST = 1

function! node#lib#glob(dir)
	" Remove a single trailing slash, but keep extra ones.
	let dir = substitute(a:dir, '/$', "", "")

	if dir =~# '^/'
		" Not handled for now.
	elseif dir =~# '^\v\.\.?(/|$)'
		" Not handled for now.
	else
		let root = b:node_root . "/node_modules"
		let path = empty(dir) ? root : root . "/" . dir
		let glob = fnameescape(path) . "/*"
		let matches = glob(glob, s:GLOB_WILDIGNORE, s:GLOB_RETURN_LIST)

		call map(matches, "v:val . (isdirectory(v:val) ? '/' : '')")
		" Counting and removing bytes intentionally as there's no substr function
		" that takes character count, only bytes.
		call map(matches, "strpart(v:val, len(root) + 1)")

		return matches
	endif
endfunction

function! s:uniq(list)
	let list = reverse(copy(a:list))
	return reverse(filter(list, "index(list, v:val, v:key + 1) == -1"))
endfunction
