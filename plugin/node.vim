if exists("g:loaded_node") || &cp || v:version < 700 | finish | endif
let g:loaded_node = 1

function! s:detect(path)
	if exists("b:node_root") | return | en
	let path = a:path

	while 1
		let is_node = 0
		let is_node = is_node || filereadable(path . "/package.json")
		let is_node = is_node || isdirectory(path . "/node_modules")
		if is_node | return s:init(path) | endif

		let parent = fnamemodify(path, ":h")
		if parent == path | return | endif
		let path = parent
	endwhile
endfunction

function! s:init(root)
	let b:node_root = a:root

	if &filetype == "javascript"
		setl suffixesadd+=.js
		exe "setl includeexpr=" . s:snr() . "find(v:fname)"
	endif
endfunction

function! s:snr()
	return matchstr(expand("<sfile>"), '<SNR>\d\+_')
endfunction

function! s:find(name)
	" Skip relative or absolute paths.
	if a:name =~# '^\(/\|\./\|\.\./\)' | return a:name | endif

	let path = b:node_root . "/node_modules/" . a:name
	if isdirectory(path) | let path = s:pathFromDirectory(path) | endif
	let path = s:pathWithSuffix(path)
	if !empty(path) | return path | endif

	return a:name
endfunction

function! s:pathFromDirectory(path)
	" Node.js checks for package.json in every directory, not just the
	" module's parent. According to:
	" http://nodejs.org/api/modules.html#modules_all_together

	if filereadable(a:path . "/package.json")
		" Node expects main to refer to a file, so no directory resolving:
		let main = s:pathFromPackage(a:path . "/package.json")
		if !empty(main) | return a:path . "/" . main | endif
	endif

	return a:path . "/index"
endfunction

function! s:pathFromPackage(path)
	for line in readfile(a:path)
		if line !~# '"main"\s*:' | continue | endif
		return matchstr(line, '"main"\s*:\s*"\zs[^"]\+\ze"')
	endfor
endfunction

function! s:pathWithSuffix(path)
	for suffix in ([""] + split(&suffixesadd, ","))
		let path = a:path . suffix
		if filereadable(path) | return path | endif
	endfor
endfunction

augroup Node
	au!
	au BufRead,BufNewFile * call s:detect(expand("<amatch>:p"))
augroup END
