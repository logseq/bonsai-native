module Apple = Bonsai_apple
module Backend = Apple.For_testing.Backend
module App = Apple.App.Make (Backend)

let require condition message =
  if not condition then failwith message
;;

let counter graph =
  let count, set_count = Apple.state graph ~key:"count" 0 in
  Apple.vstack
    [ Apple.text (string_of_int count)
    ; Apple.button "Increment" ~on_click:(set_count (count + 1))
    ]
;;

let test_event_rerenders_component_state () =
  Backend.reset ();
  let app = App.create counter in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require (Backend.find_text_exn root ~path:[ 0 ] = "0") "initial count should be 0";
  Backend.click_exn root ~path:[ 1 ];
  require (Backend.find_text_exn root ~path:[ 0 ] = "1") "click should rerender count"
;;

let test_scoped_state_is_independent () =
  let scoped key graph =
    Apple.scope graph ~key (fun graph ->
      let count, set_count = Apple.state graph ~key:"count" 0 in
      Apple.button (key ^ ":" ^ string_of_int count) ~on_click:(set_count (count + 1)))
  in
  Backend.reset ();
  let app =
    App.create (fun graph ->
      Apple.vstack [ scoped "a" graph; scoped "b" graph ])
  in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require (Backend.find_text_exn root ~path:[ 0 ] = "a:0") "initial a count should be 0";
  require (Backend.find_text_exn root ~path:[ 1 ] = "b:0") "initial b count should be 0";
  Backend.click_exn root ~path:[ 0 ];
  require (Backend.find_text_exn root ~path:[ 0 ] = "a:1") "a should update";
  require (Backend.find_text_exn root ~path:[ 1 ] = "b:0") "b should not update"
;;

let test_tab_selection_updates_state () =
  Backend.reset ();
  let component graph =
    let selected, set_selected = Apple.state graph ~key:"selected" "counter" in
    Apple.tab_view
      ~selected
      ~on_select:set_selected
      [ Apple.tab ~id:"counter" ~title:"Counter" (Apple.text "Counter")
      ; Apple.tab ~id:"search" ~title:"Search" ~role:Apple.Search (Apple.text "Search")
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  Backend.select_tab_exn root ~id:"search";
  require
    (Backend.find_text_exn root ~path:[ 1 ] = "Search")
    "tab selection should keep tab content mounted"
;;

let () =
  test_event_rerenders_component_state ();
  test_scoped_state_is_independent ();
  test_tab_selection_updates_state ()
