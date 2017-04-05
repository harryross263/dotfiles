" Vim filetype plugin for viewing fix logs
" Last Change:  Fri Mar 27 08:13:20 GMT 2009
" Maintainer: Benedikt Grundmann <bgrundmann@janestcapital.com>

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let b:undo_ftplugin = "setlocal textwidth< nowrap< statusline<"


if !exists("*FixLogSafeSummarizeFix")
  function FixLogSafeSummarizeFix()
    let l:summary = ""
    let l:fixmsg = system("fixlogviewer.exe fields 35,msgtype,orderqty,symbol,price,ordstatus,orderid", getline("."))
    if v:shell_error ||  l:fixmsg =~ '^\*\*\*'
      return ''
    else
      let [l:type, l:longtype, l:quantity, l:symbol, l:price, l:ordstatus, l:orderid] = split(l:fixmsg, '\t', 1)
      let l:orderid = substitute(l:orderid, '[\n\r]$', '', '')  
      if l:type ==# "8"  
        " Execution report
        let l:summary = printf("%s %s %s @ %s [%s]", l:ordstatus, l:quantity, l:symbol, l:price, l:orderid)
      elseif l:type ==# "D"
        let l:summary = printf("Order %s %s @ %s", l:quantity, l:symbol, l:price)
      elseif l:type ==# "F"
        let l:summary = printf("Cancel request %s %s", l:quantity, l:symbol)
      else
        let l:summary = l:longtype
      endif
      return l:summary
    endif
  endfunction

  function UtilVarOrEmpty(var)
    if exists(a:var) 
      return eval(a:var)
    else
      return ''
    endif
  endfunction
endif

" buffer settings {{{ 
" We don't want any text wrapping or mangling in the log window
setlocal textwidth=0 
setlocal nowrap
setlocal statusline=%{UtilVarOrEmpty('b:condition')}%{FixLogSafeSummarizeFix()}%=%F%m%R\ [pos=%l,%v]\ [len=%L\ (%p%%)]
" }}}

" Mappings {{{

" Map <Leader>d to view details
" Add mappings, unless the user didn't want this.
if !exists("no_plugin_maps") && !exists("no_fixlog_maps")
  noremap <SID>ViewDetails :call <SID>ViewDetails()<CR>
  noremap <buffer> <unique> <script> <Plug>FixlogDetails  <SID>ViewDetails
  "noremenu <buffer> <script> Plugin.Fixlog.Details   <SID>ViewDetails

  if !hasmapto('<Plug>FixLogDetails')
    map <buffer> <unique> <LocalLeader>d  <Plug>FixlogDetails
  endif

  " Map <Leader>f to view filter
  noremap <SID>Filter :call <SID>Filter()<CR>
  noremap <buffer> <unique> <script> <Plug>FixlogFilter   <SID>Filter
  "noremenu <buffer> <script> Plugin.Fixlog.Filter   <SID>Filter

  if !hasmapto('<Plug>FixLogFilter')
    map <buffer> <unique> <LocalLeader>f  <Plug>FixlogFilter
  endif
endif
" }}}

if exists("*s:AdjustWindowToContent")
  finish
end

function s:AdjustWindowToContent()
  let l:used=line("$") 
  if l:used < winheight("")
    exec "resize " . l:used
  endif
  " CR bgrundmann cross hack
  1
  " Force the redraw to make sure that the scrolling to the top happens
  " before we go a different buffer
  redraw
  if l:used == winheight("")
    setlocal winfixheight
  endif
endfunction

function s:FilterBy(field,value)
  let l:srcbuf=bufnr("%")
  " Create new window 
  wincmd n
  let l:dstbuf=bufnr("%")
  " That buffer does not represent a underlying file
  setlocal buftype=nofile
  setlocal bufhidden=delete
  setlocal noswapfile
  let b:condition='FILTER ' . a:field . '==' . a:value . '  '
  setfiletype fixlog
  " Go back to the src buffer
  execute "sbuffer " . l:srcbuf
  " and copy everything
  %yank
  " Go back to the dst buffer
  execute "sbuffer " . l:dstbuf
  " And replace the line in there with the output of the fixlogviewer
  put
  g/^$/d
  exec "%!fixlogviewer.exe dump " . shellescape(a:field) . " == " . shellescape(a:value)
  call s:AdjustWindowToContent()
endfunction

function s:Decode(line)
  let l:fixmsg = system("fixlogviewer.exe fields symbol,orderid,clordid", a:line)
  if v:shell_error || l:fixmsg =~ '^\*\*\*'
    return {}
  else
    let l:d = {}
    let [l:symbol, l:orderid, l:clordid] = split(substitute(l:fixmsg, '[\n\r]$', '', ''), '\t', 1)
    let l:d['symbol'] = l:symbol
    let l:d['orderid'] = l:orderid
    let l:d['clordid'] = l:clordid
    return l:d
  endif
endfunction

function s:Filter()
  let l:d = s:Decode(getline("."))
  if ! empty(l:d)
    let l:items = items(l:d)
    let l:question = ""
    for [k, v] in l:items
      if l:question != '' 
        let l:question = l:question . "\n"
      endif
      let l:question = l:question . k . "==" . v
    endfor
    let ndx = confirm("What do you want to filter by?", l:question)
    if ndx > 0 
      call s:FilterBy(l:items[ndx-1][0], l:items[ndx-1][1])
    endif
  endif
endfunction

function s:ViewDetails()
  let l:logbuf=bufnr("%")
  " Create new window (to show details of a line)
  wincmd n
  let l:detailbuf=bufnr("%")
  " That buffer does not represent a underlying file
  setlocal buftype=nofile
  setlocal bufhidden=delete
  setlocal noswapfile
  setlocal statusline=DETAILS\ %{UtilVarOrEmpty('b:fixmessageSummary')}%=%F%m%R\ [pos=%l,%v]\ [len=%L\ (%p%%)]
  " We don't want any text wrapping or mangling in the detail window 
  setlocal textwidth=0 
  setlocal nowrap
  " Go back to the log window
  execute "sbuffer " . l:logbuf
  " Get the current line
  yank
  " Go back to the detail window
  execute "sbuffer " . l:detailbuf
  " And replace the line in there with the output of the fixlogviewer
  put
  " But first generate the status line
  let b:fixmessage=getline(".")
  let b:fixmessageSummary=FixLogSafeSummarizeFix()
  .!fixlogviewer.exe pretty
  " Get rid of empty lines
  g/^$/d
  call s:AdjustWindowToContent()
  " Go back to log window
  execute "sbuffer " . l:logbuf
endfunction

