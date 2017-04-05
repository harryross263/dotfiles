(** A module to clean up the output of omake to make it vim-friendly  *)
module Dedup = struct

  let is_build_target = Str.regexp ".*- \\(build\\|scan\\) .*"

  let irrelevant_parts_of_build_target = Str.regexp "\\( +\\)"

  let file_that_has_changed = Str.regexp "^\\*\\*\\* \\(omake\\|jenga\\): file \\(.*\\) changed"

  let is_ocamlfind_line = Str.regexp "^ *\\+ ocamlfind .*"

  let previous_errors = ref (Hashtbl.create 1000)

  let should_print = ref false

  let check_line line =
    if Str.string_match is_ocamlfind_line line 0 then
      false
    else
      if Str.string_match is_build_target line 0 then begin
        let my_line = Str.global_replace irrelevant_parts_of_build_target "" line in
        if Hashtbl.mem !previous_errors my_line then
          should_print := false
        else begin
          Hashtbl.add !previous_errors my_line my_line;
          should_print := true;
        end;
        !should_print
      end else begin
        !should_print
      end

  let clear () =
    previous_errors := Hashtbl.create 1000;
    (* reached_targets_not_rebuilt := false; *)
    should_print := false

end

let rec input_line buff =
  let ch = input_char stdin in
  match ch with
  | '\010' .. '\013' ->
    let str = Buffer.contents buff in
    Buffer.clear buff;
    str
  | x ->
    Buffer.add_char buff x;
    input_line buff

let clear_escape_sequences =
  let pattern = Str.regexp "\027\\[K" in
  fun line ->
    Str.global_replace pattern "" line

let is_deadlock = Str.regexp ".* \\(omake\\|jenga\\): deadlock .*"

let is_a_dependency = Str.regexp ".*is a dependency of .*"

let rebuilding = Str.regexp ".*rebuilding"

let is_progress_line =
  let rex1 = Str.regexp "^.?\\[.*=+ *\\] [0-9]+ / [0-9]+$" in
  let rex2 = Str.regexp "^.*todo: [0-9]+ ([0-9]+ / [0-9]+) .*" in
  fun line start ->
    Str.string_match rex2 line start
    || Str.string_match rex1 line start
  ;;

let main output_file omake_root =
  let cnt = ref 0 in
  let ch = ref (open_out output_file) in
  let is_first_line = ref true in
  let last_line_was_progress_bar = ref false in
  let fprintf line =
    let prefix =
      if !last_line_was_progress_bar then "\n"
      else ""
    in
    last_line_was_progress_bar := false;
    Printf.fprintf !ch "%s%s\n" prefix line
  in
  fprintf (Printf.sprintf "- build %s hg.root" omake_root);
  let buff = Buffer.create 97 in
  try
    while true do
      let line = input_line buff in
      let line = clear_escape_sequences line in
      if line = "*** \\(omake\\|jenga\\): polling for filesystem changes" then begin
        is_first_line := true;
        incr cnt;
        fprintf (Printf.sprintf "%d : Finished compiling" !cnt);
        Printf.printf "%d : Finished compiling\n%!" !cnt;
        Dedup.clear ();
      end else if Str.string_match rebuilding line 0 then begin
        close_out !ch;
        ch := open_out output_file;
        Dedup.clear ();
        fprintf (Printf.sprintf "- build %s hg.root" omake_root);
      end;
      if Str.string_match is_deadlock line 0 then fprintf line
      else if Str.string_match is_a_dependency line 0 then fprintf line
      else ();
      if is_progress_line line 0 then begin
        last_line_was_progress_bar := true;
        Printf.printf "%s\013" line;
        Printf.fprintf !ch "%s\013" line;
      end else begin
        if Dedup.check_line line then begin
          fprintf (Printf.sprintf "%s" line);
        end;
        Printf.printf "%s\n" line;
      end;
      flush stdout;
      flush !ch;
    done
  with
  | End_of_file ->
      close_out !ch;
      ()

let () =
  if 3 = Array.length Sys.argv then main Sys.argv.(1) Sys.argv.(2)
  else prerr_string "Typical usage: jomake -j4 -P -o 1p --output-postpone  2>&1 | omake_filter.exe output_file `hg root`\n"
