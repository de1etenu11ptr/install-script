runtime! archlinux.vim

if !isdirectory($HOME."/.vim")
	call mkdir($HOME."/.vim", "", 0770)
endif
if !isdirectory($HOME."/.vim/undo-dir")
	call mkdir($HOME."/.vim/undo-dir", "", 0700)
endif
if !isdirectory($HOME."/.vim/backup-dir")
	call mkdir($HOME."/.vim/backup-dir", "", 0700)
endif

set undodir=~/.vim/undo-dir
set undofile
set noswapfile
set spellfile=~/.vim/spellfile.utf-8.add

set viminfo='20,<1000,f1

let g:mapleader = ";"
let g:case_change = []

 set noexpandtab
" set expandtab
 set tabstop=8
 set shiftwidth=8

" set noexpandtab
" set expandtab
" set shiftwidth=4
" set tabstop=4

set ruler

set showcmd

set number
set relativenumber

set nohlsearch
set incsearch

set scrolloff=8

" The minimum number of columns used to print the line number in front of each line
set numberwidth=8

set autoindent
set smartindent

let g:fuzzbox_respect_gitignore = 1

set belloff=all

" ===================================
" BEGIN: General Prep & Config
" ===================================

augroup U_General
	autocmd!
	autocmd BufWritePre * call mkdir(expand('<afile>:p:h'), 'p')
	autocmd BufReadPost * call RestoreCursor()
	autocmd FileType netrw nnoremap ? :help netrw-quickmap<CR>
augroup END

augroup U_SetFileType
	autocmd!
	autocmd BufRead,BufNewFile *.kitty-session set filetype=kitty
	autocmd BufRead,BufNewFile /etc/nginx/sites-*/* set filetype=conf
	autocmd BufRead,BufNewFile /etc/sudoers set filetype=sudoers
	autocmd BufRead,BufNewFile *.txt set filetype=txt
	autocmd FileType sh call BashAppendPrefix()
augroup END

function BashAppendPrefix()
	if !filereadable(expand('%'))
		0put ='#!/bin/bash'
		normal! G
	endif
endfunction

function! RestoreCursor()
	let l:line = line("'\"")
	if l:line >= 1 && l:line <= line("$")
		exec "normal! g'\""
	endif
endfunction

" ===================================
" END: General Prep & Config
" ===================================

" ===================================
" BEGIN: Spell Checking
" ===================================

let g:spellcheck_filetypes = ["vimwiki", "markdown"]

augroup U_SpellCheck
	autocmd!
	autocmd FileType vimwiki call SetupSpellChecking()
augroup END

function! SetupSpellChecking()
	if index(g:spellcheck_filetypes, &ft) == -1
		return
	endif
	setlocal spell
	setlocal spelllang=en_gb
	setlocal spellsuggest=best,5
	" highlight clear SpellBad
	nnoremap <leader>hs :highlight clear SpellBad<CR>
endfunction

" ===================================
" END: Spell Checking
" ===================================

" ===================================
" BEGIN: UI Customization
" ===================================

augroup U_StyleUtilities
	autocmd!
	autocmd FileType c,cpp,h,hpp,javascript,python call HighlightColumn(81)
augroup END

augroup U_FormatUtilities
	autocmd!
	autocmd BufWritePre *.c,*.cpp,*.java,*.javascript,*.python,*.vimrc call TrimTrailingWhiteSpace()
	autocmd BufWritePre *.c,*.cpp,*.java,*.javascript,*.python,*.vimrc call RemoveRedundantNewLines()
augroup END

function! HighlightColumn(no)
	" colour the 81st column of lines (the kernel coding style suggests keeping your lines to a max of 80 columns used, so this helps in keeping track of that)
	"execute "set colorcolumn=" . join(range(81, 335, 1), ',')
	execute 'set colorcolumn=' . a:no
	highlight ColorColumn ctermbg=None ctermfg=Cyan
endfunction

function! TrimTrailingWhiteSpace()
	let l:_save_pos=getpos(".")
	%s/\([^"'`]\)\{1\}\s\+$/\1/e
	call setpos(".", l:_save_pos)
	unlet l:_save_pos
endfunction

function! RemoveRedundantNewLines()
	let l:_save_pos=getpos(".")
	%s/\n\{2,\}$/\r/e
	call setpos(".", l:_save_pos)
	unlet l:_save_pos
endfunction

" ===================================
" END: UI Customization
" ===================================

" ===================================
" BEGIN: Performance Adjustments
" ===================================

let g:optimization_file_size = 100*1000*1000

augroup U_CustomizePerformance
	autocmd!
	autocmd BufWinEnter * nested call HandleLargeFiles()
augroup END

function! HandleLargeFiles()
	let l:_file = expand("%:p")
	let l:_file_size = max([getfsize(l:_file), 0])
	if l:_file_size >= g:optimization_file_size || l:_file_size == -2
		syntax clear
		setlocal wrap=off
		setlocal bufhidden=unload
		setlocal undolevels=-1
		setlocal foldmethod=manual
		setlocal viminfofile=NONE
	else
		if index(["python", "vim", "xml"], &filetype) >= 0
			setlocal foldmethod=indent
		else
			setlocal foldmethod=syntax
		endif
		set updatetime=1000
	endif
endfunction

" ===================================
" END: Performance Adjustments
" ===================================

" ===================================
" BEGIN: Backup Config
" ===================================

set backupdir=~/.vim/backup-dir
set backup
set writebackup
set backupcopy=yes

let g:backupdir = &backupdir
" 500MB
let g:min_backup_file_size = 500 * 1000 * 1000
let g:min_backup = 3
let g:max_backup = 10
let g:backupext_pat = '-[0-9]\{8\}[0-9:]\{6\}\~$'
" 100MB
" 10 days
let g:old_backups_delete = (10 * 24 * 60 * 60)

augroup U_BackupManage
	autocmd!
	autocmd BufWritePre * call PreFileBackup()
	autocmd VimLeave * call DeleteOldBackups()
	autocmd BufReadPost * nnoremap <leader>bd :call DeleteAllBackups(expand("%:p"))<CR>
augroup END

function! PreFileBackup()
	exec 'set backupdir=' .. g:backupdir .. fnameescape(expand("%:p:h"))
	if !isdirectory(&backupdir)
		call mkdir(&backupdir, "p")
	endif
	let &backupext = '-' .. strftime("%Y%m%d%H%M%S") .. '~'
endfunction

function! GetAllDirItems(dir)
	let l:results = []
	let l:items = glob(a:dir .. "/*", 1, 1) + glob(a:dir .. "/.*", 1, 1)
	call filter(l:items, {idx, val -> !(match(val, '/\.\{1,2\}$') >= 0 && isdirectory(val))})
	for item in l:items
		call add(l:results, l:item)
		if isdirectory(l:item)
			call extend(l:results, GetAllDirItems(l:item))
		endif
	endfor
	return l:results
endfunction

function! DeleteAllBackups(tfile)
	let l:backup_files = GetAllDirItems(g:backupdir)
	let l:target = g:backupdir .. a:tfile
	for file in l:backup_files
		let l:real_file = substitute(file, g:backupext_pat, "", "")
		if l:target == l:real_file
			call delete(file)
		endif
	endfor
endfunction

function! RemoveUnnecessaryFiles(dict)
	for key in keys(a:dict)
		call sort(a:dict[key], {a, b -> getftime(a) - getftime(b)})
		let l:files = a:dict[key]
		let l:n = len(l:files)

		let l:sizes = map(copy(l:files), {_, tmp -> max([getfsize(tmp), 0])})
		let l:avg = 0
		for size in l:sizes
			let l:avg += size
		endfor
		let l:avg = float2nr(l:avg / len(l:sizes))

		if l:avg >= g:min_backup_file_size
			let l:target = g:min_backup
		else
			let l:target = g:max_backup
		endif

		if l:n <= l:target
			continue
		endif

		let l:keep = []
		" Select those to preserve
		if l:target <= 1
			let l:keep = [l:files[-1]]
		else
			for i in range(0, l:target - 1)
				let l:idx = float2nr(round((l:n - 1) * i / (l:target - 1)))
				call add(l:keep, l:files[l:idx])
			endfor
		endif
		let l:keep = uniq(sort(l:keep))

		" Delete everything not preserved
		for file in l:files
			if index(l:keep, file) == -1
				call delete(file)
			endif
		endfor
	endfor
endfunction

function! DeleteOldBackups()
	" 10 days in seconds
	let l:now = localtime()

	let l:backup_files = GetAllDirItems(g:backupdir)
	call sort(l:backup_files, {a, b -> len(b) - len(a)})

	let l:dict = {}

	for file in l:backup_files
		if isdirectory(file)
			call delete(file, "d")
			continue
		endif

		let l:real_file = substitute(file, g:backupext_pat, "", "")
		if has_key(l:dict, l:real_file)
			call add(l:dict[l:real_file], file)
		else
			let l:dict[l:real_file] = [file]
		endif

		if (l:now - getftime(file) > g:old_backups_delete)
			call delete(file)
		endif
	endfor

	call RemoveUnnecessaryFiles(l:dict)
endfunction

" ===================================
" END: Backup Config
" ===================================

" ===================================
" BEGIN: Workstation General Configs
" ===================================

augroup U_WorkStationGeneral
	autocmd!
	autocmd FileType * nnoremap <leader>cc :call CompileProgramKittySession(0)<CR>
	autocmd FileType * nnoremap <leader>cw :call CompileProgramKittySession(1)<CR>
	autocmd FileType * call SetIndentSettings()
	autocmd FileType * call SetupFormatterShortcuts()
	autocmd BufEnter * call SetupFormatterShortcuts()
augroup END

function! SetIndentSettings()
	if index(['yaml', 'yml'], &ft) > -1
		setlocal expandtab
		setlocal tabstop=2
		setlocal shiftwidth=2
	elseif index(['python', 'vimwiki'], &ft) > -1
		setlocal expandtab
		setlocal tabstop=4
		setlocal shiftwidth=4
	else
		setlocal noexpandtab
		setlocal tabstop=8
		setlocal shiftwidth=8
	endif
endfunction

function! Format(type, is_normal)
	write!
	if a:type == 'c' && executable('python') && filereadable('/usr/share/clang/clang-format.py')
		if a:is_normal
			let l:formatter = ['clang-format', '-i', expand('%')]
		else
			let l:executer = ['python']
			let l:formatter = ['/usr/share/clang/clang-format.py']
		endif
	elseif a:type == 'python' && executable('black')
		let l:formatter = ['black', expand('%')]
	elseif a:type == 'html' && executable('prettier')
		let l:formatter = ['prettier', '--write', expand('%')]
	elseif a:type == 'javascript' && executable('prettier')
		let l:formatter = ['prettier', '--write', expand('%')]
	elseif a:type == 'shell' && executable('shfmt')
		let l:formatter = ['shfmt', '-w', '-i', '0', '-sr', expand('%')]
	elseif a:type == 'json' && executable('json_pp')
		let l:fname = expand('%')
		let l:tmp = tempname()
		let l:formatter = 'json_pp -f json -t json -json_opt pretty,canonical < '
			\ .. shellescape(l:fname)
			\ .. ' > ' .. shellescape(l:tmp)
			\ .. ' && cat ' .. shellescape(l:tmp) .. ' > ' .. shellescape(l:fname)
	else
		echo "No formatter set for \"" .. a:type .. "\"."
	endif

	if exists('l:formatter') == 0
		return
	elseif exists('l:executer') == 0
		let l:out = system(l:formatter)
		if v:shell_error == 0
			echohl MoreMsg | echo "Successfully formatted..." | echohl None
		else
			echohl Error | echo "Failed formatting..." | echohl None | echo l:out
		endif
	else
		let l:out = system(l:executer + l:formatter)
		if v:shell_error == 0
			echohl MoreMsg | echo "Successfully formatted..." | echohl None
		else
			echohl Error | echo "Failed formatting..." | echohl None | echo l:out
		endif
	endif
	call getchar()
	edit!
endfunction

function! SetupFormatterShortcuts()
	if index(['cpp', 'c', 'hpp', 'h'], &filetype) >= 0
		noremap <c-k> :call Format('c', 1)<cr>
		inoremap <c-k> <c-o>:call Format('c', 0)<cr>
	elseif index(['python'], &filetype) >= 0
		noremap <c-k> :call Format('python', 1)<cr>
		inoremap <c-k> <c-o>:call Format('python', 0)<cr>
	elseif index(['html', 'css'], &filetype) >= 0
		noremap <c-k> :call Format('html', 1)<cr>
		inoremap <c-k> <c-o>:call Format('html', 0)<cr>
	elseif index(['javascript'], &filetype) >= 0
		noremap <c-k> :call Format('javascript', 1)<cr>
		inoremap <c-k> <c-o>:call Format('javascript', 0)<cr>
	elseif index(['sh'], &filetype) >= 0
		noremap <c-k> :call Format('shell', 1)<cr>
		inoremap <c-k> <c-o>:call Format('shell', 0)<cr>
	elseif index(['json'], &filetype) >= 0
		noremap <c-k> :call Format('json', 1)<cr>
		inoremap <c-k> <c-o>:call Format('json', 0)<cr>
	endif
endfunction

function! GetNoSessionWindows()
	let l:session_launch_file = getenv('HOME') .. "/.config/kitty/session-launch-kitten.py"
	if !filereadable(l:session_launch_file)
		echohl ErrorMsg
		echo "\"" .. l:session_launch_file .. "\" not found..."
		echohl None
		return ""
	endif

	let l:session = readfile(l:session_launch_file)
	if len(l:session) == 0
		return ""
	endif
	let l:options = []
	let l:session = readfile(l:session_launch_file)
	for option in l:session
		if match(option, '^SUPPORTED_TYPES') >= 0
			let l:tmp = substitute(option, '^SUPPORTED_TYPES\s*=\s*', '', '')
			let l:tmp = substitute(l:tmp, ';\s*$', '', '')
			let l:tmp = json_decode(l:tmp)
			let l:options = keys(l:tmp)
			call map(l:options, {_, val -> substitute(val, '\(^"\|"$\)', "", "g")})
			break
		endif
	endfor
	if len(l:options) == 0
		return ""
	endif

	let l:menu = ["Pick a session type:"]
	for i in range(len(l:options))
		call add(l:menu, (i + 1) .. ". " .. l:options[i])
	endfor

	let l:choice = inputlist(l:menu)
	if l:choice <= 0 || l:choice > len(l:options)
		return l:options[0]
	endif

	return l:options[l:choice - 1]
endfunction

function! GetSessionType()
	let l:cwd = getcwd()
	let l:kitty_json = l:cwd .. "/" .. ".kitty-session.json"
	if !filereadable(l:kitty_json)
		echohl ErrorMsg
		echo "\"" .. l:kitty_json .. "\" not found..."
		echohl None
		return ""
	endif

	let l:session = json_decode(join(readfile(l:kitty_json), "\n"))
	let l:s_options = keys(l:session)
	if len(l:s_options) == 0
		return ""
	endif
	let l:s_options = sort(l:s_options)

	let l:menu = ["Pick a session type:"]
	for i in range(len(l:s_options))
		call add(l:menu, (i + 1) .. ". " .. l:s_options[i])
	endfor

	let l:choice = inputlist(l:menu)
	if l:choice <= 0 || l:choice > len(l:s_options)
		return l:s_options[0]
	endif

	return l:s_options[l:choice - 1]
endfunction

function! CompileProgramKittySession(workstation)
	if a:workstation
		let l:type = GetNoSessionWindows()
		if l:type == ""
			echohl ErrorMsg
			echo "Failed..."
			echohl None
			return
		endif
		let l:cmd =<< trim END
			if [[ -f "${HOME}/.config/kitty/session-launch-kitten.py" ]]; then
				kitty @ kitten session-launch-kitten.py -vim "$KITTY_WINDOW_ID" -type %s
			fi
		END
		let l:cmd_result = printf(join(l:cmd, "\n"), l:type)
	else
		let l:type = GetSessionType()
		if l:type == ""
			echohl ErrorMsg
			echo "Failed..."
			echohl None
			return
		endif
		echohl MoreMsg
		echo "\nSelected: " .. l:type
		echohl None
		let l:cmd =<< trim END
			if [[ -f ".kitty-session.json" ]]; then
				kitty @ kitten workstation-kitten.py -vim "$KITTY_WINDOW_ID" -build %s
			fi
		END
		let l:cmd_result = printf(join(l:cmd, "\n"), l:type)
	endif
	let l:cmd_result = systemlist(l:cmd_result)
	for line in l:cmd_result
		echo line
	endfor
endfunction

" ===================================
" END: Workstation General Configs
" ===================================

augroup U_WorkStationC
	autocmd!
	autocmd FileType c,cpp setlocal cindent
	autocmd FileType c,cpp setlocal cinoptions=l1
	autocmd FileType c,cpp nnoremap <leader>hs :call SortHeaders()<CR>
	autocmd FileType c,cpp nnoremap <leader>hh :call DeclarationsCopy()<CR>
	autocmd FileType c,cpp nnoremap <leader>hd :%s/^\([a-zA-Z_]\w*[^{;]*(\_.\{-})\)\_s*{/\1\r{/gc<CR>
	autocmd FileType c,cpp,h,hpp nnoremap <leader>hf :call SwitchCFile()<CR>
augroup END

vnoremap <leader>ca :call AddToCaseChangeList()<CR>
vnoremap <leader>cc :call RemoveCaseChangeList()<CR>
nnoremap <leader>sc :call SnakeCase()<CR>

vnoremap <leader>d "_d
vnoremap <leader>x "_x

nnoremap <leader>r :syntax sync fromstart<CR>
nnoremap <leader>rf :edit<CR>

nnoremap <silent> <leader>uu :Ex<CR>
nnoremap <silent> <leader>d $
nnoremap <silent> <leader>p ^

inoremap jk <esc>
vnoremap jk <esc>

inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>

" Vim Completion Remaps
inoremap <c-f> <c-x><c-f>
inoremap <c-d> <c-x><c-d>

nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
nnoremap <leader>v "+p`]o<esc>
nnoremap <leader>pv "+p`]<esc>
nnoremap <a-]> :n<CR>
nnoremap <a-[> :prev<CR>
nnoremap <leader>w <c-w>w
nnoremap <a-9> :tabp<CR>
nnoremap <a-0> :tabn<CR>

vnoremap <up> <nop>
vnoremap <down> <nop>
vnoremap <left> <nop>
vnoremap <right> <nop>

vnoremap p :<C-u>let temp = @"<CR>gvp<CR>:let @" = temp<CR>

function! IsLexSmaller(a, b)
	let l:length = len(a:a) > len(a:b) ? len(a:b) : len(a:a)
	for i in range(l:length)
		if a:a[i] < a:b[i]
			return -1
		elseif a:a[i] > a:b[i]
			return 1
		endif
	endfor
	return len(a:a) > len(a:b) ? 1 : -1
endfunction

function! SortHeaders()
	call cursor([1, 1])
	let l:end = search('#include [^\n\r]*\(\_s*#include [^\n\r]*\)*', "e")
	let l:headers = getline(1, l:end)
	let l:std = []
	let l:usr = []
	call filter(l:headers, {_, val -> len(val) > 8})
	call uniq(l:headers)
	for header in l:headers
		if match(header, '#include <') >= 0
			call add(l:std, header)
		else
			call add(l:usr, header)
		endif
	endfor
	call sort(l:std, "IsLexSmaller")
	call sort(l:usr, "IsLexSmaller")
	call appendbufline(bufname(), l:end, "")
	call setbufline(bufname(), 1, l:std + l:usr)
endfunction

function! GetVisualSelection()
	" [bufnum, lnum, cnum, off]
	let l:start = getpos("'<")
	let l:end = getpos("'>")

	if l:start[1] == l:end[1]
		let l:sel = getline(l:start[1])[l:start[2] - 1 : l:end[2] - 1]
	else
		let l:sel = getline(l:start[1], l:end[1])
		let l:sel[0] = l:sel[0][l:start[2] - 1 :]
		let l:sel[len(l:sel) - 1] = l:sel[len(l:sel) - 1][0 : l:end[2] - 1]
	endif

	return l:sel
endfunction

function! RemoveCaseChangeList()
	if len(g:case_change) > 0
		call remove(g:case_change, 0, -1)
	endif
	echohl MoreMsg
	echo "Cleared case_change list."
	echo "List: [" .. join(g:case_change, ", ") .. "]."
	echohl None
endfunction

function! AddToCaseChangeList()
	call add(g:case_change, GetVisualSelection())
	call uniq(sort(g:case_change))
	echohl MoreMsg
	echo "Added: \"" .. g:case_change[len(g:case_change) - 1] .. "\"."
	echo "List: [" .. join(g:case_change, ", ") .. "]."
	echohl None
endfunction

function! SnakeCase()
	for l:change in g:case_change
		let l:escaped = escape(l:change, '\.^$\/[]~')
		let l:replacement = substitute(l:escaped, '\([A-Z]\)', '_\l\1', 'g')
		let l:replacement = substitute(l:replacement, '^_\([a-z]\)', '\1', 'g')
		echohl MoreMsg
		echo "Changing \"" .. l:change .. "\" to \"" .. l:replacement .. "\"."
		echohl None
		execute '%s/' .. l:escaped .. '/' .. l:replacement .. '/g'
	endfor
endfunction

function! DeclarationsCopy()
	let cur = getpos(".")
	let funcs = []
	let pattern = '^[a-zA-Z_]\w*[^{;]*(\_.\{-})\_s*{'
	" let pattern = '^[a-zA-Z_]\w*[^{;]*(\_.\{-})\_s\{-1,}{'
	" Return to the beginning of the file
	normal! gg

	while search(pattern, 'W')
		let start_line = line(".")
		call setpos(".", [0, start_line, 1, 0])
		call search("{", "W")
		let end_line = searchpair("{", "", "}", "W")
		if end_line > 0
			let m = join(getline(start_line, end_line), "\n")
			let m = matchstr(m, pattern)
			let m = substitute(m, '\_s*{\_s*$', ";", "")
			echohl MoreMsg
			let in = input('Would you like to add "' . m . '" to the copied declarations?' . "\n", "y")
			echo "\n"
			echohl None
			if in == "y"
				call add(funcs, m)
			endif
			call setpos(".", [0, end_line, 1, 0])
		endif
	endwhile
	call setpos(".", cur)

	let header_file_contents = join(funcs, "\n") . "\n"
	let @p = header_file_contents
	" let funcs = map(funcs, '"func: " . v:val')
	for i in range(len(funcs))
		let funcs[i] = "func: " . funcs[i]
	endfor
	echo join(funcs, "\n")
endfunction

function! SwitchCFile()
	let l:current_file = expand("%:p")
	if l:current_file == ""
		echohl ErrorMsg
		echo "No File Open"
		echohl None
		return
	endif

	let l:current_ext = matchstr(l:current_file, '.\w*$')
	let l:current_ext = substitute(l:current_ext, '^\.', "", "")
	let l:current_base = substitute(l:current_file, '\.\w*$', "", "")

	if l:current_ext == 'c'
		let l:candidate = [l:current_base . ".h", l:current_base . ".hpp"]
	elseif l:current_ext == 'cpp'
		let l:candidate = [l:current_base . ".hpp", l:current_base . ".h"]
	elseif l:current_ext == 'h'
		let l:candidate = [l:current_base . ".c", l:current_base . ".cpp"]
	elseif l:current_ext == 'hpp'
		let l:candidate = [l:current_base . ".cpp", l:current_base . ".c"]
	else
		echohl ErrorMsg
		echo "Not a recognizable C/C++ file"	
		echohl None
		return
	endif

	for f in l:candidate
		if filereadable(f)
			exec 'edit ' . fnameescape(f)
			return
		endif
	endfor

	" if none exist
	exec 'edit ' . fnameescape(l:candidate[0])
	echohl MoreMsg
	echo "Created new file: \"" . l:candidate[0] . "\""
	echohl None
endfunction
