set nocompatible            "Allow Vim-only settings even if they break vi keybindings.
:filetype on                "Enable filetype detection
set incsearch               "Find as you type
set ignorecase              "Ignore case in search
set scrolloff=5             "Number of lines to keep above/below cursor
set smartcase               "Only ignore case when all letters are lowercase
set number                  "Show line numbers
set wildmode=longest,list   "Complete longest string, then list alternatives
"set pastetoggle=<F2>       "Toggle paste mode
set fileformats=unix        "Use Unix line endings
set smartindent             "Smart autoindenting on new line
set smarttab                "Respect space/tab settings
set history=300             "Number of commands to remember
set noshowmode              "Don't show mode (because of airline)
set noshowmatch             "Don't show matching brackets/parentheses
set backspace=2             "Use standard backspace behavior
set hlsearch                "Highlight matches in search
set ruler                   "Show line and column number
set formatoptions=1         "Don't wrap text after a one-letter word
set linebreak               "Break lines when appropriate
syntax enable               "Enable syntax highlighting
syntax on
set autoindent              "Auto indent based on previous line
let php_htmlInStrings = 1   "Syntax highlight for HTML inside PHP strings
let php_parent_error_open = 1 "Display error for unmatch brackets
let loaded_matchparen = 1   "Force the bracket matcher to not load - very slow in objc

"When in split screen, map <C-LeftArrow> and <C-RightArrow> to switch panes.
nn [5C <C-W>w
nn [5R <C-W>W

"Drupal PHP filetypes
augroup module
	autocmd BufRead,BufNewFile *.module set filetype=php
	autocmd BufRead,BufNewFile *.php set filetype=php
	autocmd BufRead,BufNewFile *.install set filetype=php
	autocmd BufRead,BufNewFile *.inc set filetype=php
	autocmd BufRead,BufNewFile *.profile set filetype=php
	autocmd BufRead,BufNewFile *.theme set filetype=php
augroup END

"Uncomment the following to have Vim jump to the last position when reopening
if has("autocmd")
 au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
 \| exe "normal! g'\"" | endif
endif

"Highlight long comments and trailing whitespace.
highlight ExtraWhitespace ctermbg=red guibg=red
let a = matchadd('ExtraWhitespace', '\s\+$')
highlight OverLength ctermbg=red ctermfg=white guibg=red guifg=white
let b = matchadd('OverLength', '\(^\(\s\)\{-}\(*\|//\|/\*\)\{1}\(.\)*\(\%81v\)\)\@<=\(.\)\{1,}$')

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Vundle
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/Vundle.vim'

"Plugins
Plugin 'plasticboy/vim-markdown'
Plugin 'vim-scripts/eunuch.vim'
Plugin 'vim-scripts/node'
Plugin 'bling/vim-airline'
Plugin 'tpope/vim-fugitive'
Plugin 'edkolev/promptline.vim'
Plugin 'edkolev/tmuxline.vim'
Plugin 'chrisbra/NrrwRgn'
Plugin 'vim-scripts/argtextobj.vim'

"Color schemes
Plugin 'altercation/vim-colors-solarized'
Plugin 'zenorocha/dracula-theme'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Other custom
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"set t_Co=256

"Disable arrow keys for movement in both insert and cmd mode
"Good for learning hjkl
noremap <Left>   <NOP>
noremap <Right>  <NOP>
noremap <Up>     <NOP>
noremap <Down>   <NOP>
inoremap <Left>  <NOP>
inoremap <Right> <NOP>
inoremap <Up>    <NOP>
inoremap <Down>  <NOP>

"Tab settings
set tabstop=4     "Use four spaces for hard tabs
set noexpandtab   "Tab key inserts tabs
set shiftwidth=4  "Use four spaces for auto-indent
set autoindent    "Auto-indent based on previous line

"General
set scrolloff=5   "Keep five lines above and below the cursor

"Wrap at 68 in plaintext files
"From http://www.reddit.com/r/vim/comments/1sqljw/help_vim_hard_wrapping_for_markdown/
"Annoying for YAML headers because they get merged into one line
"augroup Formatting
"    autocmd!
"    autocmd BufNew,BufRead,BufWrite *.txt,*.md setlocal formatoptions=ant textwidth=68 wrapmargin=0
"augroup END

"Write backup files globally, but keep them unique
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
set undodir=~/.vim/undo//

"Disable markdown folding
let g:vim_markdown_folding_disabled=1

"2 spaces in yaml and package.json
autocmd Filetype yaml setlocal tabstop=2 expandtab shiftwidth=2
autocmd BufNewFile,BufRead,BufWrite package.json setlocal tabstop=2 expandtab shiftwidth=2

if has('gui_running')
	set background=light
else
	set background=dark
endif

"K in help opens help for under the cursor
autocmd FileType help setlocal keywordprg=:help

autocmd FileType netrw AirlineRefresh

"""""""""""""""
"Plugin config"
"""""""""""""""

"Airline
let g:airline_powerline_fonts=1
set laststatus=2
let g:airline#extensions#branch#enabled=1
let g:airline#extensions#branch#empty_message='no repo'
let g:airline#extensions#hunks#enabled=0
let g:airline#extensions#whitespace#enabled=1
let g:airline#extensions#whitespace#mixed_indent_algo=1 "Tabs before spaces

autocmd VimEnter * AirlineTheme dark

"Tmuxline
"Future customization ideas: weather, IPs (public and private), ...?
"IP's: When 192.168.1.151 is an IP and there is an alternate (DHCP interface),
"  show the DCHP addr
"  When .1.151 is the only, show the public IP
"  When not .1.151 locally, show the private IP
let g:tmuxline_preset = {
	\'a'       : '#S:#I',
	\'b disabled'       : '',
	\'c disabled'       : '',
	\'win'     : ['#I', '#W'],
	\'cwin'    : ['#I', '#W'],
	\'x disabled'       : '',
	\'y'       : ['%a', '%Y-%m-%d', '%l:%M%p'],
	\'z'       : ['#(whoami)', '#h'],
	\'options' : {'status-justify': 'left'}}

"Promptline
let g:promptline_preset = {
	\'a': [ promptline#slices#host(), promptline#slices#user() ],
	\'b': [ promptline#slices#cwd() ],
	\'z': [ promptline#slices#vcs_branch(), promptline#slices#jobs() ],
	\'warn': [ promptline#slices#battery(), promptline#slices#last_exit_code() ]}

"Solarized
"let &t_Co=256
let g:solarized_termcolors=&t_Co
let g:solarized_termtrans=1      "Transparent background, correct bg color
colorscheme solarized

"""""""""""""""
"Abbreviations"
"""""""""""""""
"Holding shift while ending a CSS comment
ab *? */
