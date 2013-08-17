let s:suffixesadd = [".js", ".json"]

function! node#initialize(root)
	let b:node_root = a:root
	call s:initializeCommands()
	if &filetype == "javascript" | call s:initializeJavaScript() | endif
	silent doautocmd User Node
endfunction

function! s:initializeCommands()
	command! -bar -bang -nargs=1 -buffer Nedit 
		\ exe s:nedit(<q-args>, bufname("%"), "edit<bang>")
endfunction

function! s:initializeJavaScript()
	setl path-=/usr/include
	let &l:suffixesadd .= "," . join(s:suffixesadd, ",")
	let &l:include = '\<require(\(["'']\)\zs[^\1]\+\ze\1'
	let &l:includeexpr = s:snr() . "find(v:fname, bufname('%'))"

	nnoremap <buffer><silent> <Plug>NodeGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"))<CR>
	nnoremap <buffer><silent> <Plug>NodeSplitGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"), "split")<CR>
	nnoremap <buffer><silent> <Plug>NodeVSplitGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"), "vsplit")<CR>
	nnoremap <buffer><silent> <Plug>NodeTabGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"), "tab split")<CR>

	if !hasmapto("<Plug>NodeGotoFile")
		" Split gotofiles don't take a count for the new window's width, but for
		" opening the nth file. Though Node.vim doesn't support counts atm.
		nmap <buffer> gf <Plug>NodeGotoFile
		nmap <buffer> <C-w>f <Plug>NodeSplitGotoFile
		nmap <buffer> <C-w><C-f> <Plug>NodeSplitGotoFile
		nmap <buffer> <C-w>gf <Plug>NodeTabGotoFile
	endif
endfunction

function! s:snr()
	return matchstr(expand("<sfile>"), '.*\zs<SNR>\d\+_')
endfunction

function! s:find(name, from)
	let dir = isdirectory(a:from) ? a:from : fnamemodify(a:from, ":h")

	if a:name =~# '^/'
		let path = a:name
	elseif a:name =~# '^\v\.\.?(/|$)'
		let path = dir . "/" . a:name
	else
		let path = b:node_root . "/node_modules/" . a:name
	endif

	return s:findByPath(path)
endfunction

function! node#find(name, ...)
	let from = a:0 == 1 ? a:1 : bufname("%")
	return s:find(a:name, from)
endfunction

function! s:findByPath(path)
	" Node checks for files *before* directories, so see if the path does not
	" end with a slash or dots and try to match it as a file.
	if a:path !~# '\v/(\.\.?/?)?$'
		let path_with_suffix = s:pathWithSuffix(a:path)
		if !empty(path_with_suffix) | return path_with_suffix | endif
	endif

	if isdirectory(a:path) | return s:pathFromDirectory(a:path) | endif
endfunction

function! s:pathFromDirectory(path)
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
			let path = s:findByPath(a:path . "/" . main)
			if !empty(path) | return path | endif
		endif
	endif

	" We need to check for ./index.js's existence here rather than leave it to
	" the caller, because otherwise we can't distinguish if this ./index was
	" from the directory defaulting to ./index.js or it was the package.json
	" which referred to ./index, which in itself could mean both ./index.js and
	" ./index/index.js.
	return s:pathWithSuffix(a:path . "/index")
endfunction

function! s:mainFromPackage(path)
	for line in readfile(a:path)
		if line !~# '"main"\s*:' | continue | endif
		return matchstr(line, '"main"\s*:\s*"\zs[^"]\+\ze"')
	endfor
endfunction

function! s:pathWithSuffix(path)
	for suffix in s:uniq([""] + s:suffixesadd + split(&l:suffixesadd, ","))
		let path = a:path . suffix
		if filereadable(path) | return path | endif
	endfor
endfunction

function! s:edit(name, from, ...)
	if empty(a:name) | return | endif
	let dir = isdirectory(a:from) ? a:from : fnamemodify(a:from, ":h")
	let command = a:0 == 1 ? a:1 : "edit"

	" If just a plain filename with no directory part, check if it exists:
	if a:name !~# '^\v(/|\./|\.\./)' && filereadable(dir . "/" . a:name)
		let path = dir . "/" . a:name
	else
		let path = s:find(a:name, dir)
	end

	if empty(path)
		return s:error("E447: Can't find file \"" . a:name . "\" in path")
	endif

	exe command . " " . fnameescape(path)
endfunction

function! s:nedit(name, from, ...)
	let command = a:0 == 1 ? a:1 : "edit"
	let name = a:name =~# '^/' ? "." . a:name : a:name
	call s:edit(name, b:node_root, command)
endfunction

" Using the built-in :echoerr prints a stacktrace, which isn't that nice.
function! s:error(msg)
	echohl ErrorMsg
	echomsg a:msg
	echohl NONE
	let v:errmsg = a:msg
endfunction

function! s:uniq(list)
	let list = reverse(copy(a:list))
	return reverse(filter(list, "index(list, v:val, v:key + 1) == -1"))
endfunction
