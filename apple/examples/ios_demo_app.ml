open! Core

module Apple = Bonsai_apple

let initial_tab_id () =
  let initial_tab =
    match Sys.getenv "BONSAI_NATIVE_INITIAL_TAB" with
    | Some value -> Some value
    | None -> Sys.getenv "BONSAI_APPLE_INITIAL_TAB"
  in
  match initial_tab with
  | Some ("counter" | "0") -> "counter"
  | Some ("todo" | "1") -> "todo"
  | Some ("search" | "2") -> "search"
  | _ -> "counter"
;;

let component graph =
  let open Bonsai.Let_syntax in
  let counter = Counter.component graph in
  let todo = Todo.component graph in
  let search = Searchable_list.component graph in
  let selected_tab, set_selected_tab = Bonsai.state (initial_tab_id ()) graph in
  let%arr counter and todo and search and selected_tab and set_selected_tab in
  Apple.tab_view
    ~selected:selected_tab
    ~on_select:set_selected_tab
    [ Apple.tab
        ~id:"counter"
        ~title:"Counter"
        ~system_image:"plus.circle"
        counter
    ; Apple.tab ~id:"todo" ~title:"Todo" ~system_image:"checklist" todo
    ; Apple.tab
        ~id:"search"
        ~title:"Search"
        ~system_image:"magnifyingglass"
        ~role:Apple.Search
        search
    ]
;;
