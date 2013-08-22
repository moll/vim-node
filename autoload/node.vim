let node#suffixesadd = [".js", ".json"]
let node#filetypes = ["javascript", "json"]

function! node#initialize(root)
	let b:node_root = a:root
	call s:initializeCommands()
	if index(g:node#filetypes, &ft) > -1 | call s:initializeJavaScript() | en
	silent doautocmd User Node
endfunction

function! s:initializeCommands()
	command! -bar -bang -nargs=1 -buffer -complete=customlist,s:complete Nedit
		\ exe s:nedit(<q-args>, bufname("%"), "edit<bang>")
	command! -bar -bang -nargs=1 -buffer -complete=customlist,s:complete Nopen
		\ exe s:nopen(<q-args>, bufname("%"), "edit<bang>")

	nnoremap <buffer><silent> <Plug>NodeGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"))<CR>
	nnoremap <buffer><silent> <Plug>NodeSplitGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"), "split")<CR>
	nnoremap <buffer><silent> <Plug>NodeVSplitGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"), "vsplit")<CR>
	nnoremap <buffer><silent> <Plug>NodeTabGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"), "tab split")<CR>
endfunction

function! s:initializeJavaScript()
	setl path-=/usr/include
	let &l:suffixesadd .= "," . join(g:node#suffixesadd, ",")
	let &l:include = '\<require(\(["'']\)\zs[^\1]\+\ze\1'
	let &l:includeexpr = "node#find(v:fname, bufname('%'))"

	if !hasmapto("<Plug>NodeGotoFile")
		" Split gotofiles don't take a count for the new window's width, but for
		" opening the nth file. Though Node.vim doesn't support counts atm.
		nmap <buffer> gf <Plug>NodeGotoFile
		nmap <buffer> <C-w>f <Plug>NodeSplitGotoFile
		nmap <buffer> <C-w><C-f> <Plug>NodeSplitGotoFile
		nmap <buffer> <C-w>gf <Plug>NodeTabGotoFile
	endif
endfunction

function! node#find(name, ...)
	let from = a:0 == 1 ? a:1 : bufname("%")
	return node#lib#find(a:name, from)
endfunction

function! s:edit(name, from, ...)
	if empty(a:name) | return | endif
	let dir = isdirectory(a:from) ? a:from : fnamemodify(a:from, ":h")
	let command = a:0 == 1 ? a:1 : "edit"

	" If just a plain filename with no directory part, check if it exists:
	if a:name !~# '^\v(/|\./|\.\./)' && filereadable(dir . "/" . a:name)
		let path = dir . "/" . a:name
	else
		let path = node#find(a:name, dir)
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

function! s:nopen(name, from, ...)
	let command = a:0 == 1 ? a:1 : "edit"
	call s:nedit(a:name, a:from, command)
	if exists("b:node_root") | exe "lcd " . fnameescape(b:node_root) | endif
endfunction

function! s:complete(arg, cmd, cursor)
	let possibilities = []

	if a:arg =~# '^/'
	elseif a:arg =~# '^\v\.\.?(/|$)'
	else
		let path = b:node_root . "/node_modules/"
		let possibilities = glob(fnameescape(path) . "/*", 1, 1)
		call map(possibilities, "fnamemodify(v:val, ':t')")
	endif

	call filter(possibilities, "stridx(v:val, a:arg) == 0")
	return possibilities
endfunction

" Using the built-in :echoerr prints a stacktrace, which isn't that nice.
function! s:error(msg)
	echohl ErrorMsg
	echomsg a:msg
	echohl NONE
	let v:errmsg = a:msg
endfunction
