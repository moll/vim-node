function! node#initialize(root)
	let b:node_root = a:root
	if &filetype == "javascript" | call s:initializeJavaScript() | endif
endfunction

function! s:initializeJavaScript()
	setl suffixesadd+=.js,.json
	let &l:include = '\<require(\(["'']\)\zs[^\1]\+\ze\1'
	let &l:includeexpr = s:snr() . "find(v:fname, bufname('%'))"

	nnoremap <buffer><silent> <Plug>NodeGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"))<CR>
	if !hasmapto("<Plug>NodeGotoFile")
		nmap <buffer> gf <Plug>NodeGotoFile
	endif
endfunction

function! s:snr()
	return matchstr(expand("<sfile>"), '.*\zs<SNR>\d\+_')
endfunction

function! s:find(name, from)
	let dir = isdirectory(a:from) ? a:from : fnamemodify(a:from, ":h")

	if a:name =~# '^/'
		let path = a:name
	elseif a:name =~# '^\.\.\?\(/\|$\)'
		let path = dir . "/" . a:name
	else
		let path = b:node_root . "/node_modules/" . a:name
	endif

	if isdirectory(path) | let path = s:pathFromDirectory(path) | endif
	let path = s:pathWithSuffix(path)
	if !empty(path) | return path | endif
endfunction

function! s:edit(name, from)
	if empty(a:name) | return | endif
	let dir = isdirectory(a:from) ? a:from : fnamemodify(a:from, ":h")

	" If just a plain filename with no directory part, check if it exists:
	if a:name !~# '^\(/\|\./\|\.\./\)' && filereadable(dir . "/" . a:name)
		let path = dir . "/" . a:name
	else
		let path = s:find(a:name, dir)
	end

	if empty(path)
		return s:error("E447: Can't find file \"" . a:name . "\" in path")
	endif

	exe "edit " . fnameescape(path)
endfunction

function! s:pathFromDirectory(path)
	" Node.js checks for package.json in every directory, not just the
	" module's parent. According to:
	" http://nodejs.org/api/modules.html#modules_all_together

	if filereadable(a:path . "/package.json")
		let main = s:mainFromPackage(a:path . "/package.json")

		if !empty(main)
			" Turns out, even though Node says it does not support directories in
			" main, it does.
			let path = a:path . "/" . main 
			return isdirectory(path) ? s:pathFromDirectory(path) : path
		endif
	endif

	return a:path . "/index"
endfunction

function! s:mainFromPackage(path)
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

" Using the built-in :echoerr prints a stacktrace, which isn't that nice.
function! s:error(msg)
	echohl ErrorMsg
	echomsg a:msg
	echohl NONE
	let v:errmsg = a:msg
endfunction
