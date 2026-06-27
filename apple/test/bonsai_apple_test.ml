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

let substring_index text ~substring ~from =
  let text_length = String.length text in
  let substring_length = String.length substring in
  let rec loop index =
    if substring_length = 0
    then Some index
    else if index + substring_length > text_length
    then None
    else if String.sub text index substring_length = substring
    then Some index
    else loop (index + 1)
  in
  loop from
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
let swiftui_backend_source_path = "../swiftui/bonsai_apple_swiftui.ml"

let test_navigation_value_links_keep_primary_tap_for_link () =
  let source = read_file swiftui_source_path in
  require
    (count_substrings
       source
       ~substring:"navigationLinkLabel(suppressRowActions: true)"
     >= 2)
    "both value-based and destination-based NavigationLink labels should suppress \
     nested row actions so the primary tap opens the link"
;;

let test_navigation_value_links_do_not_preempt_system_push () =
  let source = read_file swiftui_source_path in
  let value_link_start =
    match
      substring_index
        source
        ~substring:"if let navigationValue = node.navigationLinkValue"
        ~from:0
    with
    | Some index -> index
    | None -> failwith "value-based NavigationLink branch not found"
  in
  let destination_link_start =
    match
      substring_index
        source
        ~substring:"} else {\n        NavigationLink {"
        ~from:value_link_start
    with
    | Some index -> index
    | None -> failwith "destination NavigationLink branch not found"
  in
  let value_branch =
    String.sub source value_link_start (destination_link_start - value_link_start)
  in
  require
    (not (contains value_branch ~substring:"simultaneousGesture"))
    "value-based NavigationLink should let NavigationStack update path first so push/pop \
     and header transitions remain native"
;;

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
    (count_substrings source ~substring:"performSidebarAction(action)" >= 2)
    "compact sidebar action taps should share the data-driven action helper";
  require
    (contains source ~substring:"selectSidebarActionRoute(selectedTab")
    "compact sidebar actions should select the route locally before the OCaml rerender";
  require
    (contains source ~substring:"node.selectedTabId = selectedTab")
    "compact sidebar route selection should update the selected route in the Swift \
     animation transaction";
  require
    (count_substrings source ~substring:"closeCompactSidebarIfNeeded(action)" = 1)
    "compact sidebar action close policy should stay centralized";
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
            ~selects_tab:"chat"
            ~id:"inbox"
            ~title:"Inbox"
            ~system_image:"tray"
            ~on_click:(set_event "inbox")
            ()
        ; Apple.sidebar_action
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
      [ Apple.tab ~id:"decks" ~title:"Decks" (Apple.text event)
      ; Apple.tab ~id:"chat" ~title:"Chat" (Apple.text event)
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
    (contains rendered ~substring:"inbox:Inbox:tray:selects=chat")
    "sidebar action should expose the route it selects when it differs from its action id";
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
       ~substring:"sidebar-shell-background=home-body-ignores-safe-area-outside-clip")
    "compact sidebar shell background should cover the top and bottom safe areas";
  require
    (contains
       rendered
       ~substring:"sidebar-bottom-controls=safe-area-inset keyboard-offset top-padding=10")
    "compact sidebar bottom controls should keep Swift safe-area inset layout while \
     offsetting above the keyboard";
  require
    (contains
       rendered
       ~substring:
         "sidebar-scroll-disabled=dragging content-scroll-disabled=open-or-dragging")
    "compact sidebar should disable scroll during the same drawer states as Swift";
  require
    (contains
       rendered
       ~substring:
         "sidebar-route-selection-animation=swift-interactive-spring \
          route-change-and-close")
    "compact sidebar route selection should animate route changes and drawer close";
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

let test_compact_sidebar_bottom_search_tracks_keyboard () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"sidebarKeyboardBottomPadding")
    "compact sidebar bottom search should add keyboard-aware bottom padding instead of \
     staying behind the keyboard";
  require
    (contains source ~substring:"keyboardWillChangeFrameNotification")
    "compact sidebar should observe keyboard frame changes for the custom full-screen \
     drawer";
  require
    (contains source ~substring:".offset(y: -sidebarKeyboardBottomPadding)")
    "compact sidebar bottom search should visually move above the keyboard; changing \
     only the safe-area inset padding can still leave the control under the keyboard"
;;

let test_compact_sidebar_keeps_presented_sheets_interactive () =
  let source = read_file swiftui_source_path in
  require
    (not (contains source ~substring:".disabled(isCompactSidebarOpen)"))
    "compact sidebar should not disable the selected route subtree because app-level \
     sheets are attached there in the OCaml backend; disabling that subtree makes \
     practice/settings sheets open but not respond to taps"
;;

let test_multiple_sheet_modifiers_install_only_presented_sheet () =
  let source = read_file swiftui_backend_source_path in
  require
    (contains source ~substring:"pending_sheet")
    "SwiftUI backend should arbitrate multiple sheet modifiers through a pending sheet \
     instead of letting a later false sheet overwrite an earlier presented one";
  require
    (contains source ~substring:"install_pending_sheet")
    "SwiftUI backend should install the chosen sheet once after scanning modifiers"
;;

let test_sheet_content_host_fills_sheet_background () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"bonsaiSheetContentHost")
    "SwiftUI sheets should wrap native content in a common host container";
  require
    (contains
       source
       ~substring:".frame(maxWidth: .infinity, maxHeight: .infinity")
    "SwiftUI sheet host should fill the sheet instead of letting intrinsic-width content \
     leave uncovered side gutters";
  require
    (contains source ~substring:".background(bonsaiHomeBodyBackground")
    "SwiftUI sheet host should paint the app body background across the full sheet"
;;

let test_sheet_content_host_preserves_leading_content_alignment () =
  let source = read_file swiftui_source_path in
  let host_start =
    match substring_index source ~substring:"private func bonsaiSheetContentHost" ~from:0 with
    | Some index -> index
    | None -> failwith "bonsaiSheetContentHost not found"
  in
  let detents_start =
    match substring_index source ~substring:"private var sheetPresentationDetents" ~from:host_start with
    | Some index -> index
    | None -> failwith "sheetPresentationDetents not found after bonsaiSheetContentHost"
  in
  let host_source = String.sub source host_start (detents_start - host_start) in
  require
    (contains host_source ~substring:"ZStack(alignment: .topLeading)")
    "SwiftUI sheet host should paint a full-width background without forcing sheet \
     content into the horizontal center";
  require
    (contains host_source ~substring:"alignment: .topLeading")
    "SwiftUI sheet host should keep sheet content leading-aligned while the host \
     background fills the sheet"
;;

let test_custom_label_buttons_use_full_label_hit_target () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"customButtonLabelHitTarget")
    "custom label buttons should wrap their label content in a shared full-frame hit \
     target";
  require
    (contains source ~substring:".contentShape(Rectangle())")
    "custom label buttons should use the whole label frame as the tappable area instead \
     of only the visible glyphs"
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

let test_text_field_delete_backward_at_start_event () =
  Backend.reset ();
  let component graph =
    let deleted, set_deleted = Apple.state graph ~key:"deleted" false in
    Apple.vstack
      [
        Apple.text_field ~text:""
          ~placeholder:"Block"
          ~on_change:(fun _ -> Apple.Action.ignore)
          ~on_delete_backward_at_start:(set_deleted true)
          ();
        Apple.text (if deleted then "deleted" else "idle");
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  Backend.delete_backward_at_start_text_exn root ~path:[ 0 ];
  App.flush_and_render app;
  let rendered =
    match App.view app with
    | Some root -> Backend.show root
    | None -> failwith "app did not render"
  in
  require
    (contains rendered ~substring:"text=\"deleted\"")
    "delete backward at the start of a text field should dispatch its event"
;;

let test_text_field_focus_renders () =
  Backend.reset ();
  let component _graph =
    Apple.text_field ~text:"Focused" ~placeholder:"Block" ~is_focused:true
      ~on_change:(fun _ -> Apple.Action.ignore)
      ()
  in
  let app = App.create component in
  App.flush_and_render app;
  let rendered =
    match App.view app with
    | Some root -> Backend.show root
    | None -> failwith "app did not render"
  in
  require (contains rendered ~substring:"text-field#") rendered;
  require
    (contains rendered ~substring:" focused")
    "focused text field should expose focus state to the backend"
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

let test_list_marks_focused_row_for_native_scroll () =
  Backend.reset ();
  let component _graph =
    Apple.list
      ~focused_row_key:"third"
      [ "first"; "second"; "third" ]
      ~key:(fun row -> row)
      ~row:(fun row ->
        Apple.text_field
          ~text:row
          ~is_focused:(String.equal row "third")
          ~on_change:(fun _ -> Apple.Action.ignore)
          ())
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains (Backend.show root) ~substring:"focused-row=third")
    "focused list row should be exposed so the native list can keep it visible"
;;

let test_focused_row_scroll_keeps_row_visible_without_centering () =
  let source = read_file swiftui_source_path in
  require
    (not (contains source ~substring:"proxy.scrollTo(index, anchor: .center)"))
    "focused row scrolling should keep the row visible without forcing it to the center";
  require
    (contains source ~substring:"proxy.scrollTo(index)")
    "focused row scrolling should let SwiftUI choose the minimal scroll needed to reveal it"
;;

let () =
  test_event_rerenders_component_state ();
  test_scoped_state_is_independent ();
  test_tab_selection_updates_state ();
  test_sidebar_history_actions_are_separate_and_clickable ();
  test_sidebar_actions_can_keep_compact_drawer_open ();
  test_compact_sidebar_top_bar_uses_system_toolbar_item_chrome ();
  test_compact_sidebar_bottom_search_tracks_keyboard ();
  test_compact_sidebar_keeps_presented_sheets_interactive ();
  test_multiple_sheet_modifiers_install_only_presented_sheet ();
  test_sheet_content_host_fills_sheet_background ();
  test_sheet_content_host_preserves_leading_content_alignment ();
  test_custom_label_buttons_use_full_label_hit_target ();
  test_navigation_value_links_do_not_preempt_system_push ();
  test_compact_sidebar_close_paths_share_swift_animation ();
  test_navigation_value_links_keep_primary_tap_for_link ();
  test_image_semantic_color_renders ();
  test_button_label_renders_custom_clickable_content ();
  test_text_field_delete_backward_at_start_event ();
  test_text_field_focus_renders ();
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
  test_movable_rows_move_only_the_group_children ();
  test_list_marks_focused_row_for_native_scroll ();
  test_focused_row_scroll_keeps_row_visible_without_centering ()
;;
