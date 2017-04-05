" Vim script to work like "less"
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last Change:	2012 May 18
" Hacked by avaron!

" Avoid loading this file twice, allow the user to define his own script.
if exists("loaded_less")
  finish
endif
let loaded_less = 1

" If not reading from stdin, skip files that can't be read.
" Exit if there is no file at all.
if argc() > 0
  let s:i = 0
  while 1
    if filereadable(argv(s:i))
      if s:i != 0
	sleep 3
      endif
      break
    endif
    if isdirectory(argv(s:i))
      echomsg "Skipping directory " . argv(s:i)
    elseif getftime(argv(s:i)) < 0
      echomsg "Skipping non-existing file " . argv(s:i)
    else
      echomsg "Skipping unreadable file " . argv(s:i)
    endif
    echo "\n"
    let s:i = s:i + 1
    if s:i == argc()
      quit
    endif
    next
  endwhile
endif

" Switch to editing (switch off less mode)
command! -nargs=* -buffer Fedit call <SID>Edit()
command! -nargs=* -buffer FeditOld call <SID>OldEdit()
set noma
set nowrite
au VimEnter * set nomod

nnoremap <buffer> <CR> :Fedit<CR>

fun! s:RemoveFeGutter(s) 
  return strpart(a:s, 7)
endfun

fun! s:FindLine(sought) 

  let sought=a:sought

  let sought=s:RemoveFeGutter(sought)

  let lines=getbufline("%",1,10000)

  let n=0
  let loc=-1

  for line in lines
    let n += 1

    if stridx(line, sought) >= 0
      if loc >= 0 
        return [n, 0]
      else 
        let loc=n
      endif
    endif
  endfor 

  return [loc, 1]
endfun 

fun! s:getlinewithoutescapes(pos)
  let lines=getbufline('%',a:pos)
  for line in lines
    "remove escape sequences
    let line=substitute(line, '\e\[[0-9;]\+[mK]', '', 'g')
    "remove newlines
    let line=substitute(line, '\n','','g')
    return line
  endfor

  return "$stop trying$"
endfun

fun! s:nospaces(s)
  return substitute(a:s, '\s', '', 'g')
endfun

fun! s:isminusline(line)
  " Depending on g or file-by-file, the minus could be in different places.  
  return a:line[0] == '-' || a:line[1] == '-' || a:line[2] == '-' || a:line[3] == '-' 
endfun

" Returns string of (hopefully unique) line, and amount to move from that string to get to original position
fun! s:FirstNonMinusLines(direction)
  let curpos=getcurpos()[1]
  let adj=0

  let ret=[]
  let line=s:getlinewithoutescapes(curpos)

  if s:isminusline(line) && a:direction < 0
    " If we're on a minus line, let's prefer to end up on the line after
    let adj=1
  end

  while line!='$stop trying$' && len(ret) < 20

    if !(s:isminusline(line))
      if len(s:nospaces(line))>=6
        let ret+=[[line, adj]]
      endif
      let adj-=a:direction
    endif

    let curpos+=a:direction
    let line=s:getlinewithoutescapes(curpos)
  endwhile

  return ret
endfun

fun! s:sortingorder(s1,s2) 
  return abs(a:s1[1]) - abs(a:s2[1])
endfun

fun! s:gotoline(line_and_adj, loc)
  call cursor(a:loc+a:line_and_adj[1], 1)
endfun

fun! s:getscrolllocation()

  return [winsaveview(), winheight(0)]
endfun

fun! s:scrollto(scrollloc) 
  let curscrollloc=s:getscrolllocation()

  let viewbef=a:scrollloc[0]
  let heightbef=a:scrollloc[1]
  let viewaft=curscrollloc[0]
  let heightaft=curscrollloc[1]
  
  let linesabovecursor=heightaft * (viewbef['lnum'] - viewbef['topline']) / heightbef
  :call winrestview({'topline': viewaft['lnum'] - linesabovecursor})
endfun

fun! s:Edit()
  if g:fedit_split_type == "v"
    vsp
  elseif g:fedit_split_type == "h"
    sp
  else 
    throw "g:fedit_split_type can only be v or h"
  endif

  let scrollloc=s:getscrolllocation()

  let beforelines=s:FirstNonMinusLines(-1)
  let afterlines=s:FirstNonMinusLines(1)
  let linestotry=beforelines + afterlines
  call sort(linestotry, "s:sortingorder")

  silent! normal j0l

  exec "normal! ?^tip file *= \\zs\\|@@@@* \\zs[a-zA-Z0-9.+][^ ]*[/.].*\\|^\<c-v>\<esc>\\[1;34m@@* \\zs[^,][^,]* @.*\\n.*scrutiny \<CR>gf"


  let best=[]
  let g:fedit_dbg=[]
  for line_and_adj in linestotry
    let found=s:FindLine(line_and_adj[0])

    let g:fedit_dbg += [[line_and_adj, found]]
    if found[0] >= 0 
      if found[1] == 1
        "Unique match!  Let's go there
        call s:gotoline(line_and_adj, found[0])
        let best=[]
        break
      elseif len(best) == 0
        let best = [line_and_adj, found[0]]
      endif
    endif
  endfor

  if len(best) > 0
    call s:gotoline(best[0], best[1])
  endif

  :call s:scrollto(scrollloc)

  set modifiable
  set write
endfun

fun! s:OldEdit()
  if g:fedit_split_type == "v"
    vsp
  elseif g:fedit_split_type == "h"
    sp
  else 
    throw "g:fedit_split_type can only be v or h"
  endif
  0
  normal 0Wgf
  set modifiable
  set write
endfun
" vim: sw=2
"
