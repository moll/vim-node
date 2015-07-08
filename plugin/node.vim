if exists("g:loaded_node") || &cp || v:version < 700 | finish | endif
let g:loaded_node = 1

let s:filetypes = ["javascript", "json", "jsx"]
if exists("g:node_filetypes") | let s:filetypes = g:node_filetypes | endif

function! s:detect(dir)
	if exists("b:node_root") | return | endif
	let dir = a:dir

	while 1
		let is_node = 0
		let is_node = is_node || filereadable(dir . "/package.json")
		let is_node = is_node || isdirectory(dir . "/node_modules")
		if is_node | return node#initialize(dir) | endif

		let parent = fnamemodify(dir, ":h")
		if parent == dir | return | endif
		let dir = parent
	endwhile
endfunction

function! s:permutate(ft)
	" Don't know right now how to detect javascript.jsx and other permutations
	" without precomputing them in advance. Please let me know if you do.
	return [a:ft, a:ft . ".*", "*." . a:ft, "*." . a:ft . ".*"]
endfunction

function! s:flatten(list)
	let values = []
	for value in a:list
		if type(value) == type([]) | call extend(values, value)
		else | add(values, value)
		endif
	endfor
	return values
endfunction

augroup Node
	au!
	au VimEnter * if empty(expand("<amatch>")) | call s:detect(getcwd()) | endif
	au BufRead,BufNewFile * call s:detect(expand("<amatch>:p"))

	let s:filetype_patterns = s:flatten(map(s:filetypes, "<SID>permutate(v:val)"))
	let s:filetype_patterns_joined = join(s:filetype_patterns, ",")
	execute "au FileType " s:filetype_patterns_joined " call node#javascript()"
augroup end
