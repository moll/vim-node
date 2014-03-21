let node#suffixesadd = [".js", ".json"]
let node#filetypes = ["javascript", "json"]

function! node#initialize(root)
	let b:node_root = a:root
	if index(g:node#filetypes, &ft) > -1 | call s:initializeJavaScript() | en
	silent doautocmd User Node
endfunction

function! node#initializeCommands()
	command! -bar -bang -nargs=1 -buffer -complete=customlist,s:complete Nedit
		\ exe s:nedit(<q-args>, bufname("%"), "edit<bang>")
	command! -bar -bang -nargs=1 -buffer -complete=customlist,s:complete Nopen
		\ exe s:nopen(<q-args>, bufname("%"), "edit<bang>")

	command! -nargs=0 -complete=customlist,s:complete NodeGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"))
	command! -nargs=0 -complete=customlist,s:complete NodeSplitGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"), "split")
	command! -nargs=0 -complete=customlist,s:complete NodeVSplitGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"), "vsplit")
	command! -nargs=0 -complete=customlist,s:complete NodeTabGotoFile
		\ :call <SID>edit(expand("<cfile>"), bufname("%"), "tab split")
endfunction

function! s:initializeJavaScript()
	setl path-=/usr/include
	let &l:suffixesadd .= "," . join(g:node#suffixesadd, ",")
	let &l:include = '\<require(\(["'']\)\zs[^\1]\+\ze\1'
	let &l:includeexpr = "node#lib#find(v:fname, bufname('%'))"
endfunction

function! s:edit(name, from, ...)
	if empty(a:name) | return | endif
	let dir = isdirectory(a:from) ? a:from : fnamemodify(a:from, ":h")
	let command = a:0 == 1 ? a:1 : "edit"

	" If just a plain filename with no directory part, check if it exists:
	if a:name !~# '^\v(/|\./|\.\./)' && filereadable(dir . "/" . a:name)
		let path = dir . "/" . a:name
	else
		let path = node#lib#find(a:name, dir)
	end

	if empty(path)
		normal gf
  else
		exe command . " " . fnameescape(path)
	endif
endfunction

function! s:nedit(name, from, ...)
	let command = a:0 == 1 ? a:1 : "edit"
	call s:edit(a:name, b:node_root, command)
endfunction

function! s:nopen(name, from, ...)
	let command = a:0 == 1 ? a:1 : "edit"
	call s:nedit(a:name, a:from, command)
	if exists("b:node_root") | exe "lcd " . fnameescape(b:node_root) | endif
endfunction

function! s:complete(arg, cmd, cursor)
	let matches = node#lib#glob(s:dirname(a:arg))

	" Show private modules (_*) only if explicitly asked:
	if a:arg[0] != "_" | call filter(matches, "v:val[0] != '_'") | endif

	let filter = "stridx(v:val, a:arg) == 0"
	let ignorecase = 0
	let ignorecase = ignorecase || exists("&fileignorecase") && &fileignorecase
	let ignorecase = ignorecase || exists("&wildignorecase") && &wildignorecase
	if ignorecase | let filter = "stridx(tolower(v:val),tolower(a:arg)) == 0" | en

	return filter(matches, filter)
endfunction

function! s:dirname(path)
	let dirname = fnamemodify(a:path, ":h")
	if dirname == "." | return "" | endif

	" To not change the amount of final consecutive slashes, using this
	" dirname/basename trick:
	let basename = fnamemodify(a:path, ":t")
	return a:path[0 : 0 - len(basename) - 1]
endfunction

" Using the built-in :echoerr prints a stacktrace, which isn't that nice.
function! s:error(msg)
	echohl ErrorMsg
	echomsg a:msg
	echohl NONE
	let v:errmsg = a:msg
endfunction
