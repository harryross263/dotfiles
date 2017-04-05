#!/bin/sh
# Shell script to start Vim with less.vim.
# Read stdin if no arguments were given and stdin was redirected.

if test -t 1; then
  if hgroot=$(hg root 2>/dev/null); then
    add_root_to_path="set path+=${hgroot}"
  else
    #NO-OP
    add_root_to_path='let &path=&path'
  fi
    
  if test $# = 0; then
    if test -t 0; then
      echo "Missing filename" 1>&2
      exit
    fi
    vim --cmd "$add_root_to_path" --cmd 'let no_plugin_maps = 1' -c 'source $HOME/.vim/bundle/Jsocaml/bin/fe-less.vim' \
      -c 'AnsiEsc' -
  else
    vim --cmd "$add_root_to_path" --cmd 'let no_plugin_maps = 1' -c 'source $HOME/.vim/bundle/Jsocaml/bin/fe-less.vim' "$@"
  fi
else
  # Output is not a terminal, cat arguments or stdin
  if test $# = 0; then
    if test -t 0; then
      echo "Missing filename" 1>&2
      exit
    fi
    cat
  else
    cat "$@"
  fi
fi
