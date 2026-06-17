open! Core

module Apple = Bonsai_apple

let all_items = [ "Today"; "Tasks"; "Settings"; "Archive"; "Projects" ]

let component graph =
  let open Bonsai.Let_syntax in
  let query, set_query = Bonsai.state "" graph in
  let%arr query and set_query in
  let items =
    List.filter all_items ~f:(fun item ->
      String.Caseless.is_substring item ~substring:query)
  in
  Apple.vstack
    ~spacing:12.
    [ (Apple.text_field ~text:query ~placeholder:"Search" ~on_change:set_query ()
       |> Apple.frame ~width:360. ~height:44.)
    ; (Apple.list items ~key:Fn.id ~row:Apple.text |> Apple.frame ~width:360. ~height:620.)
    ]
;;

let () = ignore component
