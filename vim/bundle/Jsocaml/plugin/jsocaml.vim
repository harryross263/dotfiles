if exists("did_jsocaml_plugin")
  finish
endif

let b:did_jsocaml_plugin=1

let s:detect_jsocaml_changes=0

function s:Set_detect_changes() 
  let s:detect_jsocaml_changes=1
endfunction

let s:target_files = {}
let s:override_target_file=''

function s:Vim_target_file(for_file)
  if s:override_target_file != ''
    return s:override_target_file
  endif

  if !has_key(s:target_files, a:for_file)
    let s:target_files[a:for_file] = system('${HOME}/.vim/bundle/Jsocaml/bin/vim-omake --print-vim-target-file ' . a:for_file)
  endif

  return s:target_files[a:for_file]
endfunction

if !exists('g:use_old_jomake')
  let g:use_old_jomake=0
endif

if !exists('g:jomake_use_vim_status_exe')
  let g:jomake_use_vim_status_exe=0
endif

let s:errorformat = ''
      \. '%DUsing jenga root dir %f,'
      \. '%-G %#- exit %s,' 
      \. '%-Z*** jenga: %.%#,'
      \. '%-Zmake%.%#,' 
      \. '%E%.%#File "%f"\, line %l\, characters %c-%n (end at line %*\d\, character %*\d):,' 
      \. '%E%.%#File "%f"\, line %l\, characters %c-%n:,' 
      \. '%E%.%#File "%f"\, line %l\, characters %c--%*\d:,' 
      \. '%EFile "%f"\, line %l\, character %c:%m,' 
      \. '%E%.%#File "%f"\, line %l:,' 
      \. '%+EReference to unbound regexp name %m,' 
      \. '%Eocamlyacc: e - line %l of "%f"\, %m,' 
      \. '%Wocamlyacc: w - %m,' 
      \. '%D%*\a[%*\d]: Entering directory `%f'',' 
      \. '%X%*\a[%*\d]: Leaving directory `%f'',' 
      \. '%D%*\a: Entering directory `%f'',' 
      \. '%X%*\a: Leaving directory `%f'',' 
      \. '%D%.%#- scan %f %.%#,' 
      \. '%D%.%#- build %f %.%#,' 
      \. '%DMaking %*\a in %f,' 
      \. '%-C\s%#%m'

if g:use_old_jomake
  function s:Refresh_jomake(jump_to_first_error)

    setlocal efm=
          \%E%.%#File\ \"%f\"\\,\ line\ %l\\,\ characters\ %c-%*\\d:,
          \%EFile\ \"%f\"\\,\ line\ %l\\,\ character\ %c:%m,
          \%E%.%#File\ \"%f\"\\,\ line\ %l:,
          \%+EReference\ to\ unbound\ regexp\ name\ %m,
          \%Eocamlyacc:\ e\ -\ line\ %l\ of\ \"%f\"\\,\ %m,
          \%Wocamlyacc:\ w\ -\ %m,
          \%-Zmake%.%#,
          \%D%*\\a[%*\\d]:\ Entering\ directory\ `%f',
          \%X%*\\a[%*\\d]:\ Leaving\ directory\ `%f',
          \%D%*\\a:\ Entering\ directory\ `%f',
          \%X%*\\a:\ Leaving\ directory\ `%f',
          \%D%.%#-\ scan\ %f\ %.%#,
          \%D%.%#-\ build\ %f\ %.%#,
          \%DMaking\ %*\\a\ in\ %f,
          \%E%f:%l:%c:

    let &g:errorformat=&l:errorformat

    if a:jump_to_first_error 
      let s:detect_jsocaml_changes=0
      let file_contents = system('cat ' . s:Vim_target_file(expand("%:p:h")))
      cexpr system('col -b', file_contents)
    else
      if s:detect_jsocaml_changes
        let file_contents = system('cat ' . s:Vim_target_file(expand("%:p:h")))
        cgetexpr system('col -b', file_contents)
        call feedkeys("f\e", "n")
        redraw!
      endif
    endif
  endfunction

  command! Jomake call <SID>Refresh_jomake (1)
  command! Jomakes call <SID>Refresh_jomake (0)
  command! Jomakedetect call <SID>Set_detect_changes ()
elseif g:jomake_use_vim_status_exe
  let s:already_setup = 0
  let s:jengaerrorfile=tempname() . '.err'
  let s:jengaerrorcontents = ''
  let s:signs={}
  let s:signnumber=109
  let s:matchgroup='JSOerror'

  if !exists("g:max_jomake_preview_size")
    let g:max_jomake_preview_size=30
  endif

  function! s:SetupJomake() abort
    if !s:already_setup
      :sign define jomake text=>>
      :exec ':highlight ' . s:matchgroup . ' cterm=underline term=underline gui=undercurl'
      augroup Jomake
        au BufWinEnter *.ml call s:Display_jomake_error(0)
        au BufWinEnter *.mli call s:Display_jomake_error(0)
        au BufEnter *.ml call s:Display_jomake_error(0)
        au BufEnter *.mli call s:Display_jomake_error(0)
      augroup END
      let s:already_setup = 1
    endif
  endfunction

  function! s:Clear_matches() abort
    let matches=getmatches()

    for m in getmatches()
      if get(m, 'group', '') == s:matchgroup
        call matchdelete(m['id'])
      endif
    endfor

    :silent! au! JSO_Remove_matches TextChanged <buffer>
  endfunction

  function! s:Clear_signs(clear_these_signs) abort
    for i in a:clear_these_signs
      :exe ':silent! sign unplace  ' . l:i
      unlet s:signs[l:i]
    endfor
  endfunction

  function! s:Place_sign(bufnr, line) abort
    exec ':sign place ' . s:signnumber . ' line=' . a:line . ' name=jomake buffer=' . a:bufnr
    let s:signs[s:signnumber]=1
    let s:signnumber+=1
  endfunction

  function! s:Clear_all_indicators() abort
    :call s:Clear_signs(keys(s:signs))
    :call s:Clear_matches()
  endfunction

  function! s:Time_diff_to_str(seconds) abort
    if a:seconds > 90 
      return (a:seconds / 60) . 'm'
    else
      return a:seconds . 's'
    endif
  endfunction

  function! s:modify_for_values_do_not_match(msg) abort
    let l:step = 0
    let l:beg=[]
    let l:left=[]
    let l:right=[]
    let l:end=[]

    for i in a:msg
      if l:step == 0
        let l:beg+=[i]
        if i =~ '.*Values do not match.*'
          let l:step = 1
        endif
      elseif l:step == 1
        if i =~ '.*is not included in.*'
          let l:step = 2
          let l:sepstr=i
        else
          let l:left+=[i]
        endif
      elseif l:step == 2
        if i =~ 'File "'
          let l:step += 1
          let l:end += [i]
        else
          let l:right+=[i]
        endif
      elseif l:step == 3
        let l:end += [i]
      endif
    endfor

    if l:step < 2 
      return a:msg
    endif

    let l:sep = [nr2char(27) . '[33m' . l:sepstr . nr2char(27) . '[0;']
    let l:leftfile='/tmp/left'.$USER
    let l:rightfile='/tmp/right'.$USER
    :call writefile(l:left, l:leftfile)
    :call writefile(l:right, l:rightfile)
    let l:diff = systemlist('patdiff -context 10000 ' . l:leftfile . ' ' . l:rightfile . ' | tail -n +4 | sed -e "s/\t/    /g"')
    let l:hrbeg = ['=============================== Diff' ]
    let l:hrend = ['=============================== End diff']
    return l:beg + l:hrbeg + l:diff + l:hrend + l:left + l:sep + l:right + l:end
  endfunction

  function! s:contains_escape(l) abort
    for i in a:l
      if stridx(i, nr2char(27)) >= 0
        return 1
      endif
    endfor

    return 0
  endfunction

  function! s:Display_jomake_error(no_errors_msg) abort
    let l:old_signs = keys(s:signs)

    :call s:Clear_matches()

    let qf=getqflist()

    let errtext=[] 
    let founderr=0
    let l:added_match = 0

    for e in l:qf
      if get(e, 'valid', 0) && get(e, 'lnum', 0)
        let founderr=1
        :call s:Place_sign(e['bufnr'], e['lnum'])

        if get(e, 'bufnr', -1) == bufnr('%')
          if get(e, 'col', 0) 
            let chars = get(e,'nr', e['col'])  - e['col'] 
            let e['nr'] = 0
            let e['col'] += 1

            ":echo e
            let l:pattern = '\%' . e['lnum'] . 'l\%' . e['col'] . 'c\_.\{' . l:chars . '}'
            ":echo e
            let l:added_match = 1
            :call matchadd(s:matchgroup, l:pattern)
          else
            let chars = 0
          endif

          if line('.') == e['lnum'] || (line('.') == line('$') && e['lnum'] >= line('$'))
            if !empty(e['text'])
              let l:header = '----'

              if empty(errtext)
                let l:header = '----line ' . e['lnum'] . ' of ' . expand('%:t') . ' '
              else 
                let errtext+=['']
              endif

              if get(e, 'col', 0)
                let l:header.='cols ' . e['col']

                if l:chars > 0
                  let l:header.= '-' . (e['col'] + l:chars)
                endif
              endif

              let errtext+= [l:header]

              let errtext+=split(e['text'], '\n')
            endif
          endif
        endif
      endif
    endfor

    :call s:Clear_signs(l:old_signs)

    if l:founderr == 0
      let l:status = system('jenga monitor -snapshot')
      let g:status=l:status
      if stridx(l:status, '!') >= 0
        let l:founderr = 1
        let l:msg = 'Found error but cannot parse it.  Please send error to as-vim@.'
        let errtext+=[l:msg, ""]
        for e in qf
          let errtext+=split(e['text'], '\n')
        endfor

        echon l:msg
      endif
    endif

    if l:added_match
      :augroup JSO_Remove_matches
      :au TextChanged <buffer> :call s:Clear_matches()
      :augroup END
    endif

    let l:saved_ea=&g:equalalways
    let l:savedview={}
    set noequalalways

    " For some reason, if this is turned off and you have a split, and you hit
    " jomake multiple times, the top window will keep getting smaller.
    let l:saved_splitbelow=&g:splitbelow
    set splitbelow

    if a:no_errors_msg
      if l:founderr == 1 && !empty(errtext)
        exec 'silent! bw! ' s:jengaerrorfile
        let errtext=s:modify_for_values_do_not_match(errtext)
        call writefile(errtext, s:jengaerrorfile)

        let l:wheight = min([len(errtext), g:max_jomake_preview_size])
        exec 'silent set previewheight=' . l:wheight
        exec 'silent bel pedit +setl\ bt=nofile\ bh=hide\ nobl ' . s:jengaerrorfile

        if s:contains_escape(errtext)
          wincmd P
          :AnsiEsc
          wincmd p
        endif
      else 
        let l:savedview=winsaveview()
        :pclose!
      endif

      if l:saved_ea
        " Restoring equalalways to prev setting causes all windows to equalize,
        " which isn't what we want.  Could probably do better, but for now, just
        " store height and size of current window and restore them
        let l:wh=winheight(0)
        let l:ww=winwidth(0)
        let &equalalways=l:saved_ea
        exec ':' . l:wh . 'wincmd _'
        exec ':' . l:ww . 'wincmd |'
        :call winrestview(l:savedview)
      endif

      let &g:splitbelow=l:saved_splitbelow

      :redraw!
    endif

  endfunction

  function! s:Prev_jomake_error() abort
    cp
    call s:Display_jomake_error(1)
  endfunction

  function! s:Next_jomake_error() abort
    cn
    call s:Display_jomake_error(1)
  endfunction

  function! s:Refresh_jomake(jump_to_first_error, wait_for_completion) abort
    let &l:errorformat = s:errorformat

    let &g:errorformat=&l:errorformat

    let l:localfile = expand("%:p:h")

    :call s:SetupJomake()

    " t_ti, t_te control switching to the alternate screen, which is really
    " distracting
    let l:ti=&t_ti
    let l:te=&t_te
    set t_ti= t_te=
    let l:shellpipe=&shellpipe
    set shellpipe=>

    if a:wait_for_completion
      set makeprg=/j/office/app/vim/prod/bin/vim-jenga-status-v1\ -wait
    else
      set makeprg=/j/office/app/vim/prod/bin/vim-jenga-status-v1
    endif
    :silent execute 'make!'

    let &shellpipe=l:shellpipe
    let &t_ti=l:ti
    let &t_te=l:te

    if a:jump_to_first_error
      :silent! :cc!

      call s:Display_jomake_error(1)

      let l:qf = getqflist()
      if len(l:qf) > 0
        :echo l:qf[0]['text']
      endif
    else
      call s:Display_jomake_error(0)
    endif
  endfunction

  function! s:Jomake_test_error_files(dir) abort
    let l:files = systemlist('find ' . a:dir . ' -type f -name "*.in"')
    " let l:files = systemlist('cat ' . a:dir)
    for f in l:files
      let &l:errorformat = s:errorformat
      let &g:errorformat=&l:errorformat

      let s:contents = system('cat ' . f)
      silent cgetexpr system('col -b', s:contents)
      let l:qf=getqflist()
      call writefile(map(copy(l:qf), 'string(v:val)'), f . '.unfiltered')
      call writefile(map(filter(l:qf, 'v:val["valid"]'), 'string(v:val)'), f . '.out')
    endfor
  endfunction

  :function! Jomake_load_error(filename) abort
    let s:override_target_file=a:filename
    :call s:Refresh_jomake(1)
    let s:override_target_file=''
  endfunction

  :command! JomakeClear :call <SID>Clear_all_indicators()
  :command! JomakePrev :call <SID>Prev_jomake_error()
  :command! JomakeNext :call <SID>Next_jomake_error()
  :command! Jomake call <SID>Refresh_jomake (1, 0)
  :command! JomakeWait call <SID>Refresh_jomake (1, 1)
  :command! Jomakes call <SID>Refresh_jomake (0, 0)

else " Use the new jomake!
  let s:already_setup = 0
  let s:jengaerrorfile=tempname() . '.err'
  let s:jengaerrorcontents = ''
  let s:signs={}
  let s:signnumber=109
  let s:matchgroup='JSOerror'

  if !exists("g:max_jomake_preview_size")
    let g:max_jomake_preview_size=30
  endif

  function! s:SetupJomake() abort
    if !s:already_setup
      :sign define jomake text=>>
      :exec ':highlight ' . s:matchgroup . ' cterm=underline term=underline gui=undercurl'
      augroup Jomake
        au BufWinEnter *.ml call s:Display_jomake_error(0)
        au BufWinEnter *.mli call s:Display_jomake_error(0)
        au BufEnter *.ml call s:Display_jomake_error(0)
        au BufEnter *.mli call s:Display_jomake_error(0)
      augroup END
      let s:already_setup = 1
    endif
  endfunction

  function! s:Clear_matches() abort
    let matches=getmatches()

    for m in getmatches()
      if get(m, 'group', '') == s:matchgroup
        call matchdelete(m['id'])
      endif
    endfor

    :silent! au! JSO_Remove_matches TextChanged <buffer>
  endfunction

  function! s:Clear_signs(clear_these_signs) abort
    for i in a:clear_these_signs
      :exe ':silent! sign unplace  ' . l:i
      unlet s:signs[l:i]
    endfor
  endfunction

  function! s:Place_sign(bufnr, line) abort
    exec ':sign place ' . s:signnumber . ' line=' . a:line . ' name=jomake buffer=' . a:bufnr
    let s:signs[s:signnumber]=1
    let s:signnumber+=1
  endfunction

  function! s:Clear_all_indicators() abort
    :call s:Clear_signs(keys(s:signs))
    :call s:Clear_matches()
  endfunction

  function! s:Time_diff_to_str(seconds) abort
    if a:seconds > 90 
      return (a:seconds / 60) . 'm'
    else
      return a:seconds . 's'
    endif
  endfunction

  function! s:modify_for_values_do_not_match(msg) abort
    let l:step = 0
    let l:beg=[]
    let l:left=[]
    let l:right=[]
    let l:end=[]

    for i in a:msg
      if l:step == 0
        let l:beg+=[i]
        if i =~ '.*Values do not match.*'
          let l:step = 1
        endif
      elseif l:step == 1
        if i =~ '.*is not included in.*'
          let l:step = 2
          let l:sepstr=i
        else
          let l:left+=[i]
        endif
      elseif l:step == 2
        if i =~ 'File "'
          let l:step += 1
          let l:end += [i]
        else
          let l:right+=[i]
        endif
      elseif l:step == 3
        let l:end += [i]
      endif
    endfor

    if l:step < 2 
      return [0, a:msg]
    endif

    let l:sep = [nr2char(27) . '[33m' . l:sepstr . nr2char(27) . '[0;']
    let l:leftfile='/tmp/left'.$USER
    let l:rightfile='/tmp/right'.$USER
    :call writefile(l:left, l:leftfile)
    :call writefile(l:right, l:rightfile)
    let l:diff = systemlist('patdiff -context 10000 ' . l:leftfile . ' ' . l:rightfile . ' | tail -n +4 | sed -e "s/\t/    /g"')
    let l:hrbeg = ['=============================== Diff' ]
    let l:hrend = ['=============================== End diff']
    return [1, l:beg + l:hrbeg + l:diff + l:hrend + l:left + l:sep + l:right + l:end]
  endfunction

  function! s:Display_jomake_error(no_errors_msg) abort
    let l:old_signs = keys(s:signs)

    :call s:Clear_matches()

    let qf=getqflist()

    let errtext=[] 
    let founderr=0
    let l:added_match = 0

    for e in l:qf
      if get(e, 'valid', 0) && get(e, 'lnum', 0)
        let founderr=1
        :call s:Place_sign(e['bufnr'], e['lnum'])

        if get(e, 'bufnr', -1) == bufnr('%')
          if get(e, 'col', 0) 
            let chars = get(e,'nr', e['col'])  - e['col'] 
            let e['nr'] = 0
            let e['col'] += 1

            ":echo e
            let l:pattern = '\%' . e['lnum'] . 'l\%' . e['col'] . 'c\_.\{' . l:chars . '}'
            ":echo e
            let l:added_match = 1
            :call matchadd(s:matchgroup, l:pattern)
          else
            let chars = 0
          endif

          if line('.') == e['lnum']
            if !empty(e['text'])
              if empty(errtext)
                let l:header = '--line ' . e['lnum'] . ' of ' . expand('%:t')

                if get(e, 'col', 0)
                  let l:header.=' cols ' . e['col']

                  if l:chars > 0
                    let l:header.= '-' . (e['col'] + l:chars)
                  endif
                endif

                let errtext+= [l:header]
              endif

              let errtext+=['']
              let errtext+=split(e['text'], '\n')
            endif
          endif
        endif
      endif
    endfor

    :call s:Clear_signs(l:old_signs)

    if l:founderr == 0
      let l:status = system('jenga monitor -snapshot')
      let g:status=l:status
      if stridx(l:status, '!') >= 0
        let l:founderr = 1
        let l:msg = 'Found error but cannot parse it.  Please send error to as-vim@.'
        let errtext+=[l:msg, ""]
        for e in qf
          let errtext+=split(e['text'], '\n')
        endfor

        echon l:msg
      endif
    endif

    if l:added_match
      :augroup JSO_Remove_matches
      :au TextChanged <buffer> :call s:Clear_matches()
      :augroup END
    endif

    let l:saved_ea=&g:equalalways
    let l:savedview={}
    set noequalalways

    " For some reason, if this is turned off and you have a split, and you hit
    " jomake multiple times, the top window will keep getting smaller.
    let l:saved_splitbelow=&g:splitbelow
    set splitbelow

    if a:no_errors_msg
      if l:founderr == 1 && !empty(errtext)
        exec 'silent! bw! ' s:jengaerrorfile
        let [l:need_ansi, errtext]=s:modify_for_values_do_not_match(errtext)
        call writefile(errtext, s:jengaerrorfile)

        let l:wheight = min([len(errtext), g:max_jomake_preview_size])
        exec 'silent set previewheight=' . l:wheight
        exec 'silent bel pedit +setl\ bt=nofile\ bh=hide\ nobl ' . s:jengaerrorfile
        if l:need_ansi
          wincmd P
          :AnsiEsc
          wincmd p
        endif
      else 
        let l:savedview=winsaveview()
        :pclose!
      endif

      if l:saved_ea
        " Restoring equalalways to prev setting causes all windows to equalize,
        " which isn't what we want.  Could probably do better, but for now, just
        " store height and size of current window and restore them
        let l:wh=winheight(0)
        let l:ww=winwidth(0)
        let &equalalways=l:saved_ea
        exec ':' . l:wh . 'wincmd _'
        exec ':' . l:ww . 'wincmd |'
        :call winrestview(l:savedview)
      endif

      let &g:splitbelow=l:saved_splitbelow

      :redraw!

      if l:founderr == 0 
        if stridx(l:status, 'finished') < 0
          echon 'Hold your horses! (' . substitute(l:status, '\n', '', 'g') . ')'
        else
          echon 'HURRAH (completed ' . s:Time_diff_to_str(localtime() - s:jenga_error_modtime) . ' ago)'
        endif
      endif
    endif

  endfunction

  function! s:Prev_jomake_error() abort
    cp
    call s:Display_jomake_error(1)
  endfunction

  function! s:Next_jomake_error() abort
    cn
    call s:Display_jomake_error(1)
  endfunction

  function! s:Refresh_jomake(jump_to_first_error) abort
    let &l:errorformat = s:errorformat

    let &g:errorformat=&l:errorformat

    let l:localfile = expand("%:p:h")

    :call s:SetupJomake()

    let l:errorfile = s:Vim_target_file(expand("%:p:h"))

    if a:jump_to_first_error 
      let s:detect_jsocaml_changes=0
      let s:jenga_error_contents = system('cat ' . l:errorfile)
      let s:jenga_error_modtime=getftime(l:errorfile)
      silent cexpr system('col -b', s:jenga_error_contents)
      call s:Display_jomake_error(1)
    else
      let s:jenga_error_contents = system('cat ' . l:errorfile)
      let s:jenga_error_modtime=getftime(l:errorfile)
      cgetexpr system('col -b', s:jenga_error_contents)

      if s:detect_jsocaml_changes
        " CR idamron for avaron : No idea what you were intending here
        call feedkeys("f\e", "n")
        redraw!
      else
        call s:Display_jomake_error(1)
      endif
    endif
  endfunction

  function! s:Jomake_test_error_files(dir) abort
    let l:files = systemlist('find ' . a:dir . ' -type f -name "*.in"')
    " let l:files = systemlist('cat ' . a:dir)
    for f in l:files
      let &l:errorformat = s:errorformat
      let &g:errorformat=&l:errorformat

      let s:contents = system('cat ' . f)
      silent cgetexpr system('col -b', s:contents)
      let l:qf=getqflist()
      call writefile(map(copy(l:qf), 'string(v:val)'), f . '.unfiltered')
      call writefile(map(filter(l:qf, 'v:val["valid"]'), 'string(v:val)'), f . '.out')
    endfor
  endfunction

  :function! Jomake_load_error(filename) abort
    let s:override_target_file=a:filename
    :call s:Refresh_jomake(1)
    let s:override_target_file=''
  endfunction

  :command! JomakeClear :call <SID>Clear_all_indicators()
  :command! JomakePrev :call <SID>Prev_jomake_error()
  :command! JomakeNext :call <SID>Next_jomake_error()
  command! Jomake call <SID>Refresh_jomake (1)
  command! Jomakes call <SID>Refresh_jomake (0)
  command! Jomakedetect call <SID>Set_detect_changes ()
endif

function! s:Hg_root() abort
  return join(systemlist("hg root"),'')
endfunction

" If we add another function like these, create a shared one.
function! s:Fe_crs(switches)
  let root_directory=s:Hg_root()
  cexpr ("fecrs[0]: Entering directory '".root_directory."'\n".system("fe crs " . a:switches))
endfunction

function! s:Fe_conflicts(switches)
  cexpr system("fe conflicts " . a:switches)
endfunction

function! s:Fe_compile(bang, switches)
  let l:files=escape(a:switches, ' ')
  let l:cdcmd=''

  if empty(l:files)
    let l:default_build_target = join(systemlist('fe show -property default-build-target'), '')

    if v:shell_error == 0
      let l:files=l:default_build_target
      echo 'Building default build target ' l:default_build_target
      let l:cdcmd="cd\\ " . s:Hg_root() . "\\ &&\\ "
    endif
  endif

  execute "setlocal makeprg=".l:cdcmd."~/.vim/bundle/Jsocaml/bin/vim-omake\\ -j\\ 5\\ ".l:files

  if a:bang
    execute "Make!"
  else 
    execute "Make"
  endif

endfunction

function! Fe_diff_with_base() abort
  let l:ft=&ft
  let l:filename=expand('%') . '-base.tmp'
  let l:baserev=system('fe show -base')
  :silent let l:file = systemlist('hg cat ' . expand('%') . ' -r ' . l:baserev)
  :call writefile(l:file, l:filename)

  :exe 'keepalt leftabove vert diffsplit ' l:filename
  :autocmd BufHidden <buffer> :diffoff!
  :autocmd BufHidden <buffer> :set nodiff
  wincmd p
  :exec 'silent set ft=' . l:ft
  :diffthis
endfunction

function! s:Fesummary() abort
  let l:filename=s:Hg_root() . "/fe-summary.tmp"
  :exec "e " . l:filename
  :silent %!COLUMNS=300 fe show -omit-completed-review -omit-review-sessions-in-progress-table
  :normal Go
  :normal mao(Press <CR> to jump to file, s to split file, d to split then show the fe diff, D to diff without splitting first)
  :silent r!COLUMNS=300 fe diff -summary | cut -c 3-
  :normal Go
  :normal o─────hg status─────
  :silent r!hg status
  :normal o───────────────────
  :normal Go
  :silent r!COLUMNS=300 fe crs
  :silent setlocal nomod readonly ft=text
  :normal 'a5jz.
  :AnsiEsc
  :nnoremap <buffer> <CR> gf
  :nnoremap <buffer> s <c-w>f
  :nnoremap <buffer> d <c-w>f:Fediff<CR>
  :nnoremap <buffer> D gf:Fediff<CR>
endfunction

command! Fediff :call Fe_diff_with_base()
command! Fesummary :call s:Fesummary()
command! -nargs=* Fecrs call <SID>Fe_crs(<q-args>)
command! -nargs=* Feconflicts call <SID>Fe_conflicts(<q-args>)
command! -bang -complete=dir -nargs=* Fecompile call <SID>Fe_compile(<bang>0, <q-args>)
