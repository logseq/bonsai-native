module Apple = Bonsai_apple

let all_items = [ "Today"; "Tasks"; "Settings"; "Archive"; "Projects" ]

let contains_case_insensitive text ~substring =
  let text = String.lowercase_ascii text in
  let substring = String.lowercase_ascii substring in
  let text_length = String.length text in
  let substring_length = String.length substring in
  let rec loop index =
    substring_length = 0
    || (index + substring_length <= text_length
        && (String.sub text index substring_length = substring || loop (index + 1)))
  in
  loop 0
;;

let component graph =
  let query, set_query = Apple.state graph ~key:"query" "" in
  let items =
    List.filter (fun item -> contains_case_insensitive item ~substring:query) all_items
  in
  Apple.vstack
    ~spacing:12.
    [ (Apple.text_field ~text:query ~placeholder:"Search" ~on_change:set_query ()
       |> Apple.frame ~width:360. ~height:44.)
    ; (Apple.list items ~key:(fun item -> item) ~row:Apple.text |> Apple.frame ~width:360. ~height:620.)
    ]
;;

let () = ignore component
