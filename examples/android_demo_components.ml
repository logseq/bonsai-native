module Android = Bonsai_android

type todo =
  { id : string
  ; title : string
  }

let counter graph =
  let count, set_count = Android.state graph ~key:"count" 0 in
  Android.vstack
    ~spacing:12.
    [ Android.text (string_of_int count)
    ; Android.button "Increment" ~on_click:(set_count (count + 1))
    ]
  |> Android.padding
;;

let todo graph =
  let input, set_input = Android.state graph ~key:"input" "" in
  let todos, set_todos = Android.state graph ~key:"todos" [] in
  let add () =
    if input <> ""
    then set_todos ({ id = input; title = input } :: todos) ()
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

let contains_case_insensitive text ~substring =
  let text = String.lowercase_ascii text in
  let substring = String.lowercase_ascii substring in
  let text_length = String.length text in
  let substring_length = String.length substring in
  let rec loop index =
    if substring_length = 0
    then true
    else if index + substring_length > text_length
    then false
    else if String.sub text index substring_length = substring
    then true
    else loop (index + 1)
  in
  loop 0
;;

let search graph =
  let query, set_query = Android.state graph ~key:"query" "" in
  let items =
    List.filter (fun item -> contains_case_insensitive item ~substring:query) all_search_items
  in
  Android.vstack
    ~spacing:12.
    [ (Android.text_field ~text:query ~placeholder:"Search" ~on_change:set_query ()
       |> Android.frame ~width:360. ~height:44.)
    ; (Android.list items ~key:(fun value -> value) ~row:Android.text
       |> Android.frame ~width:360. ~height:620.)
    ]
  |> Android.padding
;;

let metadata = [ "counter", "Counter"; "todo", "Todo"; "search", "Search" ]

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
