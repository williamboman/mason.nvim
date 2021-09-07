if exists('g:loaded_nvim_lsp_installer') | finish | endif
let g:loaded_nvim_lsp_installer = v:true
let g:lsp_installer_allow_federated_servers = get(g:, "lsp_installer_allow_federated_servers", v:true)

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

command! -nargs=+ -complete=custom,s:LspInstallCompletion LspInstall exe s:LspInstall("<args>")
command! -nargs=+ -complete=custom,s:LspUninstallCompletion LspUninstall exe s:LspUninstall("<args>")

command! LspUninstallAll call s:LspUninstallAll()
command! LspPrintInstalled call s:LspPrintInstalled()
command! LspInstallInfo call s:LspInstallInfo()

autocmd User LspAttachBuffers lua require"nvim-lsp-installer".lsp_attach_proxy()

let &cpo = s:save_cpo
unlet s:save_cpo
