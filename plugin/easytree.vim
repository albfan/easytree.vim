" easytree.vim - simple tree file manager for vim
" Maintainer: Dmitry "troydm" Geurkov <d.geurkov@gmail.com>
" Version: 0.2.1
" Description: easytree.vim is a simple tree file manager
" Last Change: 10 January, 2013
" License: Vim License (see :help license)
" Website: https://github.com/troydm/easytree.vim
"
" See easytree.vim for help.  This can be accessed by doing:
" :help easytree

let s:save_cpo = &cpo
set cpo&vim

" check python support and vim patchset version {{{
if !has("python")
    if exists("g:easytree_suppress_load_warning") && g:easytree_suppress_load_warning
        finish
    endif
    echo "easytree needs vim compiled with +python option"
    finish
endif

if !exists('*pyeval')
    if exists("g:easytree_suppress_load_warning") && g:easytree_suppress_load_warning
        finish
    endif
    echo "easytree needs vim 7.3 with atleast 569 patchset included"
    finish
endif
" }}}

" options {{{
if !exists('g:easytree_loaded')
    let g:easytree_loaded = 0
endif

if !exists("g:easytree_cascade_open_single_dir")
    let g:easytree_cascade_open_single_dir = 1
endif

if !exists("g:easytree_show_line_numbers")
    let g:easytree_show_line_numbers = 0
endif

if !exists("g:easytree_show_relative_line_numbers")
    let g:easytree_show_relative_line_numbers = 0
endif

if !exists("g:easytree_show_hidden_files")
    let g:easytree_show_hidden_files = 0
endif

if !exists("g:easytree_highlight_cursor_line")
    let g:easytree_highlight_cursor_line = 1
endif

if !exists("g:easytree_enable_vs_and_sp_mappings")
    let g:easytree_enable_vs_and_sp_mappings = 0
endif

if !exists("g:easytree_ignore_dirs")
    let g:easytree_ignore_dirs = []
endif

if !exists("g:easytree_ignore_files")
    let g:easytree_ignore_files = ['.easytree','*.swp']
endif

if !exists("g:easytree_ignore_find_result")
    let g:easytree_ignore_find_result = []
endif

if !exists("g:easytree_use_plus_and_minus")
    let g:easytree_use_plus_and_minus = 0
endif

if !exists("g:easytree_auto_load_settings")
    let g:easytree_auto_load_settings = 1
endif

if !exists("g:easytree_auto_save_settings")
    let g:easytree_auto_save_settings = 0
endif

if !exists("g:easytree_settings_file")
    let g:easytree_settings_file = '<dir>/.easytree'
endif

if !exists("g:easytree_hijack_netrw")
    let g:easytree_hijack_netrw = 1
endif

if !exists("g:easytree_width_auto_fit")
    let g:easytree_width_auto_fit = 0
endif

if !exists("g:easytree_win")
    let g:easytree_win = 'left'
endif

if !exists("g:easytree_toggle_win")
    let g:easytree_toggle_win = 'left'
endif

if !exists('s:EasyTreeIndicatorMap')
    let s:EasyTreeIndicatorMap = {
                \ 'Modified'  : '✹',
                \ 'Staged'    : '✚',
                \ 'Untracked' : '✭',
                \ 'Renamed'   : '➜',
                \ 'Unmerged'  : '═',
                \ 'Deleted'   : '✖',
                \ 'Dirty'     : '✗',
                \ 'Clean'     : '✔︎',
                \ 'Ignored'   : '☒',
                \ 'Unknown'   : '?'
                \ }
endif

" }}}

" commands {{{
command! -nargs=? -complete=dir EasyTree call easytree#OpenTree(g:easytree_win,<q-args>)
command! -nargs=? -complete=dir EasyTreeToggle call easytree#ToggleTree(g:easytree_toggle_win,<q-args>)
command! -nargs=? -complete=dir EasyTreeHere call easytree#OpenTree('edit here',<q-args>)
command! -nargs=? -complete=dir EasyTreeLeft call easytree#OpenTree('left',<q-args>)
command! -nargs=? -complete=dir EasyTreeRight call easytree#OpenTree('right',<q-args>)
command! -nargs=? -complete=dir EasyTreeTop call easytree#OpenTree('top',<q-args>)
command! -nargs=? -complete=dir EasyTreeBottom call easytree#OpenTree('bottom',<q-args>)
command! -nargs=? -complete=dir EasyTreeTopDouble call easytree#OpenTree('top double',<q-args>)
command! -nargs=? -complete=dir EasyTreeBottomDouble call easytree#OpenTree('bottom double',<q-args>)
" }}}

" netrw hijacking related functions {{{
function! s:OpenDirHere(dir)
    if isdirectory(a:dir)
        call easytree#OpenTree('edit here',a:dir) 
    endif
endfunction

function! s:DisableFileExplorer()
    au! FileExplorer
endfunction

function! s:TreeGetIndicator(statusKey)
    let l:indicator = get(s:EasyTreeIndicatorMap, a:statusKey, '')
    if l:indicator !=# ''
        return l:indicator
    endif
    return ''
endfunction

" status highlight {{{
function! s:AddHighlighting()
    let l:synmap = {
                \ 'EasyTreeGitStatusModified'    : s:TreeGetIndicator('Modified'),
                \ 'EasyTreeGitStatusStaged'      : s:TreeGetIndicator('Staged'),
                \ 'EasyTreeGitStatusUntracked'   : s:TreeGetIndicator('Untracked'),
                \ 'EasyTreeGitStatusRenamed'     : s:TreeGetIndicator('Renamed'),
                \ 'EasyTreeGitStatusUnmerged'    : s:TreeGetIndicator('Unmerged'),
                \ 'EasyTreeGitStatusDeleted'     : s:TreeGetIndicator('Deleted'),
                \ 'EasyTreeGitStatusDirDirty'    : s:TreeGetIndicator('Dirty'),
                \ 'EasyTreeGitStatusDirClean'    : s:TreeGetIndicator('Clean'),
                \ 'EasyTreeGitStatusIgnored'     : s:TreeGetIndicator('Ignored'),
                \ 'EasyTreeGitStatusUnknown'     : s:TreeGetIndicator('Unknown')
                \ }

    for l:name in keys(l:synmap)
        exec 'syn match ' . l:name . ' #' . escape(l:synmap[l:name], '~') . '# containedin=EasyTreeFlags'
    endfor

    highlight default EasyTreeGitStatusModified term=standout ctermfg=121 gui=bold guifg=Orange
    highlight default EasyTreeGitStatusStaged term=standout ctermfg=122 gui=bold guifg=Yellow
    highlight default EasyTreeGitStatusRenamed term=standout ctermfg=123 gui=bold guifg=Purple
    highlight default EasyTreeGitStatusUnmerged term=standout ctermfg=124 gui=bold guifg=Blue
    highlight default EasyTreeGitStatusUntracked term=standout ctermfg=125 gui=bold guifg=Brown
    highlight default EasyTreeGitStatusDirDirty term=standout ctermfg=126 gui=bold guifg=Orange
    highlight default EasyTreeGitStatusDirClean term=standout ctermfg=127 gui=bold guifg=White
    " TODO: use diff color
    highlight default EasyTreeGitStatusIgnored term=standout ctermfg=128 gui=bold guifg=Gray
endfunction
" }}}

augroup EasyTree
    autocmd VimEnter * if g:easytree_hijack_netrw | call <SID>DisableFileExplorer() | endif
    autocmd BufEnter * if g:easytree_hijack_netrw | call <SID>OpenDirHere(expand('<amatch>')) | endif
    autocmd FileType easytree call <SID>AddHighlighting()
augroup end
" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set sw=4 sts=4 et fdm=marker:
