if exists("g:loaded_node") || &cp || v:version < 700 | finish | endif
let g:loaded_node = 1

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

augroup Node
	au!
	au VimEnter * if empty(expand("<amatch>")) | call s:detect(getcwd()) | endif
	au BufRead,BufNewFile * call s:detect(expand("<amatch>:p"))
augroup end
