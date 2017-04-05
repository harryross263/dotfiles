# taken from http://jneen.net/posts/2011-01-12-bash-adventures-read-a-single-character-even-if-its-a-newline
getc() {
  IFS= read -r -n1 -d '' "$@"
}

jenga monitor -exit-on-finish 2>/dev/null \
  | while getc char; do if [[ "$char" == '!' ]]; then exit 0; else printf "%c" "$char"; fi; done
