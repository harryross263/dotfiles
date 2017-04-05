all: omake_filter.native
	
omake_filter.native: omake_filter.ml
	ocamlbuild omake_filter.native -tag use_str
	mv _build/omake_filter.native omake_filter.native
