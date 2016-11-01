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
		if is_node | call node#javascript() | return node#initialize(dir) | endif

		let parent = fnamemodify(dir, ":h")
		if parent == dir | return | endif
		let dir = parent
	endwhile
endfunction

augroup Node
	au!
	let s:filetype_patterns_joined = join(s:filetypes, ",")
	execute "au FileType " s:filetype_patterns_joined ' call <SID>detect(expand("\<afile>:p"))'
augroup end
