if exists("g:loaded_local_ocaml")
  finish
endif
let g:loaded_local_ocaml = 1

setlocal nowrap

" arpeggio map to add a cr
call arpeggio#map("n", "", 0, "gc", "O(* CR <C-R>=substitute(system(\"whoami\"), '\\n', '', 'g')<CR>: *)<ESC>bT:i ") 
call arpeggio#map("n", "", 0, "ui", "O(* CR <C-R>=substitute(system(\"whoami\"), '\\n', '', 'g')<CR>: *)<ESC>bT:i ") 

" altr setup
call altr#define('%.ml', '%.mli', '%_intf.ml')

" merlin setup
nnoremap <localleader>s :MerlinLocate<CR>
nnoremap <localleader>t :TypeOf<CR>
