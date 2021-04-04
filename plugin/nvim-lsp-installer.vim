if exists('g:loaded_nvim_lsp_installer') | finish | endif
let g:loaded_nvim_lsp_installer = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:LspInstallCompletion(...) abort
    return join(luaeval("require'nvim-lsp-installer'.get_available_servers()"), "\n")
endfunction

function! s:LspUninstallCompletion(...) abort
    return join(luaeval("require'nvim-lsp-installer'.get_installed_servers()"), "\n")
endfunction

function! s:LspInstall(server) abort
    call luaeval("require'nvim-lsp-installer'.install(_A)", a:server)
endfunction

function! s:LspInstallAll() abort
    for server in luaeval("require'nvim-lsp-installer'.get_uninstalled_servers()")
        call luaeval("require'nvim-lsp-installer'.install(_A)", server)
    endfor
endfunction

function! s:LspUninstall(server) abort
    call luaeval("require'nvim-lsp-installer'.uninstall(_A)", a:server)
endfunction

function! s:LspUninstallAll() abort
    for server in luaeval("require'nvim-lsp-installer'.get_installed_servers()")
        call s:LspUninstall(server)
    endfor
endfunction

function! s:LspPrintInstalled() abort
    echo luaeval("require'nvim-lsp-installer'.get_installed_servers()")
endfunction

command! -nargs=1 -complete=custom,s:LspInstallCompletion LspInstall exe s:LspInstall("<args>")
command! -nargs=1 -complete=custom,s:LspUninstallCompletion LspUninstall exe s:LspUninstall("<args>")

command! LspInstallAll call s:LspInstallAll()
command! LspUninstallAll call s:LspUninstallAll()
command! LspPrintInstalled call s:LspPrintInstalled()

let &cpo = s:save_cpo
unlet s:save_cpo
