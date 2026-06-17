open! Core

module Apple = Bonsai_apple
module Backend = Apple.For_testing.Backend
module Renderer = Apple.Renderer.Make (Backend)
module Test_app = Apple.App.Make (Backend)

let noop = Bonsai.Effect.Ignore

let show mounted = mounted |> Renderer.view |> Backend.show

let require_string_equal actual ~expect =
  if not (String.equal actual expect)
  then raise_s [%sexp "strings differ", { actual : string; expect : string }]
;;

let require_raises_string f ~expect =
  let actual =
    match f () with
    | () -> "no exception"
    | exception Failure message -> message
    | exception exn -> Exn.to_string exn
  in
  require_string_equal actual ~expect
;;

let%test_unit "renders primitive nodes and stack hierarchy" =
  Backend.reset ();
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (Apple.vstack
         [ Apple.text "Today"
         ; Apple.hstack
             [ Apple.button "Add" ~on_click:noop
             ; Apple.text_field ~text:"milk" ~placeholder:"Task" ~on_change:(fun _ -> noop)
                 ()
             ]
         ])
  in
  require_string_equal
    (show mounted)
    ~expect:
      {|stack(vertical)#1
  label#5 text=Today
  stack(horizontal)#2
    button#4 text=Add
    text-field#3 text=milk placeholder=Task|}
;;

let%test_unit "button and text-field events are scheduled through Bonsai effects" =
  Backend.reset ();
  let scheduled = ref 0 in
  let text_changes = ref [] in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.vstack
         [ Apple.button "Increment" ~on_click:noop
         ; Apple.text_field
             ~text:""
             ~placeholder:"Search"
             ~on_change:(fun text ->
               text_changes := text :: !text_changes;
               noop)
             ()
         ])
  in
  let root = Renderer.view mounted in
  Backend.click_exn root ~path:[ 0 ];
  Backend.change_text_exn root ~path:[ 1 ] ~text:"bonsai";
  [%test_result: int] !scheduled ~expect:2;
  [%test_result: string list] !text_changes ~expect:[ "bonsai" ]
;;

let%test_unit "keyed list update reuses rows, destroys removed rows, and creates only new keys" =
  Backend.reset ();
  let render rows =
    Apple.list rows ~key:fst ~row:(fun (key, label) ->
      ignore key;
      Apple.text label)
  in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (render [ "a", "Alpha"; "b", "Beta"; "c", "Gamma" ])
  in
  let before = Backend.stats () in
  Renderer.update
    mounted
    (render [ "c", "Gamma"; "b", "Beta updated"; "d", "Delta" ]);
  require_string_equal
    (show mounted)
    ~expect:
      {|list#1
  label#4 key=c text=Gamma
  label#3 key=b text="Beta updated"
  label#5 key=d text=Delta|};
  let diff = Backend.diff_stats before (Backend.stats ()) in
  [%test_result: int] diff.created ~expect:1;
  [%test_result: int] diff.destroyed ~expect:1
;;

let%test_unit "list rejects duplicate keys before mounting" =
  require_raises_string
    (fun () ->
      ignore
        (Apple.list [ "a", "Alpha"; "a", "Again" ] ~key:fst ~row:(fun (_, label) ->
           Apple.text label)
         : Apple.node))
    ~expect:"duplicate Bonsai Apple list key: a"
;;

let%test_unit "large keyed list updates do not rebuild unchanged rows" =
  Backend.reset ();
  let rows n changed_label =
    List.init n ~f:(fun i ->
      let key = Int.to_string i in
      let label = if i = 500 then changed_label else "row-" ^ key in
      key, label)
  in
  let render rows = Apple.list rows ~key:fst ~row:(fun (_, label) -> Apple.text label) in
  let mounted = Renderer.mount ~schedule_event:(fun _ -> ()) (render (rows 1_000 "row-500")) in
  let before = Backend.stats () in
  Renderer.update mounted (render (rows 1_000 "changed"));
  let diff = Backend.diff_stats before (Backend.stats ()) in
  [%test_result: int] diff.created ~expect:0;
  [%test_result: int] diff.destroyed ~expect:0;
  [%test_result: string]
    (Backend.find_text_exn (Renderer.view mounted) ~path:[ 500 ])
    ~expect:"changed"
;;

let%test_unit "app wrapper flushes Bonsai state updates after native events" =
  Backend.reset ();
  let component graph =
    let open Bonsai.Let_syntax in
    let count, set_count = Bonsai.state 0 graph in
    let%arr count and set_count in
    Apple.button (Int.to_string count) ~on_click:(set_count (count + 1))
  in
  let app =
    Test_app.create ~time_source:(Bonsai.Time_source.create ~start:Time_ns.epoch) component
  in
  Test_app.flush_and_render app;
  let root = Option.value_exn (Test_app.view app) in
  Backend.click_exn root ~path:[];
  [%test_result: string] (Backend.find_text_exn root ~path:[]) ~expect:"1"
;;

let%test_unit "modifier events are scheduled through Bonsai effects" =
  Backend.reset ();
  let scheduled = ref 0 in
  let searchable_changes = ref [] in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.text "Inbox"
       |> Apple.searchable ~text:"bo" ~on_change:(fun text ->
         searchable_changes := text :: !searchable_changes;
         noop)
       |> Apple.toolbar
            [ Apple.toolbar_item ~id:"refresh" ~title:"Refresh" ~on_click:noop ]
       |> Apple.sheet ~is_presented:true ~content:(Apple.text "Details") ~on_dismiss:noop)
  in
  let root = Renderer.view mounted in
  Backend.change_search_exn root ~path:[] ~text:"bonsai";
  Backend.click_toolbar_item_exn root ~path:[] ~id:"refresh";
  Backend.dismiss_sheet_exn root ~path:[];
  [%test_result: int] !scheduled ~expect:3;
  [%test_result: string list] !searchable_changes ~expect:[ "bonsai" ]
;;

let%test_unit "presented sheet content is mounted and diffed by the renderer" =
  Backend.reset ();
  let render label ~is_presented =
    Apple.text "Root"
    |> Apple.sheet ~is_presented ~content:(Apple.text label) ~on_dismiss:noop
  in
  let mounted =
    Renderer.mount ~schedule_event:(fun _ -> ()) (render "Initial sheet" ~is_presented:true)
  in
  require_string_equal
    (show mounted)
    ~expect:
      {|label#1 text=Root modifiers=[sheet]
  sheet:
    label#2 text="Initial sheet"|};
  let before = Backend.stats () in
  Renderer.update mounted (render "Updated sheet" ~is_presented:true);
  let diff = Backend.diff_stats before (Backend.stats ()) in
  [%test_result: int] diff.created ~expect:0;
  [%test_result: int] diff.destroyed ~expect:0;
  require_string_equal
    (show mounted)
    ~expect:
      {|label#1 text=Root modifiers=[sheet]
  sheet:
    label#2 text="Updated sheet"|};
  let before = Backend.stats () in
  Renderer.update mounted (render "Updated sheet" ~is_presented:false);
  let diff = Backend.diff_stats before (Backend.stats ()) in
  [%test_result: int] diff.created ~expect:0;
  [%test_result: int] diff.destroyed ~expect:1
;;
