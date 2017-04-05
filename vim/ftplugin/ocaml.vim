" Language:    OCaml
" Maintainer:  David Baelde        <firstname.name@ens-lyon.org>
"              Mike Leary          <leary@nwlink.com>
"              Markus Mottl        <markus.mottl@gmail.com>
"              Stefano Zacchiroli  <zack@bononia.it>
"              Vincent Aravantinos <firstname.name@imag.fr>
" URL:         http://www.ocaml.info/vim/ftplugin/ocaml.vim
" Last Change: 2010 Jul 10 - Bugfix, thanks to Pat Rondon
"              2008 Jul 17 - Bugfix related to fnameescape (VA)
"              2007 Sep 09 - Added .annot support for ocamlbuild, python not 
"                            needed anymore (VA)
"              2006 May 01 - Added .annot support for file.whateverext (SZ)
"	             2006 Apr 11 - Fixed an initialization bug; fixed ASS abbrev (MM)
"              2005 Oct 13 - removed GPL; better matchit support (MM, SZ)
"
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin=1

" some macro
if exists('*fnameescape')
  function! s:Fnameescape(s)
    return fnameescape(a:s)
  endfun
else
  function! s:Fnameescape(s)
    return escape(a:s," \t\n*?[{`$\\%#'\"|!<")
  endfun
endif

" Error handling -- helps moving where the compiler wants you to go
let s:cposet=&cpoptions
set cpo-=C
setlocal efm=
      \%EFile\ \"%f\"\\,\ line\ %l\\,\ characters\ %c-%*\\d:,
      \%EFile\ \"%f\"\\,\ line\ %l\\,\ character\ %c:%m,
      \%+EReference\ to\ unbound\ regexp\ name\ %m,
      \%Eocamlyacc:\ e\ -\ line\ %l\ of\ \"%f\"\\,\ %m,
      \%Wocamlyacc:\ w\ -\ %m,
      \%-Zmake%.%#,
      \%C%m,
      \%D%*\\a[%*\\d]:\ Entering\ directory\ `%f',
      \%X%*\\a[%*\\d]:\ Leaving\ directory\ `%f',
      \%D%*\\a:\ Entering\ directory\ `%f',
      \%X%*\\a:\ Leaving\ directory\ `%f',
      \%DMaking\ %*\\a\ in\ %f

" Add mappings, unless the user didn't want this.
if !exists("no_plugin_maps") && !exists("no_ocaml_maps")
  " (un)commenting
  if !hasmapto('<Plug>Comment')
    nmap <buffer> <LocalLeader>c <Plug>LUncomOn
    vmap <buffer> <LocalLeader>c <Plug>BUncomOn
    nmap <buffer> <LocalLeader>C <Plug>LUncomOff
    vmap <buffer> <LocalLeader>C <Plug>BUncomOff
  endif

  nnoremap <buffer> <Plug>LUncomOn mz0i(* <ESC>$A *)<ESC>`z
  nnoremap <buffer> <Plug>LUncomOff :s/^(\* \(.*\) \*)/\1/<CR>:noh<CR>
  vnoremap <buffer> <Plug>BUncomOn <ESC>:'<,'><CR>`<O<ESC>0i(*<ESC>`>o<ESC>0i*)<ESC>`<
  vnoremap <buffer> <Plug>BUncomOff <ESC>:'<,'><CR>`<dd`>dd`<

  if !hasmapto('<Plug>Abbrev')
    iabbrev <buffer> ASS (assert (0=1) (* XXX *))
  endif
endif

" Let % jump between structure elements (due to Issac Trotts)
let b:mw = ''
let b:mw = b:mw . ',\<let\>:\<and\>:\(\<in\>\|;;\)'
let b:mw = b:mw . ',\<if\>:\<then\>:\<else\>'
let b:mw = b:mw . ',\<\(for\|while\)\>:\<do\>:\<done\>,'
let b:mw = b:mw . ',\<\(object\|sig\|struct\|begin\)\>:\<end\>'
let b:mw = b:mw . ',\<\(match\|try\)\>:\<with\>'
let b:match_words = b:mw

let b:match_ignorecase=0

" Folding support

" Get the modeline because folding depends on indentation
let s:s = line2byte(line('.'))+col('.')-1
if search('^\s*(\*:o\?caml:')
  let s:modeline = getline(".")
else
  let s:modeline = ""
endif
if s:s > 0
  exe 'goto' s:s
endif

" Get the indentation params
let s:m = matchstr(s:modeline,'default\s*=\s*\d\+')
if s:m != ""
  let s:idef = matchstr(s:m,'\d\+')
elseif exists("g:omlet_indent")
  let s:idef = g:omlet_indent
else
  let s:idef = 2
endif
let s:m = matchstr(s:modeline,'struct\s*=\s*\d\+')
if s:m != ""
  let s:i = matchstr(s:m,'\d\+')
elseif exists("g:omlet_indent_struct")
  let s:i = g:omlet_indent_struct
else
  let s:i = s:idef
endif

" Set the folding method
if exists("g:ocaml_folding")
  setlocal foldmethod=expr
  setlocal foldexpr=OMLetFoldLevel(v:lnum)
endif

" - Only definitions below, executed once -------------------------------------

if exists("*OMLetFoldLevel")
  finish
endif

function s:topindent(lnum)
  let l = a:lnum
  while l > 0
    if getline(l) =~ '\s*\%(\<struct\>\|\<sig\>\|\<object\>\)'
      return indent(l)
    endif
    let l = l-1
  endwhile
  return -s:i
endfunction

function OMLetFoldLevel(l)

  " This is for not merging blank lines around folds to them
  if getline(a:l) !~ '\S'
    return -1
  endif

  " We start folds for modules, classes, and every toplevel definition
  if getline(a:l) =~ '^\s*\%(\<val\>\|\<module\>\|\<class\>\|\<type\>\|\<method\>\|\<initializer\>\|\<inherit\>\|\<exception\>\|\<external\>\)'
    exe 'return ">' (indent(a:l)/s:i)+1 '"'
  endif

  " Toplevel let are detected thanks to the indentation
  if getline(a:l) =~ '^\s*let\>' && indent(a:l) == s:i+s:topindent(a:l)
    exe 'return ">' (indent(a:l)/s:i)+1 '"'
  endif

  " We close fold on end which are associated to struct, sig or object.
  " We use syntax information to do that.
  if getline(a:l) =~ '^\s*end\>' && synIDattr(synID(a:l, indent(a:l)+1, 0), "name") != "ocamlKeyword"
    return (indent(a:l)/s:i)+1
  endif

  " Folds end on ;;
  if getline(a:l) =~ '^\s*;;'
    exe 'return "<' (indent(a:l)/s:i)+1 '"'
  endif

  " Comments around folds aren't merged to them.
  if synIDattr(synID(a:l, indent(a:l)+1, 0), "name") == "ocamlComment"
    return -1
  endif

  return '='
endfunction

let &cpoptions=s:cposet
unlet s:cposet

" vim:sw=2 fdm=indent
