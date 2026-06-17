open! Core

module Android = Bonsai_android

type todo =
  { id : string
  ; title : string
  }

let counter graph =
  let open Bonsai.Let_syntax in
  let count, set_count = Bonsai.state 0 graph in
  let%arr count and set_count in
  Android.vstack
    ~spacing:12.
    [ Android.text (Int.to_string count)
    ; Android.button "Increment" ~on_click:(set_count (count + 1))
    ]
  |> Android.padding
;;

let todo graph =
  let open Bonsai.Let_syntax in
  let input, set_input = Bonsai.state "" graph in
  let todos, set_todos = Bonsai.state [] graph in
  let%arr input and set_input and todos and set_todos in
  let add =
    if String.is_empty input
    then Bonsai.Effect.Ignore
    else set_todos ({ id = input; title = input } :: todos)
  in
  Android.vstack
    ~spacing:12.
    [ (Android.hstack
         ~spacing:8.
         [ Android.text_field ~text:input ~placeholder:"New task" ~on_change:set_input ()
           |> Android.frame ~width:260.
         ; Android.button "Add" ~on_click:add
         ]
       |> Android.frame ~width:360. ~height:44.)
    ; (Android.list todos ~key:(fun todo -> todo.id) ~row:(fun todo -> Android.text todo.title)
       |> Android.frame ~width:360. ~height:620.)
    ]
  |> Android.padding
;;

let all_search_items = [ "Today"; "Tasks"; "Settings"; "Archive"; "Projects" ]

let search graph =
  let open Bonsai.Let_syntax in
  let query, set_query = Bonsai.state "" graph in
  let%arr query and set_query in
  let items =
    List.filter all_search_items ~f:(fun item ->
      String.Caseless.is_substring item ~substring:query)
  in
  Android.vstack
    ~spacing:12.
    [ (Android.text_field ~text:query ~placeholder:"Search" ~on_change:set_query ()
       |> Android.frame ~width:360. ~height:44.)
    ; (Android.list items ~key:Fn.id ~row:Android.text
       |> Android.frame ~width:360. ~height:620.)
    ]
  |> Android.padding
;;

let metadata =
  [ "counter", "Counter"
  ; "todo", "Todo"
  ; "search", "Search"
  ]
;;

let normalize_id = function
  | "todo" -> "todo"
  | "search" -> "search"
  | _ -> "counter"
;;

let component_by_id id =
  match normalize_id id with
  | "todo" -> todo
  | "search" -> search
  | _ -> counter
;;
