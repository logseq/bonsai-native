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

let require_string_contains actual substring =
  if not (String.is_substring actual ~substring)
  then raise_s [%sexp "substring missing", { actual : string; substring : string }]
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
    text-field#3 text=milk placeholder=Task style=Rounded_border|}
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
             ~on_submit:noop
             ()
         ])
  in
  let root = Renderer.view mounted in
  Backend.click_exn root ~path:[ 0 ];
  Backend.change_text_exn root ~path:[ 1 ] ~text:"bonsai";
  Backend.submit_text_exn root ~path:[ 1 ];
  [%test_result: int] !scheduled ~expect:3;
  [%test_result: string list] !text_changes ~expect:[ "bonsai" ]
;;

let%test_unit "toggle and secure text-field events are scheduled through Bonsai effects" =
  Backend.reset ();
  let scheduled = ref 0 in
  let toggle_changes = ref [] in
  let text_changes = ref [] in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.vstack
         [ Apple.toggle "Require password" ~is_on:false ~on_change:(fun is_on ->
             toggle_changes := is_on :: !toggle_changes;
             noop)
         ; Apple.text_field
             ~text:""
             ~placeholder:"Password"
             ~is_secure:true
             ~on_change:(fun text ->
               text_changes := text :: !text_changes;
               noop)
             ()
         ])
  in
  let root = Renderer.view mounted in
  require_string_equal
    (Backend.show root)
    ~expect:
      {|stack(vertical)#1
  toggle#3 text="Require password" selected=false
  text-field#2 text="" placeholder=Password style=Rounded_border secure|};
  Backend.change_toggle_exn root ~path:[ 0 ] ~is_on:true;
  Backend.change_text_exn root ~path:[ 1 ] ~text:"secret";
  [%test_result: int] !scheduled ~expect:2;
  [%test_result: bool list] !toggle_changes ~expect:[ true ];
  [%test_result: string list] !text_changes ~expect:[ "secret" ]
;;

let%test_unit "disabled buttons render disabled and do not schedule events" =
  Backend.reset ();
  let scheduled = ref 0 in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.button "Export" ~is_enabled:false ~on_click:noop)
  in
  let root = Renderer.view mounted in
  require_string_equal (Backend.show root) ~expect:{|button#1 text=Export disabled|};
  require_raises_string
    (fun () -> Backend.click_exn root ~path:[])
    ~expect:"View has no click handler";
  [%test_result: int] !scheduled ~expect:0
;;

let%test_unit "file exporter renders export metadata" =
  Backend.reset ();
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (Apple.file_exporter
         ~title:"Export Anki text"
         ~filename:"lulala.txt"
         ~content_type:"public.plain-text"
         ~content:"hello"
         ())
  in
  require_string_equal
    (show mounted)
    ~expect:
      {|file-exporter#1 text="Export Anki text" filename=lulala.txt content_type=public.plain-text|}
;;

let%test_unit "share link renders URL metadata" =
  Backend.reset ();
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (Apple.share_link ~title:"Share URL" ~url:"https://api.test/share/token" ())
  in
  require_string_equal
    (show mounted)
    ~expect:{|share-link#1 text="Share URL" url=https://api.test/share/token|}
;;

let%test_unit "disabled file exporter renders disabled metadata" =
  Backend.reset ();
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (Apple.file_exporter
         ~title:"Export Anki text"
         ~filename:"lulala.txt"
         ~content_type:"public.plain-text"
         ~content:"hello"
         ~is_enabled:false
         ())
  in
  require_string_equal
    (show mounted)
    ~expect:
      {|file-exporter#1 text="Export Anki text" filename=lulala.txt content_type=public.plain-text disabled|}
;;

let%test_unit "file importer forwards selected file content" =
  Backend.reset ();
  let imported = ref None in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (Apple.file_importer
         ~title:"Import Anki file"
         ~allowed_content_types:[ "public.plain-text"; "org.logseq.apkg" ]
         ~on_select:(fun content ->
           imported := Some content;
           noop)
         ())
  in
  let root = Renderer.view mounted in
  require_string_equal
    (Backend.show root)
    ~expect:
      {|file-importer#1 text="Import Anki file" allowed_content_types=[public.plain-text,org.logseq.apkg]|};
  Backend.import_file_exn root ~path:[] ~content:"Front\tBack";
  [%test_result: string option] !imported ~expect:(Some "Front\tBack")
;;

let%test_unit "camera capture forwards captured image ids" =
  Backend.reset ();
  let captured = ref None in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (Apple.camera_capture
         ~title:"Take photo"
         ~on_capture:(fun image_id ->
           captured := Some image_id;
           noop)
         ())
  in
  let root = Renderer.view mounted in
  require_string_equal
    (Backend.show root)
    ~expect:{|camera-capture#1 text="Take photo" captured=()|};
  Backend.capture_camera_exn root ~path:[] ~image_id:"camera://scan";
  [%test_result: string option] !captured ~expect:(Some "camera://scan")
;;

let%test_unit "text supports semantic Apple font attributes" =
  Backend.reset ();
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (Apple.text
         ~style:Apple.Title2
         ~weight:Apple.Semibold
         ~color:Apple.Secondary
         "Good morning")
  in
  require_string_equal
    (show mounted)
    ~expect:
      {|label#1 text="Good morning" text_attributes=((style Title2) (weight Semibold) (color Secondary))|}
;;

let%test_unit "list row renders generic metadata and schedules actions" =
  Backend.reset ();
  let scheduled = ref 0 in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.list_row
         { title = "Reply to client email"
         ; subtitle = Some "12:30 PM"
         ; trailing_text = None
         ; leading_system_image = Some "envelope"
         ; preview_image_path = Some "/tmp/card.png"
         ; content_style = Apple.Standard
         ; accessory = Apple.No_accessory
         ; title_strikethrough = false
         ; on_click = Some noop
         ; leading_button =
             Some
               { system_image = "circle"
               ; selected_system_image = Some "checkmark.circle.fill"
               ; selected = false
               ; accessibility_label = "Mark complete"
               ; on_click = noop
               }
         ; swipe_actions =
             [ { title = "Delete"
               ; system_image = Some "trash"
               ; style = Destructive
               ; on_click = noop
               }
             ]
         ; menu_actions =
             [ { title = "Open"
               ; system_image = Some "arrow.up.right"
               ; style = Default
               ; on_click = noop
               }
             ]
         })
  in
  require_string_equal
    (show mounted)
    ~expect:
      {|list-row#1 title="Reply to client email" subtitle=("12:30 PM") trailing=() style=Standard accessory=No_accessory strikethrough=false leading-image=envelope preview-image=/tmp/card.png leading=circle:false actions=[Delete:destructive] menu=[Open:default]|};
  Backend.click_exn (Renderer.view mounted) ~path:[];
  Backend.click_row_leading_exn (Renderer.view mounted) ~path:[];
  Backend.click_row_action_exn (Renderer.view mounted) ~path:[] ~title:"Delete";
  Backend.click_row_menu_action_exn (Renderer.view mounted) ~path:[] ~title:"Open";
  [%test_result: int] !scheduled ~expect:4
;;

let%test_unit "text editor renders multiline text and schedules changes" =
  Backend.reset ();
  let scheduled = ref 0 in
  let changes = ref [] in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.text_editor
         ~text:"Question\nwith context"
         ~placeholder:"Question"
         ~on_change:(fun text ->
           changes := text :: !changes;
           noop)
         ())
  in
  require_string_equal
    (show mounted)
    ~expect:{|text-editor#1 text= "Question\
\nwith context" placeholder=Question|};
  Backend.change_text_exn (Renderer.view mounted) ~path:[] ~text:"Updated\nquestion";
  [%test_result: int] !scheduled ~expect:1;
  [%test_result: string list] !changes ~expect:[ "Updated\nquestion" ]
;;

let%test_unit "sections and pickers render native list form controls" =
  Backend.reset ();
  let scheduled = ref 0 in
  let selections = ref [] in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.list
         [ Apple.section
             ~key:"Sort"
             ~title:"Sort"
             [ Apple.picker
                 ~title:"Sort decks"
                 ~selected:"due"
                 ~on_select:(fun id ->
                   selections := id :: !selections;
                   noop)
                 [ Apple.picker_option ~id:"default" ~title:"Default"
                 ; Apple.picker_option ~id:"name" ~title:"Name"
                 ; Apple.picker_option ~id:"due" ~title:"Due"
                 ]
             ]
         ; Apple.section
             ~key:"Decks"
             [ Apple.list_row
                 { title = "Biology"
                 ; subtitle = Some "12 cards"
                 ; trailing_text = Some "3 due"
                 ; leading_system_image = None
                 ; preview_image_path = None
                 ; content_style = Apple.Standard
                 ; accessory = Apple.No_accessory
                 ; title_strikethrough = false
                 ; on_click = None
                 ; leading_button = None
                 ; swipe_actions = []
                 ; menu_actions = []
                 }
             ]
         ]
         ~key:(fun section -> Apple.section_key section)
         ~row:Fn.id)
  in
  require_string_equal
    (show mounted)
    ~expect:
      {|list#1
  section#2 key=Sort title=Sort
    picker#3 title="Sort decks" selected=due options=[default:Default,name:Name,due:Due]
  section#4 key=Decks
    list-row#5 title=Biology subtitle=("12 cards") trailing=("3 due") style=Standard accessory=No_accessory strikethrough=false leading-image=none preview-image=none leading=none actions=[] menu=[]|};
  Backend.select_picker_exn (Renderer.view mounted) ~path:[ 0; 0 ] ~id:"name";
  [%test_result: int] !scheduled ~expect:1;
  [%test_result: string list] !selections ~expect:[ "name" ]
;;

let%test_unit "photo picker renders and schedules selected image identifiers" =
  Backend.reset ();
  let scheduled = ref 0 in
  let selections = ref [] in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.photo_picker
         ~title:"Attach image"
         ~selected:"photo://existing"
         ~on_select:(fun image_id ->
           selections := image_id :: !selections;
           noop)
         ())
  in
  require_string_equal
    (show mounted)
    ~expect:{|photo-picker#1 text="Attach image" selected=(photo://existing)|};
  Backend.select_photo_exn (Renderer.view mounted) ~path:[] ~image_id:"photo://new";
  [%test_result: int] !scheduled ~expect:1;
  [%test_result: string list] !selections ~expect:[ "photo://new" ]
;;

let%test_unit "disabled photo picker renders disabled and does not schedule selections" =
  Backend.reset ();
  let scheduled = ref 0 in
  let selections = ref [] in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.photo_picker
         ~title:"Set avatar"
         ~is_enabled:false
         ~on_select:(fun image_id ->
           selections := image_id :: !selections;
           noop)
         ())
  in
  require_string_equal
    (show mounted)
    ~expect:{|photo-picker#1 text="Set avatar" selected=() disabled|};
  (match
     Backend.select_photo_exn
       (Renderer.view mounted)
       ~path:[]
       ~image_id:"photo://avatar"
   with
   | () -> raise_s [%sexp "disabled photo picker should not handle selections"]
   | exception Failure message ->
     require_string_equal message ~expect:"View has no photo-selection handler");
  [%test_result: int] !scheduled ~expect:0;
  [%test_result: string list] !selections ~expect:[]
;;

let%test_unit "photo picker payload decodes local image metadata" =
  Backend.reset ();
  let scheduled = ref 0 in
  let selections = ref [] in
  let payload : Apple.image_payload =
    { id = "image-1"
    ; local_path = "/tmp/image-1.jpg"
    ; mime_type = "image/jpeg"
    ; byte_size = 4
    ; sha256 = "sha256"
    ; width = 800
    ; height = 600
    ; recognized_text =
        Some "Question: 苹果 means what?\nB. apple ✓\n解析: apple 是苹果"
    }
  in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.photo_picker_payload
         ~title:"Import photo"
         ~on_select:(fun payload ->
           selections := payload :: !selections;
           noop)
         ())
  in
  require_string_equal
    (show mounted)
    ~expect:{|photo-picker#1 text="Import photo" selected=() payload|};
  Backend.select_photo_payload_exn (Renderer.view mounted) ~path:[] ~payload;
  [%test_result: int] !scheduled ~expect:1;
  [%test_result: Apple.image_payload list] !selections ~expect:[ payload ]
;;

let%test_unit "camera capture payload decodes local image metadata" =
  Backend.reset ();
  let scheduled = ref 0 in
  let captures = ref [] in
  let payload : Apple.image_payload =
    { id = "image-camera"
    ; local_path = "/tmp/image-camera.jpg"
    ; mime_type = "image/jpeg"
    ; byte_size = 12
    ; sha256 = "camera-sha"
    ; width = 1024
    ; height = 768
    ; recognized_text = Some "Answer: osmosis"
    }
  in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.camera_capture_payload
         ~title:"Take photo"
         ~on_capture:(fun payload ->
           captures := payload :: !captures;
           noop)
         ())
  in
  require_string_equal
    (show mounted)
    ~expect:{|camera-capture#1 text="Take photo" captured=() payload|};
  Backend.capture_camera_payload_exn (Renderer.view mounted) ~path:[] ~payload;
  [%test_result: int] !scheduled ~expect:1;
  [%test_result: Apple.image_payload list] !captures ~expect:[ payload ]
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
  let render rows =
    Apple.list
      rows
      ~key:fst
      ~row:(fun (_, label) ->
        Apple.list_row
          { title = label
          ; subtitle = None
          ; trailing_text = None
          ; leading_system_image = None
          ; preview_image_path = None
          ; content_style = Apple.Standard
          ; accessory = Apple.No_accessory
          ; title_strikethrough = false
          ; on_click = None
          ; leading_button = None
          ; swipe_actions = []
          ; menu_actions = []
          })
  in
  let mounted = Renderer.mount ~schedule_event:(fun _ -> ()) (render (rows 1_000 "row-500")) in
  let before = Backend.stats () in
  Renderer.update mounted (render (rows 1_000 "changed"));
  let diff = Backend.diff_stats before (Backend.stats ()) in
  [%test_result: int] diff.created ~expect:0;
  [%test_result: int] diff.destroyed ~expect:0;
  if diff.mutations >= 20
  then
    raise_s
      [%sexp
        "single keyed row update patched too many native views"
      , { mutations = (diff.mutations : int) }];
  require_string_contains (show mounted) {|title=changed|}
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

let%test_unit "unchanged button views still receive current Bonsai actions" =
  Backend.reset ();
  let component graph =
    let open Bonsai.Let_syntax in
    let count, set_count = Bonsai.state 0 graph in
    let%arr count and set_count in
    Apple.vstack
      [ Apple.text (Int.to_string count)
      ; Apple.button "Add" ~on_click:(set_count (count + 1))
      ]
  in
  let app =
    Test_app.create ~time_source:(Bonsai.Time_source.create ~start:Time_ns.epoch) component
  in
  Test_app.flush_and_render app;
  let root = Option.value_exn (Test_app.view app) in
  Backend.click_exn root ~path:[ 1 ];
  [%test_result: string] (Backend.find_text_exn root ~path:[ 0 ]) ~expect:"1";
  Backend.click_exn root ~path:[ 1 ];
  [%test_result: string] (Backend.find_text_exn root ~path:[ 0 ]) ~expect:"2"
;;

let%test_unit "app wrapper flushes after asynchronous native effects complete" =
  Backend.reset ();
  let complete = ref None in
  let component graph =
    let open Bonsai.Let_syntax in
    let count, set_count = Bonsai.state 0 graph in
    let%arr count and set_count in
    let async_increment =
      Bonsai.Effect.bind
        (Bonsai.Effect.Expert.of_fun ~f:(fun ~callback ~on_exn:_ ->
           complete := Some (fun () -> callback ())))
        ~f:(fun () -> set_count (count + 1))
    in
    Apple.button (Int.to_string count) ~on_click:async_increment
  in
  let app =
    Test_app.create ~time_source:(Bonsai.Time_source.create ~start:Time_ns.epoch) component
  in
  Test_app.flush_and_render app;
  let root = Option.value_exn (Test_app.view app) in
  Backend.click_exn root ~path:[];
  [%test_result: string] (Backend.find_text_exn root ~path:[]) ~expect:"0";
  (Option.value_exn !complete) ();
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
            [ Apple.toolbar_item
                ~id:"refresh"
                ~title:"Refresh"
                ~system_image:"arrow.clockwise"
                ~menu_actions:
                  [ { title = "Reload from server"
                    ; system_image = Some "icloud.and.arrow.down"
                    ; style = Apple.Default
                    ; on_click = noop
                    ; file_export = None
                    }
                  ]
                ~on_click:noop
                ()
            ]
       |> Apple.sheet ~is_presented:true ~content:(Apple.text "Details") ~on_dismiss:noop)
  in
  let root = Renderer.view mounted in
  Backend.change_search_exn root ~path:[] ~text:"bonsai";
  Backend.click_toolbar_item_exn root ~path:[] ~id:"refresh";
  Backend.click_toolbar_menu_action_exn
    root
    ~path:[]
    ~id:"refresh"
    ~title:"Reload from server";
  Backend.dismiss_sheet_exn root ~path:[];
  [%test_result: int] !scheduled ~expect:4;
  [%test_result: string list] !searchable_changes ~expect:[ "bonsai" ]
;;

let%test_unit "disabled toolbar items render disabled and do not schedule events" =
  Backend.reset ();
  let scheduled = ref 0 in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.text "Share"
       |> Apple.toolbar
            [ Apple.toolbar_item
                ~id:"create"
                ~title:"Create"
                ~is_enabled:false
                ~on_click:noop
                ()
            ])
  in
  let root = Renderer.view mounted in
  require_string_contains (Backend.show root) {|toolbar=[create:Create:disabled]|};
  require_raises_string
    (fun () -> Backend.click_toolbar_item_exn root ~path:[] ~id:"create")
    ~expect:"Toolbar item \"create\" is disabled";
  [%test_result: int] !scheduled ~expect:0
;;

let%test_unit "navigation title modifier renders in the testing backend" =
  Backend.reset ();
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (Apple.navigation_stack [ Apple.text "Body" ] |> Apple.navigation_title "Share")
  in
  require_string_contains (show mounted) {|navigation-title=Share|}
;;

let%test_unit "toolbar menu file export is visible to the testing backend" =
  Backend.reset ();
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (Apple.text "Deck"
       |> Apple.toolbar
            [ Apple.toolbar_item
                ~id:"share"
                ~title:"Share"
                ~system_image:"square.and.arrow.up"
                ~menu_actions:
                  [ { title = "Anki text"
                    ; system_image = Some "doc.plaintext"
                    ; style = Apple.Default
                    ; on_click = noop
                    ; file_export =
                        Some
                          { filename = "Biology.txt"
                          ; content_type = "public.plain-text"
                          ; content = "Biology\tQuestion\tAnswer"
                          }
                    }
                  ]
                ~on_click:noop
                ()
            ])
  in
  let root = Renderer.view mounted in
  Backend.click_toolbar_menu_action_exn root ~path:[] ~id:"share" ~title:"Anki text";
  let rendered = Backend.show root in
  require_string_contains rendered {|filename=Biology.txt content_type=public.plain-text|}
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

let%test_unit "testing backend can interact with presented sheet content" =
  Backend.reset ();
  let saved = ref None in
  let component graph =
    let open Bonsai.Let_syntax in
    let value, set_value = Bonsai.state "" graph in
    let%arr value and set_value in
    Apple.text "Root"
    |> Apple.sheet
         ~is_presented:true
         ~content:
           (Apple.vstack
              [ Apple.text_field ~text:value ~placeholder:"Name" ~on_change:set_value ()
              ; Apple.button
                  "Save"
                  ~on_click:(Bonsai.Effect.of_thunk (fun () -> saved := Some value))
              ])
  in
  let app =
    Test_app.create
      ~time_source:(Bonsai.Time_source.create ~start:Time_ns.epoch)
      component
  in
  Test_app.flush_and_render app;
  let view = Option.value_exn (Test_app.view app) in
  Backend.change_sheet_text_exn view ~path:[] ~sheet_path:[ 0 ] ~text:"Edited";
  Backend.click_sheet_exn view ~path:[] ~sheet_path:[ 1 ];
  [%test_result: string option] !saved ~expect:(Some "Edited");
  require_string_contains (Backend.show view) {|text=Edited placeholder=Name|}
;;

let%test_unit "testing backend can change sheet text on an unselected sidebar route" =
  Backend.reset ();
  let saved = ref None in
  let component graph =
    let open Bonsai.Let_syntax in
    let is_renaming, set_is_renaming = Bonsai.state false graph in
    let saved_description, set_saved_description = Bonsai.state "Cell study" graph in
    let name, set_name = Bonsai.state "" graph in
    let draft_description, set_draft_description = Bonsai.state "Cell study" graph in
    let%arr is_renaming
    and set_is_renaming
    and saved_description
    and set_saved_description
    and name
    and set_name
    and draft_description
    and set_draft_description in
    let decks_route =
      Apple.navigation_stack
        [ Apple.list
            [ Apple.list_row
                { title = "Biology"
                ; subtitle = None
                ; trailing_text = None
                ; leading_system_image = None
                ; preview_image_path = None
                ; content_style = Apple.Standard
                ; accessory = Apple.No_accessory
                ; title_strikethrough = false
                ; on_click = None
                ; leading_button = None
                ; swipe_actions =
                    [ { title = "Rename"
                      ; system_image = None
                      ; style = Apple.Default
                      ; on_click =
                          Bonsai.Effect.Many
                            [ set_is_renaming true
                            ; set_name "Biology"
                            ; set_draft_description saved_description
                            ]
                      }
                    ]
                ; menu_actions = []
                }
            ]
            ~key:(fun _ -> "bio")
            ~row:Fn.id
        ]
      |> Apple.sheet
           ~is_presented:is_renaming
           ~content:
             (Apple.vstack
                [ Apple.text "Rename deck"
                ; Apple.text_field ~text:name ~placeholder:"Deck name" ~on_change:set_name ()
                ; Apple.text_field
                    ~text:draft_description
                    ~placeholder:"Description"
                    ~on_change:set_draft_description
                    ()
                ; Apple.hstack
                    [ Apple.button "Cancel" ~on_click:noop
                    ; Apple.button
                        "Save"
                        ~on_click:
                          (Bonsai.Effect.Many
                             [ set_saved_description draft_description
                             ; set_is_renaming false
                             ; Bonsai.Effect.of_thunk (fun () ->
                                 saved := Some draft_description)
                             ])
                    ]
                ])
    in
    Apple.sidebar_split
      ~selected:"chat"
      ~on_select:(fun _ -> noop)
      [ Apple.tab ~id:"decks" ~title:"Decks" decks_route
      ; Apple.tab ~id:"chat" ~title:"Chat" (Apple.text "Chat")
      ]
  in
  let app =
    Test_app.create
      ~time_source:(Bonsai.Time_source.create ~start:Time_ns.epoch)
      component
  in
  Test_app.flush_and_render app;
  let view = Option.value_exn (Test_app.view app) in
  Backend.click_row_action_exn view ~path:[ 0; 0; 0 ] ~title:"Rename";
  Backend.change_sheet_text_exn view ~path:[ 0 ] ~sheet_path:[ 2 ] ~text:"Exam notes";
  require_string_contains (Backend.show view) {|text="Exam notes" placeholder=Description|};
  Backend.click_sheet_exn view ~path:[ 0 ] ~sheet_path:[ 3; 1 ];
  [%test_result: string option] !saved ~expect:(Some "Exam notes");
  Backend.click_row_action_exn view ~path:[ 0; 0; 0 ] ~title:"Rename";
  require_string_contains (Backend.show view) {|text="Exam notes" placeholder=Description|}
;;

let%test_unit "tab view renders tab metadata and selected content" =
  Backend.reset ();
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (Apple.tab_view
         ~selected:"today"
         ~on_select:(fun _ -> noop)
         [ Apple.tab
             ~id:"today"
             ~title:"Today"
             ~system_image:"sun.max"
             (Apple.text "Today tasks")
         ; Apple.tab
             ~id:"search"
             ~title:"Search"
             ~system_image:"magnifyingglass"
             ~role:Apple.Search
             (Apple.text "Search tasks")
         ])
  in
  require_string_equal
    (show mounted)
    ~expect:
      {|tab-view#1 selected=today tabs=[today:Today:sun.max,search:Search:magnifyingglass:search]
  label#2 key=today text="Today tasks"
  label#3 key=search text="Search tasks"|}
;;

let%test_unit "adaptive layout renders compact and regular branches" =
  Backend.reset ();
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (Apple.adaptive_layout
         ~compact:(Apple.text "Phone tabs")
         ~regular:(Apple.text "Three columns"))
  in
  require_string_equal
    (show mounted)
    ~expect:
      {|adaptive-layout#1
  label#3 text="Phone tabs"
  label#2 text="Three columns"|}
;;

let%test_unit "keyed children preserve modifiers on initial mount" =
  Backend.reset ();
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (Apple.tab_view
         ~selected:"search"
         ~on_select:(fun _ -> noop)
         [ Apple.tab
             ~id:"search"
             ~title:"Search"
             ~role:Apple.Search
             (Apple.text "Search"
              |> Apple.searchable ~text:"" ~on_change:(fun _ -> noop))
         ])
  in
  require_string_equal
    (show mounted)
    ~expect:
      {|tab-view#1 selected=search tabs=[search:Search:search]
  label#2 key=search text=Search modifiers=[searchable]|}
;;

let%test_unit "tab selection is scheduled through Bonsai effects" =
  Backend.reset ();
  let scheduled = ref 0 in
  let selected = ref [] in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.tab_view
         ~selected:"today"
         ~on_select:(fun id ->
           selected := id :: !selected;
           noop)
         [ Apple.tab ~id:"today" ~title:"Today" (Apple.text "Today")
         ; Apple.tab ~id:"upcoming" ~title:"Upcoming" (Apple.text "Upcoming")
         ])
  in
  Backend.select_tab_exn (Renderer.view mounted) ~id:"upcoming";
  [%test_result: int] !scheduled ~expect:1;
  [%test_result: string list] !selected ~expect:[ "upcoming" ]
;;

let%test_unit "tab view reuses keyed tabs across reorder and text updates" =
  Backend.reset ();
  let render tabs =
    Apple.tab_view
      ~selected:"upcoming"
      ~on_select:(fun _ -> noop)
      (List.map tabs ~f:(fun (id, title, label) ->
         Apple.tab ~id ~title (Apple.text label)))
  in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (render
         [ "today", "Today", "Today tasks"
         ; "upcoming", "Upcoming", "Upcoming tasks"
         ; "search", "Search", "Search tasks"
         ])
  in
  let before = Backend.stats () in
  Renderer.update
    mounted
    (render
       [ "search", "Search", "Search tasks"
       ; "upcoming", "Upcoming", "Updated upcoming"
       ; "completed", "Completed", "Completed tasks"
       ]);
  require_string_equal
    (show mounted)
    ~expect:
      {|tab-view#1 selected=upcoming tabs=[search:Search,upcoming:Upcoming,completed:Completed]
  label#4 key=search text="Search tasks"
  label#3 key=upcoming text="Updated upcoming"
  label#5 key=completed text="Completed tasks"|}
  ;
  let diff = Backend.diff_stats before (Backend.stats ()) in
  [%test_result: int] diff.created ~expect:1;
  [%test_result: int] diff.destroyed ~expect:1
;;

let%test_unit "tab view rejects duplicate tab ids before mounting" =
  require_raises_string
    (fun () ->
      ignore
        (Apple.tab_view
           ~selected:"today"
           ~on_select:(fun _ -> noop)
           [ Apple.tab ~id:"today" ~title:"Today" (Apple.text "Today")
           ; Apple.tab ~id:"today" ~title:"Again" (Apple.text "Again")
           ]
         : Apple.node))
    ~expect:"duplicate Bonsai Apple tab id: today"
;;

let%test_unit "sidebar split renders route metadata and schedules selection" =
  Backend.reset ();
  let scheduled = ref 0 in
  let selected = ref [] in
  let search_changes = ref [] in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> Int.incr scheduled)
      (Apple.sidebar_split
         ~header_action:
           (Apple.sidebar_action
              ~id:"account"
              ~title:"Account"
              ~system_image:"person.crop.circle"
              ~on_click:(Bonsai.Effect.of_thunk (fun () -> ()))
              ())
         ~actions:
           [ Apple.sidebar_action
               ~id:"practice-cards"
               ~title:"Practice"
              ~system_image:"rectangle.stack.badge.play"
              ~on_click:noop
              ()
           ]
         ~bottom_search_placeholder:"Search"
         ~bottom_search_text:""
         ~bottom_search_on_change:(fun text ->
           search_changes := text :: !search_changes;
           noop)
         ~bottom_action:
           (Apple.sidebar_action
              ~id:"new-chat"
              ~title:"Chat"
              ~system_image:"square.and.pencil"
              ~on_click:noop
              ())
         ~selected:"chat"
         ~on_select:(fun id ->
           selected := id :: !selected;
           noop)
         [ Apple.tab
             ~id:"chat"
             ~title:"Chat"
             ~system_image:"bubble.left.and.bubble.right"
             (Apple.text "Chat detail")
         ; Apple.tab
             ~id:"decks"
             ~title:"Decks"
             ~system_image:"rectangle.stack"
             (Apple.text "Deck detail")
         ])
  in
  require_string_equal
    (show mounted)
    ~expect:
      {|sidebar-split#1 selected=chat routes=[chat:Chat:bubble.left.and.bubble.right,decks:Decks:rectangle.stack] sidebar-header-action=account:Account:person.crop.circle sidebar-actions=[practice-cards:Practice:rectangle.stack.badge.play] sidebar-bottom-search=Search text= sidebar-bottom-action=new-chat:Chat:square.and.pencil
  label#2 key=chat text="Chat detail"
  label#3 key=decks text="Deck detail"|};
  Backend.change_sidebar_bottom_search_exn (Renderer.view mounted) ~text:"math";
  [%test_result: int] !scheduled ~expect:1;
  [%test_result: string list] !search_changes ~expect:[ "math" ];
  require_string_contains (show mounted) {|sidebar-bottom-search=Search text=math|};
  Backend.click_sidebar_header_action_exn (Renderer.view mounted) ~id:"account";
  [%test_result: int] !scheduled ~expect:2;
  Backend.click_sidebar_action_exn (Renderer.view mounted) ~id:"practice-cards";
  [%test_result: int] !scheduled ~expect:3;
  Backend.click_sidebar_bottom_action_exn (Renderer.view mounted) ~id:"new-chat";
  [%test_result: int] !scheduled ~expect:4;
  Backend.select_sidebar_route_exn (Renderer.view mounted) ~id:"decks";
  [%test_result: int] !scheduled ~expect:5;
  [%test_result: string list] !selected ~expect:[ "decks" ]
;;

let%test_unit "sidebar split reuses keyed routes across reorder and text updates" =
  Backend.reset ();
  let render routes =
    Apple.sidebar_split
      ~selected:"decks"
      ~on_select:(fun _ -> noop)
      (List.map routes ~f:(fun (id, title, label) ->
         Apple.tab ~id ~title (Apple.text label)))
  in
  let mounted =
    Renderer.mount
      ~schedule_event:(fun _ -> ())
      (render
         [ "chat", "Chat", "Chat detail"
         ; "decks", "Decks", "Deck detail"
         ; "settings", "Settings", "Settings detail"
         ])
  in
  let before = Backend.stats () in
  Renderer.update
    mounted
    (render
       [ "settings", "Settings", "Settings detail"
       ; "decks", "Decks", "Updated deck detail"
       ; "practice", "Practice", "Practice detail"
       ]);
  require_string_equal
    (show mounted)
    ~expect:
      {|sidebar-split#1 selected=decks routes=[settings:Settings,decks:Decks,practice:Practice]
  label#4 key=settings text="Settings detail"
  label#3 key=decks text="Updated deck detail"
  label#5 key=practice text="Practice detail"|};
  let diff = Backend.diff_stats before (Backend.stats ()) in
  [%test_result: int] diff.created ~expect:1;
  [%test_result: int] diff.destroyed ~expect:1
;;

let%test_unit "sidebar split rejects duplicate route ids before mounting" =
  require_raises_string
    (fun () ->
      ignore
        (Apple.sidebar_split
           ~selected:"chat"
           ~on_select:(fun _ -> noop)
           [ Apple.tab ~id:"chat" ~title:"Chat" (Apple.text "Chat")
           ; Apple.tab ~id:"chat" ~title:"Again" (Apple.text "Again")
           ]
         : Apple.node))
    ~expect:"duplicate Bonsai Apple sidebar route id: chat"
;;
