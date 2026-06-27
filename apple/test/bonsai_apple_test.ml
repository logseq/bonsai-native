module Apple = Bonsai_apple
module Backend = Apple.For_testing.Backend
module App = Apple.App.Make (Backend)

let require condition message = if not condition then failwith message

let contains text ~substring =
  let text_length = String.length text in
  let substring_length = String.length substring in
  let rec loop index =
    if index + substring_length > text_length
    then false
    else if String.sub text index substring_length = substring
    then true
    else loop (index + 1)
  in
  substring_length = 0 || loop 0
;;

let count_substrings text ~substring =
  let text_length = String.length text in
  let substring_length = String.length substring in
  let rec loop index count =
    if substring_length = 0 || index + substring_length > text_length
    then count
    else if String.sub text index substring_length = substring
    then loop (index + substring_length) (count + 1)
    else loop (index + 1) count
  in
  loop 0 0
;;

let read_file path =
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () ->
       let length = in_channel_length channel in
       really_input_string channel length)
;;

let swiftui_source_path = "../swiftui/BonsaiNativeSwiftUI.swift"

let test_compact_sidebar_close_paths_share_swift_animation () =
  let source = read_file swiftui_source_path in
  let expected_direct_close_paths = 3 in
  require
    (count_substrings source ~substring:"setCompactSidebarOpen(false)"
     >= expected_direct_close_paths)
    "compact sidebar overlay and drag close paths should go through \
     setCompactSidebarOpen(false) for the Swift drawer animation, keyboard dismissal, \
     haptic, and drag-state reset";
  require
    (count_substrings source ~substring:"closeCompactSidebarIfNeeded(action)" >= 4)
    "compact sidebar action close paths should share the data-driven close helper";
  require
    (count_substrings source ~substring:"isCompactSidebarOpen = false" = 1)
    "compact sidebar close paths should not mutate isCompactSidebarOpen directly \
     outside its @State initial value"
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
    App.create (fun graph -> Apple.vstack [ scoped "a" graph; scoped "b" graph ])
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

let test_sidebar_history_actions_are_separate_and_clickable () =
  Backend.reset ();
  let component graph =
    let selected, set_selected = Apple.state graph ~key:"selected" "chat" in
    let event, set_event = Apple.state graph ~key:"event" "none" in
    Apple.sidebar_split
      ~title:"Lulala"
      ~actions:
        [ Apple.sidebar_action
            ~id:"inbox"
            ~title:"Inbox"
            ~system_image:"tray"
            ~on_click:(set_event "inbox")
            ()
        ]
      ~history_title:"Recent"
      ~history_actions:
        [ Apple.sidebar_action
            ~id:"conversation-1"
            ~title:"Find DNA cards"
            ~subtitle:"You: Find DNA cards"
            ~on_click:(set_event "conversation")
            ~menu_actions:
              [ { title = "Rename"
                ; system_image = Some "pencil"
                ; style = Apple.Default
                ; on_click = set_event "rename"
                }
              ]
            ()
        ]
      ~selected
      ~on_select:set_selected
      [ Apple.tab ~id:"chat" ~title:"Chat" (Apple.text event) ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"sidebar-actions=[inbox:Inbox:tray]")
    "primary sidebar action should render separately";
  require
    (contains rendered ~substring:"sidebar-history-title=Recent")
    "history title should render";
  require
    (contains
       rendered
       ~substring:
         "sidebar-history-actions=[conversation-1:Find DNA cards:preview=You: Find DNA \
          cards:menu=[Rename:pencil:default]]")
    "history action should render separately";
  require
    (contains rendered ~substring:"sidebar-history-menu-presentation=context-menu")
    "history actions should use Swift-style context menus instead of replacing the row \
     button";
  Backend.click_sidebar_history_action_exn root ~id:"conversation-1";
  require
    (Backend.find_text_exn root ~path:[ 0 ] = "conversation")
    "history action click should run";
  Backend.click_sidebar_history_action_menu_action_exn
    root
    ~id:"conversation-1"
    ~title:"Rename";
  require
    (Backend.find_text_exn root ~path:[ 0 ] = "rename")
    "history action menu click should run"
;;

let test_sidebar_actions_can_keep_compact_drawer_open () =
  Backend.reset ();
  let component graph =
    let selected, set_selected = Apple.state graph ~key:"selected" "decks" in
    let event, set_event = Apple.state graph ~key:"event" "none" in
    Apple.sidebar_split
      ~title:"Lulala"
      ~header_action:
        (Apple.sidebar_action
           ~id:"account"
           ~title:"Account"
           ~avatar_initial:"?"
           ~closes_sidebar:false
           ~on_click:(set_event "settings")
           ())
      ~actions:
        [ Apple.sidebar_action
            ~id:"decks"
            ~title:"Decks"
            ~system_image:"rectangle.stack"
            ~on_click:(set_event "decks")
            ()
        ; Apple.sidebar_action
            ~id:"practice-cards"
            ~title:"Practice"
            ~system_image:"rectangle.stack.badge.play"
            ~closes_sidebar:false
            ~on_click:(set_event "practice")
            ()
        ]
      ~selected
      ~on_select:set_selected
      [ Apple.tab ~id:"decks" ~title:"Decks" (Apple.text event) ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"sidebar-header-action=account:Account:avatar=?:keeps-sidebar")
    "header action should expose that it keeps the compact sidebar open";
  require
    (contains
       rendered
       ~substring:"practice-cards:Practice:rectangle.stack.badge.play:keeps-sidebar")
    "sheet-style sidebar actions should expose that they keep the compact sidebar open";
  Backend.click_sidebar_header_action_exn root ~id:"account";
  require
    (String.equal (Backend.find_text_exn root ~path:[ 0 ]) "settings")
    "header action click should still run";
  Backend.click_sidebar_action_exn root ~id:"practice-cards";
  require
    (String.equal (Backend.find_text_exn root ~path:[ 0 ]) "practice")
    "non-closing sidebar action click should still run"
;;

let test_compact_sidebar_top_bar_uses_system_toolbar_item_chrome () =
  Backend.reset ();
  let component graph =
    let selected, set_selected = Apple.state graph ~key:"selected" "decks" in
    Apple.sidebar_split
      ~title:"Lulala"
      ~selected
      ~on_select:set_selected
      [ Apple.tab ~id:"decks" ~title:"Decks" (Apple.text "Decks") ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains
       rendered
       ~substring:
         "compact-top-bar=system-toolbar toolbaritem-leading=sidebar-toggle \
          toolbaritem-title=navigation-title")
    "compact top bar should use system toolbar items like the Swift header";
  require
    (contains rendered ~substring:"toolbaritem-leading-chrome=liquid-glass")
    "compact sidebar leading toolbar item should use the same liquid glass chrome as \
     Swift";
  require
    (contains
       rendered
       ~substring:
         "sidebar-safe-area-padding=swift top=max-safe-area-plus-5-or-54 \
          bottom=max-safe-area-or-34")
    "compact sidebar should use the same safe-area padding as the Swift drawer";
  require
    (contains
       rendered
       ~substring:"sidebar-bottom-controls=safe-area-inset top-padding=10")
    "compact sidebar bottom controls should match the Swift safe-area inset layout";
  require
    (contains
       rendered
       ~substring:
         "sidebar-scroll-disabled=dragging content-scroll-disabled=open-or-dragging")
    "compact sidebar should disable scroll during the same drawer states as Swift";
  require
    (contains
       rendered
       ~substring:"sidebar-edge-gesture=enabled-when-compact-top-bar-visible")
    "compact sidebar edge gesture should follow the same route gating as Swift";
  require
    (contains
       rendered
       ~substring:
         "sidebar-open-close=swift-interactive-spring keyboard-dismiss haptic-on-change")
    "compact sidebar should use the same open and close interaction behavior as Swift"
;;

let test_image_semantic_color_renders () =
  Backend.reset ();
  let component _graph =
    Apple.hstack
      [ Apple.image ~color:Apple.Green "checkmark.circle.fill"
      ; Apple.image ~color:Apple.Red "xmark.circle.fill"
      ; Apple.image "circle"
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"text=\"checkmark.circle.fill\" image-color=green")
    "green image color should render";
  require
    (contains rendered ~substring:"text=\"xmark.circle.fill\" image-color=red")
    "red image color should render";
  require
    (not (contains rendered ~substring:"text=\"circle\" image-color="))
    "default image color should not render"
;;

let test_button_label_renders_custom_clickable_content () =
  Backend.reset ();
  let component graph =
    let selected, set_selected = Apple.state graph ~key:"selected" false in
    Apple.button_label
      ~is_enabled:(not selected)
      ~on_click:(set_selected true)
      (Apple.hstack
         ~spacing:10.
         [ Apple.image ~color:Apple.Green "checkmark.circle.fill"
         ; Apple.text "DNA"
         ; Apple.spacer ()
         ])
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"button#")
    "custom label button should render as a button";
  require
    (contains rendered ~substring:"stack(horizontal)")
    "custom label button should keep its horizontal label content";
  require
    (contains rendered ~substring:"text=\"checkmark.circle.fill\" image-color=green")
    "custom label button should render its image child";
  Backend.click_exn root ~path:[];
  require
    (contains (Backend.show root) ~substring:"button#")
    "button should remain mounted after click";
  require
    (contains (Backend.show root) ~substring:" disabled")
    "click should run the button action"
;;

let test_button_renders_bordered_prominent_style () =
  Backend.reset ();
  let component _graph =
    Apple.button
      ~style:Apple.Bordered_prominent
      ~system_image:"eye"
      "Reveal answer"
      ~on_click:Apple.Action.ignore
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains
       (Backend.show root)
       ~substring:"text=\"Reveal answer\" image=eye button-style=bordered-prominent")
    "bordered prominent button style should be visible to native renderers"
;;

let test_button_renders_plain_style () =
  Backend.reset ();
  let component _graph =
    Apple.button
      ~style:Apple.Plain
      ~system_image:"arrow.up"
      ~is_title_visible:false
      "Send"
      ~on_click:Apple.Action.ignore
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains
       (Backend.show root)
       ~substring:"text=\"Send\" image=arrow.up button-style=plain title-hidden")
    "plain button style should be visible to native renderers"
;;

let test_on_appear_event_rerenders_component_state () =
  Backend.reset ();
  let component graph =
    let count, set_count = Apple.state graph ~key:"count" 0 in
    Apple.vstack
      [ Apple.text (string_of_int count)
      ; Apple.text "sentinel" |> Apple.on_appear ~on_appear:(set_count (count + 1))
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require (Backend.find_text_exn root ~path:[ 0 ] = "0") "initial count should be 0";
  Backend.appear_exn root ~path:[ 1 ];
  require (Backend.find_text_exn root ~path:[ 0 ] = "1") "appear should rerender count"
;;

let test_searchable_renders_prompt () =
  Backend.reset ();
  let component _graph =
    Apple.navigation_stack
      [ Apple.text "Cards"
        |> Apple.searchable ~text:"" ~prompt:"Search cards" ~on_change:(fun _ ->
          Apple.Action.ignore)
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains (Backend.show root) ~substring:"searchable-prompt=\"Search cards\"")
    "searchable prompt should be visible to native renderers"
;;

let test_picker_renders_segmented_style () =
  Backend.reset ();
  let component _graph =
    Apple.picker
      ~style:Apple.Segmented
      ~title:"Card type"
      ~selected:"basic"
      ~on_select:(fun _ -> Apple.Action.ignore)
      [ Apple.picker_option ~id:"basic" ~title:"Basic"
      ; Apple.picker_option ~id:"single" ~title:"Single"
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains (Backend.show root) ~substring:"picker-style=segmented")
    "segmented picker style should be visible to native renderers"
;;

let test_liquid_glass_panel_renders () =
  Backend.reset ();
  let component _graph =
    Apple.text "Review"
    |> Apple.liquid_glass_panel
         ~corner_radius:22.
         ~is_transparent:true
         ~tint_color:Apple.Green
         ~tint_opacity:0.1
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains
       rendered
       ~substring:"panel=liquid-glass corner-radius=22 transparent=true tint=green:0.1")
    "liquid glass panel should be visible to native renderers"
;;

let test_pill_text_field_uses_liquid_glass_chrome () =
  Backend.reset ();
  let component _graph =
    Apple.text_field
      ~style:Apple.Pill
      ~text:""
      ~placeholder:"New deck"
      ~on_change:(fun _ -> Apple.Action.ignore)
      ()
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains
       rendered
       ~substring:
         "placeholder=\"New deck\" style=pill chrome=liquid-glass corner-radius=26")
    "pill text fields should render with Swift-style liquid glass chrome"
;;

let test_plain_text_field_renders_plain_style () =
  Backend.reset ();
  let component _graph =
    Apple.text_field
      ~style:Apple.Plain_text
      ~text:""
      ~placeholder:"Search"
      ~on_change:(fun _ -> Apple.Action.ignore)
      ()
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"placeholder=\"Search\" style=plain")
    "plain text fields should expose SwiftUI plain text field style"
;;

let test_file_image_can_render_swift_card_image_style () =
  Backend.reset ();
  let component _graph =
    Apple.image_file ~max_height:180. ~corner_radius:8. "/tmp/card.png"
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"source=file")
    "file images should render from the filesystem";
  require
    (contains rendered ~substring:"image-style=max-height:\"180\":corner-radius:\"8\"")
    "file images should expose Swift CardImageView sizing and clipping"
;;

let test_keyboard_dismiss_controls_renders () =
  Backend.reset ();
  let component _graph =
    Apple.form
      [ Apple.section
          ~key:"Fields"
          [ Apple.text_field ~text:"" ~on_change:(fun _ -> Apple.Action.ignore) () ]
      ]
    |> Apple.keyboard_dismiss_controls
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains (Backend.show root) ~substring:"modifiers=[keyboard-dismiss-controls]")
    "keyboard dismiss controls should be visible to native renderers"
;;

let test_scroll_dismisses_keyboard_renders () =
  Backend.reset ();
  let component _graph =
    Apple.scroll_view (Apple.text "Transcript") |> Apple.scroll_dismisses_keyboard
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"modifiers=[scroll-dismisses-keyboard]")
    "scroll-only keyboard dismissal should render without keyboard toolbar controls";
  require
    (not (contains rendered ~substring:"keyboard-dismiss-controls"))
    "scroll-only keyboard dismissal should not add keyboard toolbar controls"
;;

let test_secondary_fill_panel_renders () =
  Backend.reset ();
  let component _graph =
    Apple.text "You: Hello" |> Apple.secondary_fill_panel ~corner_radius:18. ~opacity:0.12
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"panel=secondary-fill corner-radius=18 opacity=0.12")
    "secondary fill panel should expose Swift user message bubble chrome"
;;

let test_context_menu_renders_and_clicks_actions () =
  Backend.reset ();
  let copied = ref false in
  let component _graph =
    Apple.text "Message"
    |> Apple.context_menu
         [ { title = "Copy"
           ; system_image = Some "doc.on.doc"
           ; style = Apple.Default
           ; on_click = Apple.Action.of_thunk (fun () -> copied := true)
           }
         ; { title = "Delete"
           ; system_image = Some "trash"
           ; style = Apple.Destructive
           ; on_click = Apple.Action.ignore
           }
         ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains
       rendered
       ~substring:"context-menu=[Copy:doc.on.doc:default,Delete:trash:destructive]")
    "context menus should expose SwiftUI message actions";
  Backend.click_context_menu_action_exn root ~path:[] ~title:"Copy";
  require !copied "context menu actions should be clickable"
;;

let test_copy_text_to_clipboard_action_updates_test_clipboard () =
  Backend.reset ();
  Apple.copy_text_to_clipboard "Copied text" ();
  require
    (Backend.clipboard_text () = Some "Copied text")
    "copy text action should update the backend clipboard"
;;

let test_copy_image_file_to_clipboard_action_updates_test_clipboard () =
  Backend.reset ();
  Apple.copy_image_file_to_clipboard "/tmp/photo.png" ();
  require
    (Backend.clipboard_image_file () = Some "/tmp/photo.png")
    "copy image file action should update the backend clipboard image file"
;;

let test_toggle_audio_file_playback_action_updates_test_playback_state () =
  Backend.reset ();
  Apple.toggle_audio_file_playback "/tmp/recording.m4a" ();
  require
    (Backend.playing_audio_file () = Some "/tmp/recording.m4a")
    "toggle audio action should start playback for the file";
  Apple.toggle_audio_file_playback "/tmp/recording.m4a" ();
  require
    (Option.is_none (Backend.playing_audio_file ()))
    "toggle audio action should pause the currently playing file";
  Apple.toggle_audio_file_playback "/tmp/other.m4a" ();
  require
    (Backend.playing_audio_file () = Some "/tmp/other.m4a")
    "toggle audio action should switch to a different file"
;;

let test_audio_recording_actions_update_testing_backend () =
  Backend.reset ();
  require
    (not (Backend.is_audio_recording ()))
    "audio recorder should start idle in the testing backend";
  Apple.start_audio_recording ();
  require (Backend.is_audio_recording ()) "start recording action should mark recording";
  let result = Apple.stop_audio_recording_and_transcribe () in
  require
    (not (Backend.is_audio_recording ()))
    "stop recording action should return the testing backend to idle";
  require
    (String.equal result.transcript "Voice note")
    "stop recording should return the transcript";
  require
    (String.equal result.local_path "/tmp/voice-note.m4a")
    "stop recording should return the audio file path";
  require
    (String.equal result.filename "voice-note.m4a")
    "stop recording should return the audio filename";
  require
    (String.equal result.content_type "audio/mp4")
    "stop recording should return the audio content type";
  require (result.byte_size = 42) "stop recording should return the byte size"
;;

let test_toolbar_item_can_render_share_link () =
  Backend.reset ();
  let component _graph =
    Apple.text "Preview"
    |> Apple.toolbar
         [ Apple.toolbar_item
             ~id:"share"
             ~title:"Share"
             ~system_image:"square.and.arrow.up"
             ~is_title_visible:false
             ~share_url:"file:///tmp/photo.png"
             ~on_click:Apple.Action.ignore
             ()
         ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains
       (Backend.show root)
       ~substring:
         "toolbar=[share:Share:enabled:image=square.and.arrow.up:title-hidden:share-url=file:///tmp/photo.png]")
    "toolbar share items should expose the ShareLink URL";
  require
    (contains (Backend.show root) ~substring:"toolbar-presentation=system-toolbaritem")
    "toolbar actions should render through system ToolbarItem chrome";
  require
    (contains (Backend.show root) ~substring:"toolbaritem-chrome=system-default")
    "toolbar actions should keep the system ToolbarItem button chrome"
;;

let test_movable_rows_move_only_the_group_children () =
  Backend.reset ();
  let filteri list ~f =
    let rec loop index = function
      | [] -> []
      | value :: rest ->
        if f index value then value :: loop (index + 1) rest else loop (index + 1) rest
    in
    loop 0 list
  in
  let split_at index list =
    let rec loop remaining prefix rest =
      if remaining <= 0
      then List.rev prefix, rest
      else (
        match rest with
        | [] -> List.rev prefix, []
        | value :: tail -> loop (remaining - 1) (value :: prefix) tail)
    in
    loop index [] list
  in
  let choice_rows choices =
    match choices with
    | _question :: first :: second :: _hint :: _ -> [ first; second ]
    | _ -> []
  in
  let component graph =
    let choices, set_choices =
      Apple.state graph ~key:"choices" [ "Question"; "RNA"; "DNA"; "Hint" ]
    in
    let move_choice ~from_index ~to_index =
      match choices with
      | question :: first :: second :: hint :: tail ->
        let rows = [ first; second ] in
        let item = List.nth rows from_index in
        let remaining = filteri rows ~f:(fun index _ -> index <> from_index) in
        let insert_index = if to_index > from_index then to_index - 1 else to_index in
        let before, after = split_at insert_index remaining in
        set_choices ([ question ] @ before @ [ item ] @ after @ (hint :: tail))
      | _ -> Apple.Action.ignore
    in
    Apple.list
      [ Apple.section
          ~key:"Card"
          [ Apple.text (List.nth choices 0)
          ; Apple.movable_rows
              ~edit_mode:true
              ~on_move:move_choice
              (choice_rows choices)
              ~key:(fun choice -> choice)
              ~row:Apple.text
          ; Apple.text (List.nth choices 3)
          ]
      ]
      ~key:Apple.section_key
      ~row:(fun node -> node)
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"movable-rows#")
    "movable rows should render as a separate group inside a section";
  require
    (contains rendered ~substring:"edit-mode on-move")
    "movable rows should expose Swift edit mode and move behavior";
  Backend.move_rows_exn root ~path:[ 0; 1 ] ~from_index:0 ~to_index:2;
  require
    (contains (Backend.show root) ~substring:"text=\"Question\"")
    "non-movable rows should stay in the section";
  require
    (String.equal (Backend.find_text_exn root ~path:[ 0; 1; 0 ]) "DNA")
    "moving the first movable row after the second should update that group"
;;

let () =
  test_event_rerenders_component_state ();
  test_scoped_state_is_independent ();
  test_tab_selection_updates_state ();
  test_sidebar_history_actions_are_separate_and_clickable ();
  test_sidebar_actions_can_keep_compact_drawer_open ();
  test_compact_sidebar_top_bar_uses_system_toolbar_item_chrome ();
  test_compact_sidebar_close_paths_share_swift_animation ();
  test_image_semantic_color_renders ();
  test_button_label_renders_custom_clickable_content ();
  test_button_renders_bordered_prominent_style ();
  test_button_renders_plain_style ();
  test_on_appear_event_rerenders_component_state ();
  test_searchable_renders_prompt ();
  test_picker_renders_segmented_style ();
  test_liquid_glass_panel_renders ();
  test_pill_text_field_uses_liquid_glass_chrome ();
  test_plain_text_field_renders_plain_style ();
  test_file_image_can_render_swift_card_image_style ();
  test_keyboard_dismiss_controls_renders ();
  test_scroll_dismisses_keyboard_renders ();
  test_secondary_fill_panel_renders ();
  test_context_menu_renders_and_clicks_actions ();
  test_copy_text_to_clipboard_action_updates_test_clipboard ();
  test_copy_image_file_to_clipboard_action_updates_test_clipboard ();
  test_toggle_audio_file_playback_action_updates_test_playback_state ();
  test_audio_recording_actions_update_testing_backend ();
  test_toolbar_item_can_render_share_link ();
  test_movable_rows_move_only_the_group_children ()
;;
