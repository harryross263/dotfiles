if exists("did_load_filetypes")
 finish
endif

fun! <SID>StripTrailingWhitespaces()
  let _s = @/
  let l:winview = winsaveview()
  silent! %s/\s\+$//e
  call winrestview(l:winview)
  let @/ = _s
endfun

augroup markdown
  au!
  au BufRead,BufNewFile *.mkd,*.mmd setfiletype markdown
  au BufRead,BufNewFile *.mkd,*.mmd set tw=80
augroup end

augroup log
  au!
  au BufRead,BufNewFile *.log setfiletype log
  au BufRead,BufNewFile *.log setlocal nowrap
augroup end

augroup omake
  au!
  au BufRead,BufNewFile OMakefile setfiletype omake
  au BufRead,BufNewFile OMakefile setlocal nowrap
augroup end

augroup dat
  au!
  au BufRead,BufNewFile *.DAT setfiletype dat
  au BufRead,BufNewFile *.dat setfiletype dat
  au BufRead,BufNewFile *.dat setlocal nowrap
  au BufRead,BufNewFile *.DAT setlocal nowrap
augroup end

augroup csv
  au!
  au BufRead,BufNewFile *.{csv,report} setfiletype csv
  au BufRead,BufNewFile *.{csv,report} setlocal nowrap
augroup end

augroup sexp
  au!
  au BufRead,BufNewFile *.{sexp,jobs} setfiletype scheme
  au BufRead,BufNewFile *.{sexp,jobs} setlocal nowrap
augroup end

augroup ocaml
  au!
  au BufWinEnter *.{ml,mli} let w:m1=matchadd('ErrorMsg', '\%>90v.\+', -1)
  au BufWritePre *.{ml,mli} :call <SID>StripTrailingWhitespaces()
augroup end

augroup ps
  au!
  autocmd BufReadPre *.{pdf,ps} set ro
  autocmd BufReadPost *.{pdf,ps} silent %!pdftotext -nopgbrk "%" - |fmt -csw78
augroup end

augroup doc
  au!
  autocmd BufReadPre *.doc set ro
  autocmd BufReadPost *.doc silent %!antiword "%"
augroup end

augroup binary
  au!
  au BufReadPre  *.{bin,exe,class,o} let &bin=1
  au BufReadPost *.{bin,exe,class,o} if &bin | %!xxd
  au BufReadPost *.{bin,exe,class,o} set ft=xxd | endif
  au BufWritePre *.{bin,exe,class,o} if &bin | %!xxd -r
  au BufWritePre *.{bin,exe,class,o} endif
  au BufWritePost *.{bin,exe,class,o} if &bin | %!xxd
  au BufWritePost *.{bin,exe,class,o} set nomod | endif
augroup end

augroup supertab
  au!
  autocmd Filetype * 
  \ if &omnifunc != '' | 
  \   call SuperTabChain(&omnifunc, "<c-p>") | 
  \   call SuperTabSetDefaultCompletionType("<c-x><c-u>") | 
  \ endif
augroup end

au BufNewFile,Bufread *.py:
  \ set tabstop=4
  \ set softtabstop=4
  \ set shiftwidth=4
  \ set textwidth=79
  \ set textwidth=79
  \ set expandtab
  \ set autoindent
  \ set fileformat=unix

highlight BadWhitespace ctermbg=red guibg=darkred
au BufNewFile,BufRead *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

au BufNewFile,Bufread *.js, *.html, *.css:
  \ set tabstop=2
  \ set softtabstop=2
  \ set shiftwidth=2
