open! Core

module Apple = Bonsai_apple

type native = nativeint
type application_delegate = nativeint
type application = nativeint
type launch_options = nativeint
type controller = nativeint
type window = nativeint

external register_event_callback
  :  (int -> string option -> unit)
  -> unit
  = "bonsai_apple_swiftui_register_event_callback"

external run_application
  :  (application_delegate -> application -> launch_options -> bool)
  -> unit
  = "bonsai_apple_swiftui_run_application"

external run_on_main : (unit -> unit) -> unit = "bonsai_apple_swiftui_run_on_main"

external create_node : int -> native = "bonsai_apple_swiftui_create_node"
external release_node : native -> unit = "bonsai_apple_swiftui_release_node"
external set_native_text : native -> string -> unit = "bonsai_apple_swiftui_set_text"

external set_native_system_image
  :  native
  -> string option
  -> unit
  = "bonsai_apple_swiftui_set_system_image"

external set_native_button_subtitle
  :  native
  -> string option
  -> unit
  = "bonsai_apple_swiftui_set_button_subtitle"

external set_native_title_visible
  :  native
  -> bool
  -> unit
  = "bonsai_apple_swiftui_set_title_visible"

external set_native_image_source
  :  native
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_image_source"

external set_native_text_attributes
  :  native
  -> int
  -> int
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_text_attributes"

external set_native_enabled
  :  native
  -> bool
  -> unit
  = "bonsai_apple_swiftui_set_enabled"

external set_native_placeholder
  :  native
  -> string option
  -> unit
  = "bonsai_apple_swiftui_set_placeholder"

external set_native_text_field_style
  :  native
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_text_field_style"

external set_native_text_field_secure
  :  native
  -> bool
  -> unit
  = "bonsai_apple_swiftui_set_text_field_secure"

external set_native_toggle
  :  native
  -> bool
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_toggle"

external set_native_progress
  :  native
  -> float
  -> unit
  = "bonsai_apple_swiftui_set_progress"

external set_native_spacing
  :  native
  -> float option
  -> unit
  = "bonsai_apple_swiftui_set_spacing"

external set_native_children
  :  native
  -> native array
  -> unit
  = "bonsai_apple_swiftui_set_children"

external set_native_on_click
  :  native
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_on_click"

external set_native_on_change
  :  native
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_on_change"

external set_native_list_row_subtitle
  :  native
  -> string option
  -> unit
  = "bonsai_apple_swiftui_set_list_row_subtitle"

external set_native_list_row_trailing_text
  :  native
  -> string option
  -> unit
  = "bonsai_apple_swiftui_set_list_row_trailing_text"

external set_native_list_row_content_style
  :  native
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_list_row_content_style"

external set_native_list_row_accessory
  :  native
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_list_row_accessory"

external set_native_list_row_title_strikethrough
  :  native
  -> bool
  -> unit
  = "bonsai_apple_swiftui_set_list_row_title_strikethrough"

external set_native_list_row_leading_system_image
  :  native
  -> string option
  -> unit
  = "bonsai_apple_swiftui_set_list_row_leading_system_image"

external set_native_list_row_preview_image_path
  :  native
  -> string option
  -> unit
  = "bonsai_apple_swiftui_set_list_row_preview_image_path"

external set_native_list_row_leading
  :  native
  -> string option
  -> string option
  -> bool
  -> unit
  = "bonsai_apple_swiftui_set_list_row_leading"

external set_native_list_row_leading_accessibility
  :  native
  -> string
  -> unit
  = "bonsai_apple_swiftui_set_list_row_leading_accessibility"

external set_native_list_row_leading_event
  :  native
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_list_row_leading_event"

external set_native_section
  :  native
  -> string option
  -> unit
  = "bonsai_apple_swiftui_set_section"

external clear_native_picker
  :  native
  -> string
  -> string
  -> int
  -> unit
  = "bonsai_apple_swiftui_clear_picker"

external append_native_picker_option
  :  native
  -> string
  -> string
  -> unit
  = "bonsai_apple_swiftui_append_picker_option"

external set_native_file_exporter
  :  native
  -> string
  -> string
  -> string
  -> unit
  = "bonsai_apple_swiftui_set_file_exporter"

external set_native_share_link
  :  native
  -> string
  -> unit
  = "bonsai_apple_swiftui_set_share_link"

external set_native_file_importer
  :  native
  -> string array
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_file_importer"

external set_native_image_payload_mode
  :  native
  -> bool
  -> unit
  = "bonsai_apple_swiftui_set_image_payload_mode"

external clear_native_list_row_actions
  :  native
  -> unit
  = "bonsai_apple_swiftui_clear_list_row_actions"

external append_native_list_row_action
  :  native
  -> string
  -> string option
  -> int
  -> int
  -> unit
  = "bonsai_apple_swiftui_append_list_row_action"

external clear_native_list_row_menu_actions
  :  native
  -> unit
  = "bonsai_apple_swiftui_clear_list_row_menu_actions"

external append_native_list_row_menu_action
  :  native
  -> string
  -> string option
  -> int
  -> int
  -> unit
  = "bonsai_apple_swiftui_append_list_row_menu_action"

external set_native_searchable
  :  native
  -> int
  -> string
  -> unit
  = "bonsai_apple_swiftui_set_searchable"

external clear_native_searchable
  :  native
  -> unit
  = "bonsai_apple_swiftui_clear_searchable"

external set_native_sheet
  :  native
  -> native option
  -> bool
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_sheet"

external set_native_alert
  :  native
  -> bool
  -> int
  -> string option
  -> string option
  -> unit
  = "bonsai_apple_swiftui_set_alert"

external set_native_alert_text_field
  :  native
  -> string option
  -> string option
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_alert_text_field"

external clear_native_alert_actions
  :  native
  -> unit
  = "bonsai_apple_swiftui_clear_alert_actions"

external append_native_alert_action
  :  native
  -> string
  -> string
  -> int
  -> bool
  -> int
  -> unit
  = "bonsai_apple_swiftui_append_alert_action_bytecode"
    "bonsai_apple_swiftui_append_alert_action"

external set_native_navigation_title
  :  native
  -> string option
  -> unit
  = "bonsai_apple_swiftui_set_navigation_title"

external clear_native_toolbar
  :  native
  -> unit
  = "bonsai_apple_swiftui_clear_toolbar"

external append_native_toolbar_item
  :  native
  -> string
  -> string
  -> string option
  -> bool
  -> int
  -> unit
  = "bonsai_apple_swiftui_append_toolbar_item_bytecode"
    "bonsai_apple_swiftui_append_toolbar_item"

external append_native_toolbar_menu_action
  :  native
  -> string
  -> string
  -> string option
  -> int
  -> int
  -> string option
  -> string option
  -> string option
  -> unit
  = "bonsai_apple_swiftui_append_toolbar_menu_action_bytecode"
    "bonsai_apple_swiftui_append_toolbar_menu_action"

external set_native_padding
  :  native
  -> float
  -> float
  -> float
  -> float
  -> unit
  = "bonsai_apple_swiftui_set_padding"

external set_native_frame
  :  native
  -> float
  -> float
  -> unit
  = "bonsai_apple_swiftui_set_frame"

external clear_native_tabs
  :  native
  -> string
  -> int
  -> unit
  = "bonsai_apple_swiftui_clear_tabs"

external append_native_tab
  :  native
  -> string
  -> string
  -> string option
  -> int
  -> unit
  = "bonsai_apple_swiftui_append_tab"

external clear_native_sidebar_shell
  :  native
  -> string option
  -> string
  -> int
  -> unit
  = "bonsai_apple_swiftui_clear_sidebar_shell"

external set_native_sidebar_header_action
  :  native
  -> string option
  -> string option
  -> string option
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_sidebar_header_action"

external append_native_sidebar_action
  :  native
  -> string
  -> string
  -> string option
  -> int
  -> unit
  = "bonsai_apple_swiftui_append_sidebar_action"

external set_native_sidebar_bottom_action
  :  native
  -> string option
  -> string option
  -> string option
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_sidebar_bottom_action"

external make_native_controller
  :  native
  -> controller
  = "bonsai_apple_swiftui_make_controller"

external update_native_controller
  :  controller
  -> native
  -> unit
  = "bonsai_apple_swiftui_update_controller"

external release_controller : controller -> unit = "bonsai_apple_swiftui_release_controller"
external make_native_window : native -> window = "bonsai_apple_swiftui_make_window"
external release_window : window -> unit = "bonsai_apple_swiftui_release_window"

external http_send_json_native
  :  string
  -> string
  -> string option
  -> string
  -> float
  -> (bool -> string -> unit)
  -> unit
  = "bonsai_apple_swiftui_http_send_json_bytecode" "bonsai_apple_swiftui_http_send_json"

module Http = struct
  type request =
    { method_ : string
    ; url : string
    ; authorization : string option
    ; body : string
    ; timeout_seconds : float
    }

  let send_json request =
    Bonsai.Effect.Expert.of_fun ~f:(fun ~callback ~on_exn:_ ->
      http_send_json_native
        request.method_
        request.url
        request.authorization
        request.body
        request.timeout_seconds
        (fun success response ->
          callback (if success then Ok response else Error response)))
  ;;
end

let no_event = -1

type event_handler =
  | Click of (unit -> unit)
  | Change of (string -> unit)

let next_event_id = ref 0
let event_handlers : event_handler Int.Table.t = Int.Table.create ()

let install_handler event_id handler =
  match event_id with
  | Some event_id ->
    Hashtbl.set event_handlers ~key:event_id ~data:handler;
    event_id
  | None ->
    Int.incr next_event_id;
    Hashtbl.set event_handlers ~key:!next_event_id ~data:handler;
    !next_event_id
;;

let clear_handler = Option.iter ~f:(Hashtbl.remove event_handlers)

let dispatch_event event_id text =
  match Hashtbl.find event_handlers event_id with
  | None -> ()
  | Some (Click f) -> f ()
  | Some (Change f) -> f (Option.value text ~default:"")
;;

let () = register_event_callback dispatch_event

let node_kind_id = function
  | Apple.Label -> 0
  | Apple.Button -> 1
  | Apple.Text_field -> 2
  | Apple.Text_editor -> 3
  | Apple.Toggle -> 22
  | Apple.Stack Apple.Vertical -> 4
  | Apple.Stack Apple.Horizontal -> 5
  | Apple.Scroll_view -> 6
  | Apple.List -> 7
  | Apple.Navigation_stack -> 8
  | Apple.Navigation_link -> 24
  | Apple.Navigation_split -> 20
  | Apple.Adaptive_layout -> 21
  | Apple.Tab_view -> 9
  | Apple.Sidebar_split -> 16
  | Apple.Image -> 10
  | Apple.List_row -> 11
  | Apple.Section -> 12
  | Apple.Picker -> 13
  | Apple.Custom_view _ -> 14
  | Apple.Photo_picker -> 15
  | Apple.Share_link -> 23
  | Apple.File_exporter -> 17
  | Apple.File_importer -> 18
  | Apple.Camera_capture -> 19
  | Apple.Progress_view -> 25
;;

module Backend = struct
  type view =
    { native : native
    ; mutable click_event_id : int option
    ; mutable change_event_id : int option
    ; mutable search_event_id : int option
    ; mutable tab_select_event_id : int option
    ; mutable sheet_dismiss_event_id : int option
    ; mutable alert_event_ids : int list
    ; mutable toolbar_event_ids : int list
    ; mutable picker_select_event_id : int option
    ; mutable row_event_ids : int list
    ; mutable sidebar_event_ids : int list
    ; mutable sidebar_search_event_id : int option
    ; mutable controller : controller option
    }

  let create kind =
    let native = create_node (node_kind_id kind) in
    (match kind with
     | Apple.Custom_view kind -> set_native_text native kind
     | _ -> ());
    { native
    ; click_event_id = None
    ; change_event_id = None
    ; search_event_id = None
    ; tab_select_event_id = None
    ; sheet_dismiss_event_id = None
    ; alert_event_ids = []
    ; toolbar_event_ids = []
    ; picker_select_event_id = None
    ; row_event_ids = []
    ; sidebar_event_ids = []
    ; sidebar_search_event_id = None
    ; controller = None
    }
  ;;

  let destroy view =
    clear_handler view.click_event_id;
    clear_handler view.change_event_id;
    clear_handler view.search_event_id;
    clear_handler view.tab_select_event_id;
    clear_handler view.sheet_dismiss_event_id;
    List.iter view.alert_event_ids ~f:(Hashtbl.remove event_handlers);
    List.iter view.toolbar_event_ids ~f:(fun event_id -> clear_handler (Some event_id));
    clear_handler view.picker_select_event_id;
    clear_handler view.sidebar_search_event_id;
    List.iter view.row_event_ids ~f:(Hashtbl.remove event_handlers);
    List.iter view.sidebar_event_ids ~f:(Hashtbl.remove event_handlers);
    Option.iter view.controller ~f:release_controller;
    view.controller <- None;
    release_node view.native
  ;;

  let set_text view text = set_native_text view.native text
  let set_system_image view system_image = set_native_system_image view.native system_image
  let set_button_subtitle view subtitle = set_native_button_subtitle view.native subtitle
  let set_title_visible view is_visible = set_native_title_visible view.native is_visible
  let set_enabled view is_enabled = set_native_enabled view.native is_enabled

  let image_source_id = function
    | Apple.System_image -> 0
    | Apple.File_image -> 1
  ;;

  let set_image_source view source =
    set_native_image_source view.native (image_source_id source)
  ;;

  let text_style_id = function
    | Apple.Large_title -> 0
    | Apple.Title -> 1
    | Apple.Title2 -> 2
    | Apple.Title3 -> 3
    | Apple.Headline -> 4
    | Apple.Body -> 5
    | Apple.Callout -> 6
    | Apple.Subheadline -> 7
    | Apple.Footnote -> 8
    | Apple.Caption -> 9
    | Apple.Caption2 -> 10
  ;;

  let text_weight_id = function
    | Apple.Regular -> 0
    | Apple.Semibold -> 1
    | Apple.Bold -> 2
  ;;

  let text_color_id = function
    | Apple.Primary -> 0
    | Apple.Secondary -> 1
    | Apple.Tertiary -> 2
  ;;

  let set_text_attributes view (attributes : Apple.text_attributes) =
    set_native_text_attributes
      view.native
      (text_style_id attributes.Apple.style)
      (text_weight_id attributes.weight)
      (text_color_id attributes.color)
  ;;

  let set_placeholder view placeholder = set_native_placeholder view.native placeholder

  let text_field_style_id = function
    | Apple.Rounded_border -> 0
    | Apple.Pill -> 1
  ;;

  let set_text_field_style view style =
    set_native_text_field_style view.native (text_field_style_id style)
  ;;

  let set_text_field_secure view is_secure =
    set_native_text_field_secure view.native is_secure
  ;;

  let set_toggle view ~is_on ~on_change =
    let event_id =
      install_handler
        view.change_event_id
        (Change (fun value -> on_change (Bool.of_string value)))
    in
    view.change_event_id <- Some event_id;
    set_native_toggle view.native is_on event_id
  ;;

  let set_progress view ~value = set_native_progress view.native value

  let set_spacing view spacing = set_native_spacing view.native spacing

  let set_children view ~keyed:_ children =
    set_native_children view.native (Array.of_list (List.map children ~f:(fun child -> child.native)))
  ;;

  let set_tabs view ~selected ~on_select (tabs : Apple.rendered_tab list) =
    let event_id =
      match on_select with
      | None ->
        clear_handler view.tab_select_event_id;
        view.tab_select_event_id <- None;
        no_event
      | Some on_select ->
        let event_id =
          install_handler view.tab_select_event_id (Change (fun id -> on_select id))
        in
        view.tab_select_event_id <- Some event_id;
        event_id
    in
    clear_native_tabs view.native selected event_id;
    List.iter tabs ~f:(fun tab ->
      append_native_tab
        view.native
        tab.Apple.id
        tab.title
        tab.system_image
        (match tab.role with
         | None -> 0
         | Some Apple.Search -> 1))
  ;;

  let set_sidebar_shell
    view
    ~(header_action : Apple.rendered_sidebar_action option)
    ~(actions : Apple.rendered_sidebar_action list)
    ~bottom_search_placeholder
    ~bottom_search_text
    ~bottom_search_on_change
    ~(bottom_action : Apple.rendered_sidebar_action option)
    =
    List.iter view.sidebar_event_ids ~f:(Hashtbl.remove event_handlers);
    view.sidebar_event_ids <- [];
    let install_sidebar_action (action : Apple.rendered_sidebar_action) =
      let event_id = install_handler None (Click action.on_click) in
      view.sidebar_event_ids <- event_id :: view.sidebar_event_ids;
      event_id
    in
    let bottom_search_event_id =
      match bottom_search_on_change with
      | None ->
        clear_handler view.sidebar_search_event_id;
        view.sidebar_search_event_id <- None;
        no_event
      | Some on_change ->
        let event_id =
          install_handler view.sidebar_search_event_id (Change (fun text -> on_change text))
        in
        view.sidebar_search_event_id <- Some event_id;
        event_id
    in
    clear_native_sidebar_shell
      view.native
      bottom_search_placeholder
      bottom_search_text
      bottom_search_event_id;
    (match header_action with
     | None -> set_native_sidebar_header_action view.native None None None no_event
     | Some action ->
       set_native_sidebar_header_action
         view.native
         (Some action.Apple.id)
         (Some action.title)
         action.system_image
         (install_sidebar_action action));
    List.iter actions ~f:(fun action ->
      append_native_sidebar_action
        view.native
        action.Apple.id
        action.title
        action.system_image
        (install_sidebar_action action));
    match bottom_action with
    | None -> set_native_sidebar_bottom_action view.native None None None no_event
    | Some action ->
      set_native_sidebar_bottom_action
        view.native
        (Some action.Apple.id)
        (Some action.title)
        action.system_image
        (install_sidebar_action action)
  ;;

  let set_section view ~title = set_native_section view.native title

  let set_picker
    view
    ~title
    ~selected
    ~on_select
    (options : Apple.rendered_picker_option list)
    =
    let event_id =
      match on_select with
      | None ->
        clear_handler view.picker_select_event_id;
        view.picker_select_event_id <- None;
        no_event
      | Some on_select ->
        let event_id =
          install_handler view.picker_select_event_id (Change (fun id -> on_select id))
        in
        view.picker_select_event_id <- Some event_id;
        event_id
    in
    clear_native_picker view.native title selected event_id;
    List.iter options ~f:(fun option ->
      append_native_picker_option view.native option.Apple.id option.title)
  ;;

  let set_file_exporter view (export : Apple.file_export) =
    set_native_file_exporter
      view.native
      export.filename
      export.content_type
      export.content
  ;;

  let set_share_link view (share_link : Apple.share_link) =
    set_native_share_link view.native share_link.url
  ;;

  let set_file_importer view ~allowed_content_types ~on_select =
    let event_id =
      match on_select with
      | None ->
        clear_handler view.change_event_id;
        view.change_event_id <- None;
        no_event
      | Some on_select ->
        let event_id =
          install_handler view.change_event_id (Change (fun content -> on_select content))
        in
        view.change_event_id <- Some event_id;
        event_id
    in
    set_native_file_importer
      view.native
      (Array.of_list allowed_content_types)
      event_id
  ;;

  let set_image_payload_mode view wants_payload =
    set_native_image_payload_mode view.native wants_payload
  ;;

  let set_on_click view handler =
    match handler with
    | None ->
      clear_handler view.click_event_id;
      view.click_event_id <- None;
      set_native_on_click view.native no_event
    | Some handler ->
      let event_id = install_handler view.click_event_id (Click handler) in
      view.click_event_id <- Some event_id;
      set_native_on_click view.native event_id
  ;;

  let set_on_change view handler =
    match handler with
    | None ->
      clear_handler view.change_event_id;
      view.change_event_id <- None;
      set_native_on_change view.native no_event
    | Some handler ->
      let event_id = install_handler view.change_event_id (Change handler) in
      view.change_event_id <- Some event_id;
      set_native_on_change view.native event_id
  ;;

  let style_id = function
    | Apple.Default -> 0
    | Apple.Destructive -> 1
  ;;

  let list_row_content_style_id = function
    | Apple.Standard -> 0
    | Apple.Deck_preview -> 1
    | Apple.Card_preview -> 2
  ;;

  let list_row_accessory_id = function
    | Apple.No_accessory -> 0
    | Apple.Disclosure_indicator -> 1
  ;;

  let clear_row_events view =
    List.iter view.row_event_ids ~f:(Hashtbl.remove event_handlers);
    view.row_event_ids <- []
  ;;

  let install_row_event view f =
    Int.incr next_event_id;
    Hashtbl.set event_handlers ~key:!next_event_id ~data:(Click f);
    view.row_event_ids <- !next_event_id :: view.row_event_ids;
    !next_event_id
  ;;

  let refresh_list_row_callbacks
    view
    ~on_click
    ~(leading_button : Apple.rendered_row_leading_button option)
    ~(swipe_actions : Apple.rendered_row_action list)
    ~(menu_actions : Apple.rendered_row_action list)
    =
    set_on_click view on_click;
    clear_row_events view;
    (match leading_button with
     | None -> set_native_list_row_leading_event view.native no_event
     | Some leading ->
       let event_id = install_row_event view leading.Apple.on_click in
       set_native_list_row_leading_event view.native event_id);
    clear_native_list_row_actions view.native;
    List.iter swipe_actions ~f:(fun action ->
      let event_id = install_row_event view action.Apple.on_click in
      append_native_list_row_action
        view.native
        action.title
        action.system_image
        (style_id action.style)
        event_id);
    clear_native_list_row_menu_actions view.native;
    List.iter menu_actions ~f:(fun action ->
      let event_id = install_row_event view action.Apple.on_click in
      append_native_list_row_menu_action
        view.native
        action.title
        action.system_image
        (style_id action.style)
        event_id)
  ;;

  let set_list_row
    view
    ~title
    ~subtitle
    ~trailing_text
    ~leading_system_image
    ~preview_image_path
    ~content_style
    ~accessory
    ~title_strikethrough
    ~(leading_button : Apple.rendered_row_leading_button option)
    ~(swipe_actions : Apple.rendered_row_action list)
    ~(menu_actions : Apple.rendered_row_action list)
    =
    clear_row_events view;
    set_native_text view.native title;
    set_native_list_row_subtitle view.native subtitle;
    set_native_list_row_trailing_text view.native trailing_text;
    set_native_list_row_content_style
      view.native
      (list_row_content_style_id content_style);
    set_native_list_row_accessory view.native (list_row_accessory_id accessory);
    set_native_list_row_leading_system_image view.native leading_system_image;
    set_native_list_row_preview_image_path view.native preview_image_path;
    set_native_list_row_title_strikethrough view.native title_strikethrough;
    (match leading_button with
     | None ->
       set_native_list_row_leading view.native None None false;
       set_native_list_row_leading_accessibility view.native ""
     | Some leading ->
       set_native_list_row_leading
         view.native
         (Some leading.system_image)
         leading.selected_system_image
         leading.selected;
       set_native_list_row_leading_accessibility view.native leading.accessibility_label);
    refresh_list_row_callbacks
      view
      ~on_click:None
      ~leading_button
      ~swipe_actions
      ~menu_actions
  ;;

  let install_searchable view ~schedule_event ~text ~on_change =
    let event_id =
      install_handler
        view.search_event_id
        (Change (fun text -> schedule_event (on_change text)))
    in
    view.search_event_id <- Some event_id;
    set_native_searchable view.native event_id text
  ;;

  let clear_searchable view =
    clear_handler view.search_event_id;
    view.search_event_id <- None;
    clear_native_searchable view.native
  ;;

  let install_sheet view ~schedule_event ~is_presented ~content ~on_dismiss =
    let dismiss_event_id =
      match on_dismiss with
      | None ->
        clear_handler view.sheet_dismiss_event_id;
        view.sheet_dismiss_event_id <- None;
        no_event
      | Some on_dismiss ->
        let event_id =
          install_handler
            view.sheet_dismiss_event_id
            (Click (fun () -> schedule_event on_dismiss))
        in
        view.sheet_dismiss_event_id <- Some event_id;
        event_id
    in
    set_native_sheet
      view.native
      (Option.map content ~f:(fun content -> content.native))
      is_presented
      dismiss_event_id
  ;;

  let clear_sheet view =
    clear_handler view.sheet_dismiss_event_id;
    view.sheet_dismiss_event_id <- None;
    set_native_sheet view.native None false no_event
  ;;

  let alert_role_id = function
    | Apple.Alert_default -> 0
    | Alert_cancel -> 1
    | Alert_destructive -> 2
  ;;

  let clear_alert_events view =
    List.iter view.alert_event_ids ~f:(Hashtbl.remove event_handlers);
    view.alert_event_ids <- []
  ;;

  let install_alert
    view
    ~schedule_event
    ~is_presented
    ~title
    ~message
    ~text
    ~placeholder
    ~on_text_change
    ~actions
    ~on_dismiss
    =
    clear_alert_events view;
    let install_click effect =
      let event_id = install_handler None (Click (fun () -> schedule_event effect)) in
      view.alert_event_ids <- event_id :: view.alert_event_ids;
      event_id
    in
    let dismiss_event_id =
      match on_dismiss with
      | None -> no_event
      | Some on_dismiss -> install_click on_dismiss
    in
    let text_event_id =
      match text, on_text_change with
      | Some _, Some on_text_change ->
        let event_id =
          install_handler
            None
            (Change (fun text -> schedule_event (on_text_change text)))
        in
        view.alert_event_ids <- event_id :: view.alert_event_ids;
        event_id
      | _ -> no_event
    in
    set_native_alert view.native is_presented dismiss_event_id (Some title) message;
    set_native_alert_text_field view.native text placeholder text_event_id;
    clear_native_alert_actions view.native;
    List.iter actions ~f:(fun (action : Apple.alert_action) ->
      append_native_alert_action
        view.native
        action.id
        action.title
        (alert_role_id action.role)
        action.is_enabled
        (install_click action.on_click))
  ;;

  let clear_alert view =
    clear_alert_events view;
    set_native_alert view.native false no_event None None;
    set_native_alert_text_field view.native None None no_event;
    clear_native_alert_actions view.native
  ;;

  let install_toolbar view ~schedule_event items =
    List.iter view.toolbar_event_ids ~f:(fun event_id -> clear_handler (Some event_id));
    view.toolbar_event_ids <- [];
    clear_native_toolbar view.native;
    List.iter items ~f:(fun (item : Apple.toolbar_item) ->
      let event_id = install_handler None (Click (fun () -> schedule_event item.on_click)) in
      view.toolbar_event_ids <- event_id :: view.toolbar_event_ids;
      append_native_toolbar_item
        view.native
        item.id
        item.title
        item.system_image
        item.is_enabled
        event_id;
      List.iter item.menu_actions ~f:(fun action ->
        let event_id =
          install_handler None (Click (fun () -> schedule_event action.on_click))
        in
        view.toolbar_event_ids <- event_id :: view.toolbar_event_ids;
        append_native_toolbar_menu_action
          view.native
          item.id
          action.title
          action.system_image
          (style_id action.style)
          event_id
          (Option.map action.file_export ~f:(fun export -> export.filename))
          (Option.map action.file_export ~f:(fun export -> export.content_type))
          (Option.map action.file_export ~f:(fun export -> export.content))))
  ;;

  let clear_toolbar view =
    List.iter view.toolbar_event_ids ~f:(fun event_id -> clear_handler (Some event_id));
    view.toolbar_event_ids <- [];
    clear_native_toolbar view.native
  ;;

  let set_modifiers view ~schedule_event modifiers =
    let saw_searchable = ref false in
    let saw_sheet = ref false in
    let saw_alert = ref false in
    let saw_toolbar = ref false in
    let saw_padding = ref false in
    let saw_frame = ref false in
    let saw_navigation_title = ref false in
    List.iter modifiers ~f:(function
      | Apple.Rendered_searchable { text; on_change } ->
        saw_searchable := true;
        install_searchable view ~schedule_event ~text ~on_change
      | Apple.Rendered_sheet { is_presented; content; on_dismiss } ->
        saw_sheet := true;
        install_sheet view ~schedule_event ~is_presented ~content ~on_dismiss
      | Apple.Rendered_alert
          { is_presented
          ; title
          ; message
          ; text
          ; placeholder
          ; on_text_change
          ; actions
          ; on_dismiss
          } ->
        saw_alert := true;
        install_alert
          view
          ~schedule_event
          ~is_presented
          ~title
          ~message
          ~text
          ~placeholder
          ~on_text_change
          ~actions
          ~on_dismiss
      | Apple.Rendered_padding { top; leading; bottom; trailing } ->
        saw_padding := true;
        set_native_padding view.native top leading bottom trailing
      | Apple.Rendered_frame { width; height } ->
        saw_frame := true;
        set_native_frame
          view.native
          (Option.value width ~default:(-1.))
          (Option.value height ~default:(-1.))
      | Apple.Rendered_navigation_title title ->
        saw_navigation_title := true;
        set_native_navigation_title view.native (Some title)
      | Apple.Rendered_toolbar items ->
        saw_toolbar := true;
        install_toolbar view ~schedule_event items);
    if not !saw_searchable then clear_searchable view;
    if not !saw_sheet then clear_sheet view;
    if not !saw_alert then clear_alert view;
    if not !saw_toolbar then clear_toolbar view;
    if not !saw_padding then set_native_padding view.native (-1.) (-1.) (-1.) (-1.);
    if not !saw_frame then set_native_frame view.native (-1.) (-1.);
    if not !saw_navigation_title then set_native_navigation_title view.native None
  ;;
end

module Renderer = Apple.Renderer.Make (Backend)
module App = Apple.App.Make (Backend)

let controller view =
  match view.Backend.controller with
  | Some controller -> controller
  | None ->
    let controller = make_native_controller view.native in
    view.controller <- Some controller;
    controller
;;

let update_controller controller view = update_native_controller controller view.Backend.native
let window view = make_native_window view.Backend.native
