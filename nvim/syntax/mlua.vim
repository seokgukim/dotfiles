" Vim syntax file for mLua
" Language: mLua (Lua-based language)
" Maintainer: auto-generated
" Latest Revision: 2024

if exists("b:current_syntax")
  finish
endif

" Use Lua syntax as base since mLua is Lua-based
runtime! syntax/lua.vim

" mLua specific keywords
syn keyword mluaKeyword component event handler script property method state
syn keyword mluaKeyword struct logic btnode item override attribute
syn keyword mluaKeyword import export module
syn keyword mluaBuiltin self this super

" Annotations (starting with @)
syn match mluaAnnotation "@\w\+"

" Highlight groups
hi def link mluaKeyword Keyword
hi def link mluaBuiltin Special
hi def link mluaAnnotation PreProc

let b:current_syntax = "mlua"
