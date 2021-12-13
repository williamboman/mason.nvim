if exists('g:loaded_nvim_lsp_installer') | finish | endif
let g:loaded_nvim_lsp_installer = v:true

let s:save_cpo = &cpo
set cpo&vim

let s:no_confirm_flag = "--no-confirm"

function! s:LspInstallCompletion(...) abort
    return join(sort(luaeval("require'nvim-lsp-installer'.get_install_completion()")), "\n")
endfunction

function! s:LspUninstallCompletion(...) abort
    return join(sort(luaeval("require'nvim-lsp-installer.servers'.get_installed_server_names()")), "\n")
endfunction

function! s:LspUninstallAllCompletion(...) abort
    return s:no_confirm_flag
endfunction

function! s:ParseArgs(args)
    if len(a:args) == 0
        return { 'sync': v:false, 'servers': [] }
    endif
    let sync = a:args[0] == "--sync"
    let servers = sync ? a:args[1:] : a:args
    return { 'sync': sync, 'servers': servers }
endfunction

function! s:LspInstall(args) abort
    let parsed_args = s:ParseArgs(a:args)
    if parsed_args.sync
        call luaeval("require'nvim-lsp-installer'.install_sync(_A)", parsed_args.servers)
    else
        if len(parsed_args.servers) == 0
            call luaeval("require'nvim-lsp-installer'.install_by_filetype(_A)", &filetype)
        else
            for server_name in l:parsed_args.servers
                call luaeval("require'nvim-lsp-installer'.install(_A)", server_name)
            endfor
        endif
    endif
endfunction

function! s:LspUninstall(args) abort
    let parsed_args = s:ParseArgs(a:args)
    if parsed_args.sync
        call luaeval("require'nvim-lsp-installer'.uninstall_sync(_A)", parsed_args.servers)
    else
        for server_name in l:parsed_args.servers
            call luaeval("require'nvim-lsp-installer'.uninstall(_A)", server_name)
        endfor
    endif
endfunction

function! s:LspUninstallAll(args) abort
    let no_confirm = get(a:args, 0, "") == s:no_confirm_flag
    call luaeval("require'nvim-lsp-installer'.uninstall_all(_A)", no_confirm ? v:true : v:false)
endfunction

function! s:LspPrintInstalled() abort
    echo luaeval("require'nvim-lsp-installer.servers'.get_installed_server_names()")
endfunction

function! s:LspInstallInfo() abort
    lua require'nvim-lsp-installer'.info_window.open()
endfunction

function! s:LspInstallLog() abort
    exe 'tabnew ' .. luaeval("require'nvim-lsp-installer.log'.outfile")
endfunction

command! -bar -nargs=* -complete=custom,s:LspInstallCompletion      LspInstall call s:LspInstall([<f-args>])
command! -bar -nargs=+ -complete=custom,s:LspUninstallCompletion    LspUninstall call s:LspUninstall([<f-args>])
command! -bar -nargs=? -complete=custom,s:LspUninstallAllCompletion LspUninstallAll call s:LspUninstallAll([<f-args>])

command! LspPrintInstalled call s:LspPrintInstalled()
command! LspInstallInfo call s:LspInstallInfo()
command! LspInstallLog call s:LspInstallLog()

let &cpo = s:save_cpo
unlet s:save_cpo
