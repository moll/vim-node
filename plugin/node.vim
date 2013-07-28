if exists("g:loaded_node") || &cp | finish | endif
let g:loaded_node = 1

function! s:detect(path)
	if exists("b:node_root") | return | en
	let path = a:path

	while 1
		let is_node = 0
		let is_node = is_node || filereadable(path . "/package.json")
		let is_node = is_node || isdirectory(path . "/node_modules")
		if is_node | return s:init(path) | en

		let parent = fnamemodify(path, ":h")
		echom parent
		if parent == path | return | en 
		let path = parent
	endwhile
endfunction

function! s:init(root)
	let b:node_root = a:root

	if &filetype == "javascript" | setl suffixesadd+=.js | en
endfunction

augroup Node
	au!
	au BufRead,BufNewFile * call s:detect(expand("<amatch>:p"))
augroup END
