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

external create_node : int -> native = "bonsai_apple_swiftui_create_node"
external release_node : native -> unit = "bonsai_apple_swiftui_release_node"
external set_native_text : native -> string -> unit = "bonsai_apple_swiftui_set_text"

external set_native_text_attributes
  :  native
  -> int
  -> int
  -> int
  -> unit
  = "bonsai_apple_swiftui_set_text_attributes"

external set_native_placeholder
  :  native
  -> string option
  -> unit
  = "bonsai_apple_swiftui_set_placeholder"

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

external set_native_list_row_title_strikethrough
  :  native
  -> bool
  -> unit
  = "bonsai_apple_swiftui_set_list_row_title_strikethrough"

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
  | Apple.Stack Apple.Vertical -> 3
  | Apple.Stack Apple.Horizontal -> 4
  | Apple.Scroll_view -> 5
  | Apple.List -> 6
  | Apple.Navigation_stack -> 7
  | Apple.Tab_view -> 8
  | Apple.Image -> 9
  | Apple.List_row -> 10
  | Apple.Custom_view _ -> 11
;;

module Backend = struct
  type view =
    { native : native
    ; mutable click_event_id : int option
    ; mutable change_event_id : int option
    ; mutable search_event_id : int option
    ; mutable tab_select_event_id : int option
    ; mutable sheet_dismiss_event_id : int option
    ; mutable row_event_ids : int list
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
    ; row_event_ids = []
    ; controller = None
    }
  ;;

  let destroy view =
    clear_handler view.click_event_id;
    clear_handler view.change_event_id;
    clear_handler view.search_event_id;
    clear_handler view.tab_select_event_id;
    clear_handler view.sheet_dismiss_event_id;
    List.iter view.row_event_ids ~f:(Hashtbl.remove event_handlers);
    Option.iter view.controller ~f:release_controller;
    view.controller <- None;
    release_node view.native
  ;;

  let set_text view text = set_native_text view.native text

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
  let set_spacing view spacing = set_native_spacing view.native spacing

  let set_children view ~keyed:_ children =
    set_native_children view.native (Array.of_list (List.map children ~f:(fun child -> child.native)))
  ;;

  let set_tabs view ~selected ~on_select tabs =
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

  let set_list_row
    view
    ~title
    ~subtitle
    ~trailing_text
    ~title_strikethrough
    ~(leading_button : Apple.rendered_row_leading_button option)
    ~(swipe_actions : Apple.rendered_row_action list)
    =
    clear_row_events view;
    set_native_text view.native title;
    set_native_list_row_subtitle view.native subtitle;
    set_native_list_row_trailing_text view.native trailing_text;
    set_native_list_row_title_strikethrough view.native title_strikethrough;
    (match leading_button with
     | None ->
       set_native_list_row_leading view.native None None false;
       set_native_list_row_leading_accessibility view.native "";
       set_native_list_row_leading_event view.native no_event
     | Some leading ->
       let event_id = install_row_event view leading.Apple.on_click in
       set_native_list_row_leading
         view.native
         (Some leading.system_image)
         leading.selected_system_image
         leading.selected;
       set_native_list_row_leading_accessibility view.native leading.accessibility_label;
       set_native_list_row_leading_event view.native event_id);
    clear_native_list_row_actions view.native;
    List.iter swipe_actions ~f:(fun action ->
      let event_id = install_row_event view action.Apple.on_click in
      append_native_list_row_action
        view.native
        action.title
        action.system_image
        (style_id action.style)
        event_id)
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

  let set_modifiers view ~schedule_event modifiers =
    let saw_searchable = ref false in
    let saw_sheet = ref false in
    let saw_padding = ref false in
    let saw_frame = ref false in
    List.iter modifiers ~f:(function
      | Apple.Rendered_searchable { text; on_change } ->
        saw_searchable := true;
        install_searchable view ~schedule_event ~text ~on_change
      | Apple.Rendered_sheet { is_presented; content; on_dismiss } ->
        saw_sheet := true;
        install_sheet view ~schedule_event ~is_presented ~content ~on_dismiss
      | Apple.Rendered_padding { top; leading; bottom; trailing } ->
        saw_padding := true;
        set_native_padding view.native top leading bottom trailing
      | Apple.Rendered_frame { width; height } ->
        saw_frame := true;
        set_native_frame
          view.native
          (Option.value width ~default:(-1.))
          (Option.value height ~default:(-1.))
      | Apple.Rendered_toolbar _ -> ());
    if not !saw_searchable then clear_searchable view;
    if not !saw_sheet then clear_sheet view;
    if not !saw_padding then set_native_padding view.native (-1.) (-1.) (-1.) (-1.);
    if not !saw_frame then set_native_frame view.native (-1.) (-1.)
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
