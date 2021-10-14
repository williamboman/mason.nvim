if exists('g:loaded_nvim_lsp_installer') | finish | endif
let g:loaded_nvim_lsp_installer = v:true

let s:save_cpo = &cpo
set cpo&vim

function! s:MapServerName(servers) abort
    return map(a:servers, {_, val -> val.name})
endfunction

function! s:LspInstallCompletion(...) abort
    return join(sort(s:MapServerName(luaeval("require'nvim-lsp-installer.servers'.get_available_servers()"))), "\n")
endfunction

function! s:LspUninstallCompletion(...) abort
    return join(sort(s:MapServerName(luaeval("require'nvim-lsp-installer.servers'.get_installed_servers()"))), "\n")
endfunction

function! s:LspInstall(server_names) abort
    for server_name in split(a:server_names, " ")
        call luaeval("require'nvim-lsp-installer'.install(_A)", server_name)
    endfor
endfunction

function! s:LspUninstall(server_names) abort
    for server_name in split(a:server_names, " ")
        call luaeval("require'nvim-lsp-installer'.uninstall(_A)", server_name)
    endfor
endfunction

function! s:LspUninstallAll() abort
    lua require'nvim-lsp-installer'.uninstall_all()
endfunction

function! s:LspPrintInstalled() abort
    echo s:MapServerName(luaeval("require'nvim-lsp-installer.servers'.get_installed_servers()"))
endfunction

function! s:LspInstallInfo() abort
    lua require'nvim-lsp-installer'.display()
endfunction

function! s:LspInstallLog() abort
    exe 'tabnew ' .. luaeval("require'nvim-lsp-installer.log'.outfile")
endfunction

command! -nargs=+ -complete=custom,s:LspInstallCompletion LspInstall exe s:LspInstall("<args>")
command! -nargs=+ -complete=custom,s:LspUninstallCompletion LspUninstall exe s:LspUninstall("<args>")

command! LspUninstallAll call s:LspUninstallAll()
command! LspPrintInstalled call s:LspPrintInstalled()
command! LspInstallInfo call s:LspInstallInfo()
command! LspInstallLog call s:LspInstallLog()

autocmd User LspAttachBuffers lua require"nvim-lsp-installer".lsp_attach_proxy()

let &cpo = s:save_cpo
unlet s:save_cpo



"""
""" Backward compat for deprecated g:lsp_installer* options. Remove by 2021-12-01-ish.
"""
if exists("g:lsp_installer_allow_federated_servers")
    " legacy global variable option
    call luaeval("require('nvim-lsp-installer').settings { allow_federated_servers = _A }", g:lsp_installer_allow_federated_servers)
    lua vim.notify("[Deprecation notice] Providing settings via global variables (g:lsp_installer_allow_federated_servers) is deprecated. Please refer to https://github.com/williamboman/nvim-lsp-installer#configuration.", vim.log.levels.WARN)
endif

if exists("g:lsp_installer_log_level")
    " legacy global variable option
    call luaeval("require('nvim-lsp-installer').settings { log_level = _A }", g:lsp_installer_log_level)
    lua vim.notify("[Deprecation notice] Providing settings via global variables (g:lsp_installer_log_level) is deprecated. Please refer to https://github.com/williamboman/nvim-lsp-installer#configuration.", vim.log.levels.WARN)
endif
