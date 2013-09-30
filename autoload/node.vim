let node#suffixesadd = [".js", ".json"]
let node#filetypes = ["javascript", "json"]

let node#coreModules = ["_debugger", "_http_agent", "_http_client",
	\ "_http_common", "_http_incoming", "_http_outgoing", "_http_server",
	\ "_linklist", "_stream_duplex", "_stream_passthrough", "_stream_readable",
	\ "_stream_transform", "_stream_writable", "_tls_legacy", "_tls_wrap",
	\ "assert", "buffer", "child_process", "cluster", "console", "constants",
	\ "crypto", "dgram", "dns", "domain", "events", "freelist", "fs", "http",
	\ "https", "module", "net", "node", "os", "path", "punycode", "querystring",
	\ "readline", "repl", "smalloc", "stream", "string_decoder", "sys",
	\ "timers", "tls", "tty", "url", "util", "vm", "zlib"]

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
	command! -bar -bang -nargs=1 -buffer -complete=customlist,s:complete Require
		\ call s:require(<q-args>, 0)
	command! -bar -bang -nargs=1 -buffer -complete=customlist,s:complete Unrequire
		\ call s:require(<q-args>, 1)

	if exists(":R") != 2
		command! -bar -bang -nargs=1 -buffer -complete=customlist,s:complete R
			\ call s:require(<q-args>, 0)
	endif
	if exists(":UR") != 2
		command! -bar -bang -nargs=1 -buffer -complete=customlist,s:complete UR
			\ call s:require(<q-args>, 1)
	endif

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
	let &l:includeexpr = "node#lib#find(v:fname, bufname('%'))"

	if !hasmapto("<Plug>NodeGotoFile")
		" Split gotofiles don't take a count for the new window's width, but for
		" opening the nth file. Though Node.vim doesn't support counts atm.
		nmap <buffer> gf <Plug>NodeGotoFile
		nmap <buffer> <C-w>f <Plug>NodeSplitGotoFile
		nmap <buffer> <C-w><C-f> <Plug>NodeSplitGotoFile
		nmap <buffer> <C-w>gf <Plug>NodeTabGotoFile
	endif
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
		return s:error("E447: Can't find file \"" . a:name . "\" in path")
	endif

	exe command . " " . fnameescape(path)
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

function! s:require(expr, remove)
	" TODO: Allow custom aliases?
	" For example:  :Require _ could expand to :Require _=lodash

	" Remove extension if we were passed a completed filename
	let expr = substitute(a:expr, '\v\.(js|json|coffee)$', "", "I")
	" Remove trailing slashes if we were passed a completed folder name
	let expr = substitute(expr, '\v/+$', "", "")

	let pieces  = split(expr, "=") " :Require XRegExp=xregexp
	let varname = pieces[0]        " XRegExp
	let module  = pieces[-1]       " xregexp
	let sortkey = module

	if module =~# '\v^\.'
		" For ./lib/whatever, sort on last piece of name
		let sortkey = split(module, '/')[-1]
		if varname ==# module
			" No varname given, so default to last piece of name
			let varname = sortkey
		endif
		let member = ""
	else
		" Treat mongodb.MongoClient as MongoClient=mongodb.MongoClient
		if varname ==# module && module =~# '\v\.'
			let varname = split(module, '\.')[-1]
		endif
		let pieces = split(module, '\.', 1)
		let module = pieces[0]              " mongodb
		let member = join(pieces[1:], '\.') " MongoClient[.whatever]
	endif

	" If appropriate, search for this module in the package.json file and the
	" node_modules folder, so we can warn the user about any problems.

	let package = b:node_root . "/package.json"

	if a:remove " Removing a module; no need to check package.json or node_modules

		let showDepWarning = 0
		let depWarningStr  = ""

	elseif module =~# '\v^\.' " Local module; no need to check package.json or node_modules

		let showDepWarning = 0
		let depWarningStr  = ""

	elseif index(g:node#coreModules, module) > -1 " Core module; same

		let showDepWarning = 0
		let depWarningStr  = "core module"

	else

		" Check package.json for this module
		if filereadable(package)
			let deps = node#lib#deps(package)
			if index(deps, module) > -1
				let inPackage    = 1
				let inPackageStr = "in package.json"
			else
				let inPackage    = 0
				let inPackageStr = "not in package.json"
			endif
		else
			let inPackage    = 0
			let inPackageStr = "package.json not found"
		endif

		" Check node_modules folder for this module
		if isdirectory(b:node_root . "/node_modules/" . module)
			let inFolder    = 1
			let inFolderStr = "in node_modules"
		elseif isdirectory(b:node_root . "/node_modules")
			let inFolder    = 0
			let inFolderStr = "not in node_modules"
		else
			let inFolder    = 0
			let inFolderStr = "node_modules folder not found"
		endif

		let showDepWarning = !inPackage || !inFolder
		let depWarningStr  = inFolderStr . ", " . inPackageStr

	endif

	" Find and store existing require() statements, and compute the position
	" for the new require() statement

	let inFile    = 0
	let inFileStr = "added to current file; "

	" Set maximum varname width (for alignment)
	if a:remove
		let wmax = 0
	else
		let wmax = len(varname)
	endif

	let l    = 1  " line index
	let i    = 0  " require index
	let lbeg = 0  " beginning of require() block
	let lend = 0  " end of require() block
	let lmax = min([line('$'), 100]) " Assume that the require() block is in the first 100 lines
	let rnew = -1 " position of the new require() statement
	let reqs = [] " save the relevant values for all require() statements

	while l <= lmax
		let line = getline(l)

		" Match current line
		" Subpatterns:
		" 1. dummy
		" 2. varname
		" 3. module
		" 4. member
		let m = matchlist(line, '\v'
			\ . '^(\s+,?|\s*var)\s*'
			\ . '([a-zA-Z0-9_]+)'
			\ . '\s*\=\s*require\s*\([''"]'
			\ . '([a-zA-Z0-9_./-]+)'
			\ . '[''"]\s*\)'
			\ . '(\.[a-zA-Z0-9_]+)?')
		if len(m)

			if !lbeg
				let lbeg = l
			endif

			if !lend

				let req = {
					\ "varname" : m[2],
					\ "module"  : m[3],
					\ "member"  : m[4]
				\ }

				if req.module ==# module
					let inFile    = 1
					let inFileStr = "already in current file, "
				endif

				let sorttest = req.module
				if sorttest =~# '\v^\.'
					let sorttest = split(sorttest, '/')[-1]
				endif

				if !a:remove && rnew == -1 && sorttest >? sortkey
					let rnew = i
				endif

				if !a:remove || req.module !=# module
					let wmax = max([len(req.varname), wmax])
					call add(reqs, req)
					let i += 1
				endif

			endif

		else

			if lbeg && !lend
				let lend = l - 1
			endif

		endif

		let l += 1
	endwhile

	if !lbeg
		let lbeg = 1
		let lend = 0
	elseif !lend " TODO: does this ever happen?
		let lend = lmax
		if rnew == -1
			let rnew = 0
		endif
	endif
	if rnew == -1
		let rnew = i
	endif

	if (!a:remove && !inFile) || (a:remove && inFile) " Need to insert or remove module

		if !a:remove
			call insert(reqs, {
				\ "varname" : varname,
				\ "module"  : module,
				\ "member"  : member
			\ }, rnew)
		endif

		let i = 0
		" Turn the stored objects back into code text
		" TODO: Support configurable styles?  For example:  no semicolons,
		" commas before statements rather than after, no alignment, etc.
		while i < len(reqs)
			if i == 0
				let line = "var "
			else
				let line = "    "
			endif
			let line .= reqs[i].varname
			let line .= repeat(" ", wmax - len(reqs[i].varname))
			let line .= " = require('"
			let line .= reqs[i].module
			let line .= "')"
			if len(reqs[i].member)
				let line .= "." . reqs[i].member
			endif
			if i == len(reqs) - 1
				let line .= ";"
			else
				let line .= ","
			endif
			let reqs[i] = line
			let i += 1
		endwhile

		" Add an empty line if this is a new require() block and there will be
		" something after it
		if lbeg == 1 && lend == 0 && len(getline(1))
			call add(reqs, '')
		endif

		" Save window position
		let winview = winsaveview()
		" Delete old require() block
		if lend >= lbeg
			execute 'silent! ' . lbeg . ',' . lend . 'delete _'
		endif
		" Insert new require() block
		call append(lbeg - 1, reqs)
		" Adjust saved window position for changed number of lines
		let offset = len(reqs) - (lend - lbeg + 1)
		let winview.lnum += offset
		if winview.topline > 1
			let winview.topline = max([1, winview.topline + offset])
		endif
		" Restore window position
		call winrestview(winview)

	endif

	if !a:remove && (inFile || showDepWarning)
		call s:warning("Module '" . module . "': " . inFileStr . depWarningStr)
	elseif a:remove && !inFile
		call s:warning("Module '" . module . "': not in current file")
	endif
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

function! s:warning(msg)
	echohl WarningMsg
	echomsg a:msg
	echohl NONE
	let v:warningmsg = a:msg
endfunction
