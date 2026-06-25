module Native = Bonsai_native

let require condition message =
  if not condition then failwith message
;;

let contains text ~substring =
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

let counter graph =
  let count, set_count = Native.state graph ~key:"count" 0 in
  Native.vstack
    [ Native.text (string_of_int count)
    ; Native.button "Increment" ~on_click:(set_count (count + 1))
    ]
;;

let test_event_rerenders_component_state () =
  let app = Native.App.create counter in
  let before = Native.App.render_json app in
  require (contains before ~substring:{|"text":"0"|}) "initial render should show count 0";
  Native.App.dispatch_click app 1;
  let after = Native.App.render_json app in
  require (contains after ~substring:{|"text":"1"|}) "click should rerender count 1"
;;

let scoped_counter key graph =
  Native.scope graph ~key (fun graph ->
    let count, set_count = Native.state graph ~key:"count" 0 in
    Native.button (key ^ ":" ^ string_of_int count) ~on_click:(set_count (count + 1)))
;;

let test_scoped_state_is_independent () =
  let app =
    Native.App.create (fun graph ->
      Native.vstack [ scoped_counter "a" graph; scoped_counter "b" graph ])
  in
  let before = Native.App.render_json app in
  require (contains before ~substring:{|"text":"a:0"|}) "initial render should show a:0";
  require (contains before ~substring:{|"text":"b:0"|}) "initial render should show b:0";
  Native.App.dispatch_click app 1;
  let after = Native.App.render_json app in
  require (contains after ~substring:{|"text":"a:1"|}) "first scoped counter should update";
  require (contains after ~substring:{|"text":"b:0"|}) "second scoped counter should not update"
;;

let test_change_event_updates_component_state () =
  let component graph =
    let value, set_value = Native.state graph ~key:"value" "" in
    Native.text_field ~text:value ~placeholder:"Search" ~on_change:set_value ()
  in
  let app = Native.App.create component in
  let before = Native.App.render_json app in
  require (contains before ~substring:{|"text":""|}) "initial field should be empty";
  Native.App.dispatch_change app 1 ~text:"tasks";
  let after = Native.App.render_json app in
  require (contains after ~substring:{|"text":"tasks"|}) "change should rerender text"
;;

let () =
  test_event_rerenders_component_state ();
  test_scoped_state_is_independent ();
  test_change_event_updates_component_state ()
