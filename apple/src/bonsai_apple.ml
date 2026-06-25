open! Core

module Effect = Bonsai.Effect

type edge_insets =
  { top : float
  ; leading : float
  ; bottom : float
  ; trailing : float
  }
[@@deriving sexp_of]

type frame =
  { width : float option
  ; height : float option
  }
[@@deriving sexp_of]

type row_action_style =
  | Default
  | Destructive
[@@deriving sexp_of, equal]

type alert_action_role =
  | Alert_default
  | Alert_cancel
  | Alert_destructive
[@@deriving sexp_of, equal]

type alert_action =
  { id : string
  ; title : string
  ; role : alert_action_role
  ; is_enabled : bool
  ; on_click : unit Effect.t
  }

type file_export =
  { filename : string
  ; content_type : string
  ; content : string
  }
[@@deriving sexp_of, equal]

type share_link =
  { title : string
  ; url : string
  ; is_enabled : bool
  }
[@@deriving sexp_of, equal]

type image_source =
  | System_image
  | File_image
[@@deriving sexp_of, equal]

type image =
  { name : string
  ; source : image_source
  }
[@@deriving sexp_of, equal]

type toolbar_menu_action =
  { title : string
  ; system_image : string option
  ; style : row_action_style
  ; on_click : unit Effect.t
  ; file_export : file_export option
  }

type toolbar_item =
  { id : string
  ; title : string
  ; system_image : string option
  ; is_title_visible : bool
  ; is_enabled : bool
  ; on_click : unit Effect.t
  ; menu_actions : toolbar_menu_action list
  }

type sidebar_action =
  { id : string
  ; title : string
  ; system_image : string option
  ; on_click : unit Effect.t
  }

type text_style =
  | Large_title
  | Title
  | Title2
  | Title3
  | Headline
  | Body
  | Callout
  | Subheadline
  | Footnote
  | Caption
  | Caption2
[@@deriving sexp_of, equal]

type text_weight =
  | Regular
  | Semibold
  | Bold
[@@deriving sexp_of, equal]

type text_color =
  | Primary
  | Secondary
  | Tertiary
[@@deriving sexp_of, equal]

type text_field_style =
  | Rounded_border
  | Pill
[@@deriving sexp_of, equal]

type text_attributes =
  { style : text_style
  ; weight : text_weight
  ; color : text_color
  }
[@@deriving sexp_of, equal]

type row_leading_button =
  { system_image : string
  ; selected_system_image : string option
  ; selected : bool
  ; accessibility_label : string
  ; on_click : unit Effect.t
  }

type row_action =
  { title : string
  ; system_image : string option
  ; style : row_action_style
  ; on_click : unit Effect.t
  }

type list_row_content_style =
  | Standard
  | Deck_preview
  | Card_preview
[@@deriving sexp_of, equal]

type list_row_accessory =
  | No_accessory
  | Disclosure_indicator
[@@deriving sexp_of, equal]

type picker_option =
  { id : string
  ; title : string
  }
[@@deriving sexp_of, equal]

type image_payload =
  { id : string
  ; local_path : string
  ; mime_type : string
  ; byte_size : int
  ; sha256 : string
  ; width : int
  ; height : int
  ; recognized_text : string option
  }
[@@deriving compare, sexp_of, equal]

type list_row =
  { title : string
  ; subtitle : string option
  ; trailing_text : string option
  ; leading_system_image : string option
  ; preview_image_path : string option
  ; content_style : list_row_content_style
  ; accessory : list_row_accessory
  ; title_strikethrough : bool
  ; on_click : unit Effect.t option
  ; leading_button : row_leading_button option
  ; swipe_actions : row_action list
  ; menu_actions : row_action list
  }

type tab_role = Search [@@deriving sexp_of, equal]

type rendered_tab =
  { id : string
  ; title : string
  ; system_image : string option
  ; role : tab_role option
  }
[@@deriving sexp_of, equal]

type rendered_sidebar_action =
  { id : string
  ; title : string
  ; system_image : string option
  ; on_click : unit -> unit
  }

type axis =
  | Vertical
  | Horizontal
[@@deriving sexp_of, equal]

type backend_kind =
  | Label
  | Button
  | Text_field
  | Text_editor
  | Toggle
  | Stack of axis
  | Scroll_view
  | List
  | Navigation_stack
  | Navigation_link
  | Navigation_split
  | Adaptive_layout
  | Tab_view
  | Sidebar_split
  | Image
  | List_row
  | Section
  | Picker
  | Photo_picker
  | Share_link
  | File_exporter
  | File_importer
  | Camera_capture
  | Progress_view
  | Custom_view of string
[@@deriving sexp_of, equal]

type node =
  | Text of
      { text : string
      ; attributes : text_attributes
      }
  | Button_node of
      { title : string
      ; system_image : string option
      ; subtitle : string option
      ; is_title_visible : bool
      ; is_enabled : bool
      ; on_click : unit Effect.t
      }
  | Text_field_node of
      { text : string
      ; placeholder : string option
      ; style : text_field_style
      ; is_secure : bool
      ; on_change : string -> unit Effect.t
      ; on_submit : unit Effect.t option
      }
  | Toggle_node of
      { title : string
      ; is_on : bool
      ; on_change : bool -> unit Effect.t
      }
  | Text_editor_node of
      { text : string
      ; placeholder : string option
      ; on_change : string -> unit Effect.t
      }
  | Progress_view_node of { value : float }
  | Stack_node of
      { axis : axis
      ; spacing : float option
      ; children : node list
      }
  | Scroll_view_node of node
  | List_node of keyed_node list
  | Navigation_stack_node of node list
  | Navigation_link_node of
      { label : node
      ; destination : node
      }
  | Navigation_split_node of
      { sidebar : node
      ; content : node
      ; detail : node
      }
  | Adaptive_layout_node of
      { compact : node
      ; regular : node
      }
  | Tab_view_node of
      { selected : string
      ; on_select : string -> unit Effect.t
      ; tabs : tab list
      }
  | Sidebar_split_node of
      { title : string option
      ; compact_top_bar_visible : bool
      ; selected : string
      ; on_select : string -> unit Effect.t
      ; tabs : tab list
      ; header_action : sidebar_action option
      ; actions : sidebar_action list
      ; bottom_search_placeholder : string option
      ; bottom_search_text : string
      ; bottom_search_on_change : (string -> unit Effect.t) option
      ; bottom_action : sidebar_action option
      }
  | Image_node of image
  | List_row_node of list_row
  | Section_node of
      { key : string
      ; title : string option
      ; children : node list
      }
  | Picker_node of
      { title : string
      ; selected : string
      ; on_select : string -> unit Effect.t
      ; options : picker_option list
      }
  | Photo_picker_node of
      { title : string
      ; system_image : string option
      ; is_title_visible : bool
      ; is_enabled : bool
      ; wants_payload : bool
      ; selected : string option
      ; on_select : string -> unit Effect.t
      }
  | Share_link_node of share_link
  | File_exporter_node of
      { title : string
      ; is_enabled : bool
      ; export : file_export
      }
  | File_importer_node of
      { title : string
      ; allowed_content_types : string list
      ; on_select : string -> unit Effect.t
      }
  | Camera_capture_node of
      { title : string
      ; wants_payload : bool
      ; captured : string option
      ; on_capture : string -> unit Effect.t
      }
  | Custom_view_node of
      { key : string option
      ; kind : string
      }
  | Modified_node of modifier * node

and keyed_node =
  { key : string
  ; node : node
  }

and tab =
  { id : string
  ; title : string
  ; system_image : string option
  ; role : tab_role option
  ; content : node
  }

and modifier =
  | Padding of edge_insets
  | Regular_material_panel of { corner_radius : float }
  | Frame of frame
  | Navigation_title of string
  | Searchable of
      { text : string
      ; on_change : string -> unit Effect.t
      }
  | Toolbar of toolbar_item list
  | Tap_action of { on_click : unit Effect.t }
  | Sheet of
      { is_presented : bool
      ; content : node
      ; on_dismiss : unit Effect.t option
      }
  | Alert of
      { is_presented : bool
      ; title : string
      ; message : string option
      ; text : string option
      ; placeholder : string option
      ; on_text_change : (string -> unit Effect.t) option
      ; actions : alert_action list
      ; on_dismiss : unit Effect.t option
      }

type 'view rendered_modifier =
  | Rendered_padding of edge_insets
  | Rendered_regular_material_panel of { corner_radius : float }
  | Rendered_frame of frame
  | Rendered_navigation_title of string
  | Rendered_searchable of
      { text : string
      ; on_change : string -> unit Effect.t
      }
  | Rendered_toolbar of toolbar_item list
  | Rendered_tap_action of { on_click : unit Effect.t }
  | Rendered_sheet of
      { is_presented : bool
      ; content : 'view option
      ; on_dismiss : unit Effect.t option
      }
  | Rendered_alert of
      { is_presented : bool
      ; title : string
      ; message : string option
      ; text : string option
      ; placeholder : string option
      ; on_text_change : (string -> unit Effect.t) option
      ; actions : alert_action list
      ; on_dismiss : unit Effect.t option
      }

type rendered_row_leading_button =
  { system_image : string
  ; selected_system_image : string option
  ; selected : bool
  ; accessibility_label : string
  ; on_click : unit -> unit
  }

type rendered_row_action =
  { title : string
  ; system_image : string option
  ; style : row_action_style
  ; on_click : unit -> unit
  }

type rendered_picker_option = picker_option =
  { id : string
  ; title : string
  }
[@@deriving sexp_of, equal]

let default_text_attributes = { style = Body; weight = Regular; color = Primary }

let text ?(style = Body) ?(weight = Regular) ?(color = Primary) value =
  Text { text = value; attributes = { style; weight; color } }
;;

let button
  ?(is_enabled = true)
  ?system_image
  ?subtitle
  ?(is_title_visible = true)
  title
  ~on_click
  =
  Button_node { title; system_image; subtitle; is_title_visible; is_enabled; on_click }
;;

let text_field
  ?placeholder
  ?(style = Rounded_border)
  ?(is_secure = false)
  ?on_submit
  ~text
  ~on_change
  ()
  =
  Text_field_node { text; placeholder; style; is_secure; on_change; on_submit }
;;

let toggle title ~is_on ~on_change = Toggle_node { title; is_on; on_change }

let text_editor ?placeholder ~text ~on_change () =
  Text_editor_node { text; placeholder; on_change }
;;

let progress_view ~value = Progress_view_node { value }
let vstack ?spacing children = Stack_node { axis = Vertical; spacing; children }
let hstack ?spacing children = Stack_node { axis = Horizontal; spacing; children }
let scroll_view child = Scroll_view_node child

let list rows ~key ~row =
  let seen = String.Hash_set.create () in
  List_node
    (List.map rows ~f:(fun value ->
       let key = key value in
       if Hash_set.mem seen key then failwithf "duplicate Bonsai Apple list key: %s" key ();
       Hash_set.add seen key;
       { key; node = row value }))
;;

let section ~key ?title children = Section_node { key; title; children }

let section_key = function
  | Section_node { key; _ } -> key
  | _ -> failwith "Apple.section_key expects a section node"
;;

let picker_option ~id ~title = { id; title }

let picker ~title ~selected ~on_select (options : picker_option list) =
  let seen = String.Hash_set.create () in
  List.iter options ~f:(fun option ->
    if Hash_set.mem seen option.id
    then failwithf "duplicate Bonsai Apple picker option id: %s" option.id ();
    Hash_set.add seen option.id);
  Picker_node { title; selected; on_select; options }
;;

let navigation_stack children = Navigation_stack_node children

let navigation_link ~destination label = Navigation_link_node { label; destination }

let navigation_split ~sidebar ~content ~detail =
  Navigation_split_node { sidebar; content; detail }
;;

let adaptive_layout ~compact ~regular = Adaptive_layout_node { compact; regular }

let tab ~id ~title ?system_image ?role content =
  { id; title; system_image; role; content }
;;

let tab_view ~selected ~on_select (tabs : tab list) =
  let seen = String.Hash_set.create () in
  List.iter tabs ~f:(fun tab ->
    if Hash_set.mem seen tab.id then failwithf "duplicate Bonsai Apple tab id: %s" tab.id ();
    Hash_set.add seen tab.id);
  Tab_view_node { selected; on_select; tabs }
;;

let sidebar_split
  ?title
  ?(compact_top_bar_visible = true)
  ?(header_action : sidebar_action option)
  ?(actions = ([] : sidebar_action list))
  ?bottom_search_placeholder
  ?(bottom_search_text = "")
  ?bottom_search_on_change
  ?(bottom_action : sidebar_action option)
  ~selected
  ~on_select
  (tabs : tab list)
  =
  let seen = String.Hash_set.create () in
  List.iter tabs ~f:(fun tab ->
    if Hash_set.mem seen tab.id
    then failwithf "duplicate Bonsai Apple sidebar route id: %s" tab.id ();
    Hash_set.add seen tab.id);
  let seen_actions = String.Hash_set.create () in
  List.iter (Option.to_list header_action @ actions @ Option.to_list bottom_action) ~f:(fun action ->
    if Hash_set.mem seen_actions action.id
    then failwithf "duplicate Bonsai Apple sidebar action id: %s" action.id ();
    Hash_set.add seen_actions action.id);
  Sidebar_split_node
    { title
    ; compact_top_bar_visible
    ; selected
    ; on_select
    ; tabs
    ; header_action
    ; actions
    ; bottom_search_placeholder
    ; bottom_search_text
    ; bottom_search_on_change
    ; bottom_action
    }
;;

let image name = Image_node { name; source = System_image }
let image_file path = Image_node { name = path; source = File_image }

let image_payload_header = "bonsai-image-payload"

let is_unreserved_payload_byte = function
  | 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '-' | '_' | '.' | '~' -> true
  | _ -> false
;;

let escape_payload_field value =
  String.concat_map value ~f:(fun char ->
    if is_unreserved_payload_byte char
    then String.of_char char
    else sprintf "%%%02X" (Char.to_int char))
;;

let hex_value = function
  | '0' .. '9' as char -> Some (Char.to_int char - Char.to_int '0')
  | 'a' .. 'f' as char -> Some (10 + Char.to_int char - Char.to_int 'a')
  | 'A' .. 'F' as char -> Some (10 + Char.to_int char - Char.to_int 'A')
  | _ -> None
;;

let unescape_payload_field value =
  let buffer = Buffer.create (String.length value) in
  let rec loop index =
    if index >= String.length value
    then Buffer.contents buffer
    else if Char.equal value.[index] '%'
            && index + 2 < String.length value
    then (
      match hex_value value.[index + 1], hex_value value.[index + 2] with
      | Some high, Some low ->
        Buffer.add_char buffer (Char.of_int_exn ((high * 16) + low));
        loop (index + 3)
      | _ ->
        Buffer.add_char buffer value.[index];
        loop (index + 1))
    else (
      Buffer.add_char buffer value.[index];
      loop (index + 1))
  in
  loop 0
;;

let image_payload_to_event_text (payload : image_payload) =
  String.concat
    ~sep:"\n"
    ([ image_payload_header
     ; "id=" ^ payload.id
     ; "local_path=" ^ payload.local_path
     ; "mime_type=" ^ payload.mime_type
     ; "byte_size=" ^ Int.to_string payload.byte_size
     ; "sha256=" ^ payload.sha256
     ; "width=" ^ Int.to_string payload.width
     ; "height=" ^ Int.to_string payload.height
     ]
     @
     match payload.recognized_text with
     | None -> []
     | Some text -> [ "recognized_text=" ^ escape_payload_field text ])
;;

let image_payload_of_event_text text =
  match String.split_lines text with
  | header :: fields when String.equal header image_payload_header ->
    let values =
      fields
      |> List.filter_map ~f:(fun line -> String.lsplit2 line ~on:'=')
      |> String.Map.of_alist_reduce ~f:(fun _ latest -> latest)
    in
    let value key = Map.find values key in
    let int_value key = Option.bind (value key) ~f:Int.of_string_opt in
    (match
       value "id"
       , value "local_path"
       , value "mime_type"
       , int_value "byte_size"
       , value "sha256"
       , int_value "width"
       , int_value "height"
     with
     | Some id, Some local_path, Some mime_type, Some byte_size, Some sha256, Some width, Some height ->
       Some
         { id
         ; local_path
         ; mime_type
         ; byte_size
         ; sha256
         ; width
         ; height
         ; recognized_text = Option.map (value "recognized_text") ~f:unescape_payload_field
         }
     | _ -> None)
  | _ -> None
;;

let photo_picker
  ?(is_enabled = true)
  ?system_image
  ?(is_title_visible = true)
  ~title
  ?selected
  ~on_select
  ()
  =
  Photo_picker_node
    { title; system_image; is_title_visible; is_enabled; wants_payload = false; selected; on_select }
;;

let legacy_image_payload image_id =
  { id = image_id
  ; local_path = ""
  ; mime_type = ""
  ; byte_size = 0
  ; sha256 = ""
  ; width = 0
  ; height = 0
  ; recognized_text = None
  }
;;

let photo_picker_payload
  ?(is_enabled = true)
  ?system_image
  ?(is_title_visible = true)
  ~title
  ?selected
  ~on_select
  ()
  =
  Photo_picker_node
    { title
    ; system_image
    ; is_title_visible
    ; is_enabled
    ; wants_payload = true
    ; selected
    ; on_select =
        (fun text ->
          let payload =
            image_payload_of_event_text text |> Option.value ~default:(legacy_image_payload text)
          in
          on_select payload)
    }
;;

let file_exporter ?(is_enabled = true) ~title ~filename ~content_type ~content () =
  File_exporter_node { title; is_enabled; export = { filename; content_type; content } }
;;

let share_link ?(is_enabled = true) ~title ~url () =
  Share_link_node { title; url; is_enabled }
;;

let file_importer ~title ~allowed_content_types ~on_select () =
  File_importer_node { title; allowed_content_types; on_select }
;;

let camera_capture ~title ?captured ~on_capture () =
  Camera_capture_node { title; wants_payload = false; captured; on_capture }
;;

let camera_capture_payload ~title ?captured ~on_capture () =
  Camera_capture_node
    { title
    ; wants_payload = true
    ; captured
    ; on_capture =
        (fun text ->
          let payload =
            image_payload_of_event_text text |> Option.value ~default:(legacy_image_payload text)
          in
          on_capture payload)
    }
;;

let list_row row = List_row_node row
let custom_view ?key ~kind () = Custom_view_node { key; kind }

let default_insets = { top = 8.; leading = 8.; bottom = 8.; trailing = 8. }
let padding ?(insets = default_insets) node = Modified_node (Padding insets, node)
let regular_material_panel ?(corner_radius = 8.) node =
  Modified_node (Regular_material_panel { corner_radius }, node)
;;
let frame ?width ?height node = Modified_node (Frame { width; height }, node)
let navigation_title title node = Modified_node (Navigation_title title, node)
let searchable ~text ~on_change node = Modified_node (Searchable { text; on_change }, node)
let toolbar_item
  ?system_image
  ?(is_title_visible = true)
  ?(is_enabled = true)
  ?(menu_actions = [])
  ~id
  ~title
  ~on_click
  ()
  : toolbar_item
  =
  { id; title; system_image; is_title_visible; is_enabled; on_click; menu_actions }
;;
let toolbar items node = Modified_node (Toolbar items, node)
let tap_action ~on_click node = Modified_node (Tap_action { on_click }, node)
let alert_action ?(role = Alert_default) ?(is_enabled = true) ~id ~title ~on_click () =
  { id; title; role; is_enabled; on_click }
;;

let alert
  ~is_presented
  ~title
  ?message
  ?text
  ?placeholder
  ?on_text_change
  ?(actions = [])
  ?on_dismiss
  ()
  node
  =
  Modified_node
    ( Alert
        { is_presented
        ; title
        ; message
        ; text
        ; placeholder
        ; on_text_change
        ; actions
        ; on_dismiss
        }
    , node )
;;

let sidebar_action ~id ~title ?system_image ~(on_click : unit Effect.t) ()
  : sidebar_action
  =
  { id; title; system_image; on_click }
;;

let sheet ~is_presented ~content ?on_dismiss node =
  Modified_node (Sheet { is_presented; content; on_dismiss }, node)
;;

let rec unwrap_modifiers node =
  match node with
  | Modified_node (modifier, node) ->
    let base, modifiers = unwrap_modifiers node in
    base, modifier :: modifiers
  | node -> node, []
;;

let backend_kind = function
  | Text _ -> Label
  | Button_node _ -> Button
  | Text_field_node _ -> Text_field
  | Toggle_node _ -> Toggle
  | Text_editor_node _ -> Text_editor
  | Progress_view_node _ -> Progress_view
  | Stack_node { axis; _ } -> Stack axis
  | Scroll_view_node _ -> Scroll_view
  | List_node _ -> List
  | Navigation_stack_node _ -> Navigation_stack
  | Navigation_link_node _ -> Navigation_link
  | Navigation_split_node _ -> Navigation_split
  | Adaptive_layout_node _ -> Adaptive_layout
  | Tab_view_node _ -> Tab_view
  | Sidebar_split_node _ -> Sidebar_split
  | Image_node _ -> Image
  | List_row_node _ -> List_row
  | Section_node _ -> Section
  | Picker_node _ -> Picker
  | Photo_picker_node _ -> Photo_picker
  | Share_link_node _ -> Share_link
  | File_exporter_node _ -> File_exporter
  | File_importer_node _ -> File_importer
  | Camera_capture_node _ -> Camera_capture
  | Custom_view_node { kind; _ } -> Custom_view kind
  | Modified_node _ -> assert false
;;

module Renderer = struct
  module type Backend = sig
    type view

    val create : backend_kind -> view
    val destroy : view -> unit
    val set_text : view -> string -> unit
    val set_system_image : view -> string option -> unit
    val set_button_subtitle : view -> string option -> unit
    val set_title_visible : view -> bool -> unit
    val set_text_attributes : view -> text_attributes -> unit
    val set_placeholder : view -> string option -> unit
    val set_text_field_style : view -> text_field_style -> unit
    val set_text_field_secure : view -> bool -> unit
    val set_toggle : view -> is_on:bool -> on_change:(bool -> unit) -> unit
    val set_progress : view -> value:float -> unit
    val set_spacing : view -> float option -> unit
    val set_children : view -> keyed:(string option) list -> view list -> unit
    val set_tabs
      :  view
      -> selected:string
      -> on_select:(string -> unit) option
      -> rendered_tab list
      -> unit
    val set_sidebar_shell
      :  view
      -> title:string option
      -> compact_top_bar_visible:bool
      -> header_action:rendered_sidebar_action option
      -> actions:rendered_sidebar_action list
      -> bottom_search_placeholder:string option
      -> bottom_search_text:string
      -> bottom_search_on_change:(string -> unit) option
      -> bottom_action:rendered_sidebar_action option
      -> unit
    val set_list_row
      :  view
      -> title:string
      -> subtitle:string option
      -> trailing_text:string option
      -> leading_system_image:string option
      -> preview_image_path:string option
      -> content_style:list_row_content_style
      -> accessory:list_row_accessory
      -> title_strikethrough:bool
      -> leading_button:rendered_row_leading_button option
      -> swipe_actions:rendered_row_action list
      -> menu_actions:rendered_row_action list
      -> unit
    val refresh_list_row_callbacks
      :  view
      -> on_click:(unit -> unit) option
      -> leading_button:rendered_row_leading_button option
      -> swipe_actions:rendered_row_action list
      -> menu_actions:rendered_row_action list
      -> unit
    val set_section : view -> title:string option -> unit
    val set_picker
      :  view
      -> title:string
      -> selected:string
      -> on_select:(string -> unit) option
      -> rendered_picker_option list
      -> unit
    val set_file_exporter : view -> file_export -> unit
    val set_share_link : view -> share_link -> unit
    val set_file_importer
      :  view
      -> allowed_content_types:string list
      -> on_select:(string -> unit) option
      -> unit
    val set_image_payload_mode : view -> bool -> unit
    val set_image_source : view -> image_source -> unit
    val set_on_click : view -> (unit -> unit) option -> unit
    val set_on_change : view -> (string -> unit) option -> unit
    val set_enabled : view -> bool -> unit
    val set_modifiers
      :  view
      -> schedule_event:(unit Effect.t -> unit)
      -> view rendered_modifier list
      -> unit
  end

  module Make (Backend : Backend) = struct
    type child =
      { key : string option
      ; mounted : t
      }

    and modifier_child =
      { index : int
      ; mounted : t
      }

    and t =
      { mutable kind : backend_kind
      ; mutable view : Backend.view
      ; mutable fingerprint : string
      ; schedule_event : unit Effect.t -> unit
      ; mutable children : child list
      ; mutable modifier_children : modifier_child list
      }

    let view t = t.view

    let rec destroy t =
      List.iter t.children ~f:(fun child -> destroy child.mounted);
      List.iter t.modifier_children ~f:(fun child -> destroy child.mounted);
      Backend.destroy t.view
    ;;

    let rec fingerprint node =
      let node, modifiers = unwrap_modifiers node in
      fingerprint_parts node modifiers

    and fingerprint_parts node modifiers =
      let modifiers =
        List.map modifiers ~f:(function
          | Padding insets -> [%sexp "padding", (insets : edge_insets)]
          | Regular_material_panel { corner_radius } ->
            [%sexp "regular-material-panel", (corner_radius : float)]
          | Frame frame -> [%sexp "frame", (frame : frame)]
          | Navigation_title title -> [%sexp "navigation-title", (title : string)]
          | Searchable { text; on_change = _ } -> [%sexp "searchable", (text : string)]
          | Toolbar items ->
            [%sexp
              ( "toolbar"
              , (List.map items ~f:(fun item ->
                   ( item.id
                   , item.title
                   , item.system_image
                   , item.is_enabled
                   , List.length item.menu_actions ))
                 : (string * string * string option * bool * int) list) )]
          | Tap_action _ -> [%sexp "tap-action"]
          | Sheet { is_presented; content; on_dismiss = _ } ->
            [%sexp "sheet", (is_presented : bool), (fingerprint content : string)]
          | Alert
              { is_presented
              ; title
              ; message
              ; text
              ; placeholder
              ; on_text_change = _
              ; actions
              ; on_dismiss = _
              } ->
            [%sexp
              "alert"
            , (is_presented : bool)
            , (title : string)
            , (message : string option)
            , (text : string option)
            , (placeholder : string option)
            , (List.map actions ~f:(fun action ->
                 action.id, action.title, action.role, action.is_enabled)
               : (string * string * alert_action_role * bool) list)]
        )
      in
      let shape =
        match node with
        | Text { text; attributes } ->
          [%sexp "text", (text : string), (attributes : text_attributes)]
        | Button_node
            { title; system_image; subtitle; is_title_visible; is_enabled; on_click = _ } ->
          [%sexp
            "button"
          , (title : string)
          , (system_image : string option)
          , (subtitle : string option)
          , (is_title_visible : bool)
          , (is_enabled : bool)]
        | Text_field_node { text; placeholder; style; is_secure; on_change = _; on_submit = _ } ->
          [%sexp
            "text-field"
          , (text : string)
          , (placeholder : string option)
          , (style : text_field_style)
          , (is_secure : bool)]
        | Toggle_node { title; is_on; on_change = _ } ->
          [%sexp "toggle", (title : string), (is_on : bool)]
        | Text_editor_node { text; placeholder; on_change = _ } ->
          [%sexp "text-editor", (text : string), (placeholder : string option)]
        | Progress_view_node { value } -> [%sexp "progress-view", (value : float)]
        | Stack_node { axis; spacing; children } ->
          [%sexp
            "stack"
          , (axis : axis)
          , (spacing : float option)
          , (List.map children ~f:fingerprint : string list)]
        | Scroll_view_node child -> [%sexp "scroll-view", (fingerprint child : string)]
        | List_node rows ->
          [%sexp
            ( "list"
            , (List.map rows ~f:(fun row -> row.key, fingerprint row.node)
               : (string * string) list) )]
        | Navigation_stack_node children ->
          [%sexp "navigation-stack", (List.map children ~f:fingerprint : string list)]
        | Navigation_link_node { label; destination } ->
          [%sexp
            "navigation-link"
          , (fingerprint label : string)
          , (fingerprint destination : string)]
        | Navigation_split_node { sidebar; content; detail } ->
          [%sexp
            "navigation-split"
          , (fingerprint sidebar : string)
          , (fingerprint content : string)
          , (fingerprint detail : string)]
        | Adaptive_layout_node { compact; regular } ->
          [%sexp
            "adaptive-layout", (fingerprint compact : string), (fingerprint regular : string)]
        | List_row_node row ->
          let leading =
            Option.map row.leading_button ~f:(fun leading ->
              ( leading.system_image
              , leading.selected_system_image
              , leading.selected
              , leading.accessibility_label ))
          in
          let actions =
            List.map row.swipe_actions ~f:(fun action ->
              action.title, action.system_image, action.style)
          in
          let menu_actions =
            List.map row.menu_actions ~f:(fun action ->
              action.title, action.system_image, action.style)
          in
          [%sexp
            "list-row"
          , (row.title : string)
          , (row.subtitle : string option)
          , (row.trailing_text : string option)
          , (row.leading_system_image : string option)
          , (row.title_strikethrough : bool)
          , (leading : (string * string option * bool * string) option)
          , (actions : (string * string option * row_action_style) list)
          , (menu_actions : (string * string option * row_action_style) list)]
        | Section_node { key; title; children } ->
          [%sexp
            "section"
          , (key : string)
          , (title : string option)
          , (List.map children ~f:fingerprint : string list)]
        | Tab_view_node { selected; tabs; on_select = _ } ->
          [%sexp
            ( "tabs"
            , (selected : string)
            , (List.map tabs ~f:(fun tab -> tab.id, tab.title, tab.system_image, tab.role, fingerprint tab.content)
               : (string * string * string option * tab_role option * string) list) )]
        | Sidebar_split_node
            { title
            ; compact_top_bar_visible
            ; selected
            ; tabs
            ; on_select = _
            ; header_action
            ; actions
            ; bottom_search_placeholder
            ; bottom_search_text
            ; bottom_search_on_change = _
            ; bottom_action
            } ->
          [%sexp
            ( "sidebar-tabs"
            , (title : string option)
            , (compact_top_bar_visible : bool)
            , (selected : string)
            , (List.map tabs ~f:(fun tab -> tab.id, tab.title, tab.system_image, tab.role, fingerprint tab.content)
               : (string * string * string option * tab_role option * string) list)
            , (Option.map header_action ~f:(fun action -> action.id, action.title, action.system_image)
               : (string * string * string option) option)
            , (List.map actions ~f:(fun action -> action.id, action.title, action.system_image)
               : (string * string * string option) list)
            , (bottom_search_placeholder : string option)
            , (bottom_search_text : string)
            , (Option.map bottom_action ~f:(fun action -> action.id, action.title, action.system_image)
               : (string * string * string option) option) )]
        | Image_node image -> [%sexp "image", (image : image)]
        | Picker_node { title; selected; options; on_select = _ } ->
          [%sexp "picker", (title : string), (selected : string), (options : picker_option list)]
        | Photo_picker_node
            { title
            ; system_image
            ; is_title_visible
            ; is_enabled
            ; wants_payload
            ; selected
            ; on_select = _
            } ->
          [%sexp
            "photo-picker"
          , (title : string)
          , (system_image : string option)
          , (is_title_visible : bool)
          , (is_enabled : bool)
          , (wants_payload : bool)
          , (selected : string option)]
        | Share_link_node { title; url; is_enabled } ->
          [%sexp "share-link", (title : string), (url : string), (is_enabled : bool)]
        | File_exporter_node { title; is_enabled; export } ->
          [%sexp "file-exporter", (title : string), (is_enabled : bool), (export : file_export)]
        | File_importer_node { title; allowed_content_types; on_select = _ } ->
          [%sexp "file-importer", (title : string), (allowed_content_types : string list)]
        | Camera_capture_node { title; wants_payload; captured; on_capture = _ } ->
          [%sexp
            "camera-capture"
          , (title : string)
          , (wants_payload : bool)
          , (captured : string option)]
        | Custom_view_node { key; kind } ->
          [%sexp "custom-view", (key : string option), (kind : string)]
        | Modified_node _ -> assert false
      in
      Sexp.to_string ([%sexp (shape : Sexp.t), (modifiers : Sexp.t list)])
    ;;

    let rec mount ~schedule_event node =
      let node, modifiers = unwrap_modifiers node in
      let kind = backend_kind node in
      let t =
        { kind
        ; view = Backend.create kind
        ; fingerprint = fingerprint_parts node modifiers
        ; schedule_event
        ; children = []
        ; modifier_children = []
        }
      in
      patch_same_kind t node modifiers;
      t

    (* Skipping a patch also skips callback refresh. Only nodes whose callbacks are
       represented in their fingerprint can safely use this path. *)
    and can_skip_patch_when_unchanged = function
      | Text _ | Image_node _ | List_row_node _ | Progress_view_node _ | Custom_view_node _ -> true
      | Button_node _
      | Text_field_node _
      | Toggle_node _
      | Text_editor_node _
      | Stack_node _
      | Scroll_view_node _
      | List_node _
      | Navigation_stack_node _
      | Navigation_link_node _
      | Navigation_split_node _
      | Adaptive_layout_node _
      | Section_node _
      | Tab_view_node _
      | Sidebar_split_node _
      | Picker_node _
      | Photo_picker_node _
      | Share_link_node _
      | File_exporter_node _
      | File_importer_node _
      | Camera_capture_node _
      | Modified_node _ -> false

    and patch_same_kind t node modifiers =
      t.fingerprint <- fingerprint_parts node modifiers;
      let replace_children children =
        List.iter t.children ~f:(fun child -> destroy child.mounted);
        t.children <- children;
        Backend.set_children
          t.view
          ~keyed:(List.map children ~f:(fun child -> child.key))
          (List.map children ~f:(fun child -> child.mounted.view))
      in
      let rendered_modifiers = reconcile_modifiers t modifiers in
      (match node with
       | Text { text; attributes } ->
         Backend.set_text t.view text;
         Backend.set_text_attributes t.view attributes;
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         Backend.set_enabled t.view true;
         replace_children []
       | Button_node { title; system_image; subtitle; is_title_visible; is_enabled; on_click } ->
         Backend.set_text t.view title;
         Backend.set_system_image t.view system_image;
         Backend.set_button_subtitle t.view subtitle;
         Backend.set_title_visible t.view is_title_visible;
         Backend.set_enabled t.view is_enabled;
         Backend.set_on_click
           t.view
           (if is_enabled then Some (fun () -> t.schedule_event on_click) else None);
         Backend.set_on_change t.view None;
         replace_children []
       | Text_field_node { text; placeholder; style; is_secure; on_change; on_submit } ->
         Backend.set_text t.view text;
         Backend.set_placeholder t.view placeholder;
         Backend.set_text_field_style t.view style;
         Backend.set_text_field_secure t.view is_secure;
         Backend.set_on_click
           t.view
           (Option.map on_submit ~f:(fun on_submit ->
              fun () -> t.schedule_event on_submit));
         Backend.set_on_change
           t.view
           (Some (fun text -> t.schedule_event (on_change text)));
         replace_children []
       | Toggle_node { title; is_on; on_change } ->
         Backend.set_text t.view title;
         Backend.set_toggle t.view ~is_on ~on_change:(fun is_on ->
           t.schedule_event (on_change is_on));
         replace_children []
       | Text_editor_node { text; placeholder; on_change } ->
         Backend.set_text t.view text;
         Backend.set_placeholder t.view placeholder;
         Backend.set_on_click t.view None;
         Backend.set_on_change
           t.view
           (Some (fun text -> t.schedule_event (on_change text)));
         replace_children []
       | Progress_view_node { value } ->
         Backend.set_progress t.view ~value;
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         Backend.set_enabled t.view true;
         replace_children []
       | Stack_node { spacing; children; _ } ->
         Backend.set_spacing t.view spacing;
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         reconcile_positional t children
       | Scroll_view_node child ->
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         reconcile_positional t [ child ]
       | List_node rows ->
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         reconcile_keyed t rows
       | Navigation_stack_node children ->
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         reconcile_positional t children
       | Navigation_link_node { label; destination } ->
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         reconcile_positional t [ label; destination ]
       | Navigation_split_node { sidebar; content; detail } ->
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         reconcile_positional t [ sidebar; content; detail ]
       | Adaptive_layout_node { compact; regular } ->
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         reconcile_positional t [ compact; regular ]
       | Tab_view_node { selected; on_select; tabs } ->
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         reconcile_tabs t ~selected ~on_select tabs
       | Sidebar_split_node
           { title
           ; compact_top_bar_visible
           ; selected
           ; on_select
           ; tabs
           ; header_action
           ; actions
           ; bottom_search_placeholder
           ; bottom_search_text
           ; bottom_search_on_change
           ; bottom_action
           } ->
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         reconcile_tabs t ~selected ~on_select tabs;
         let render_action (action : sidebar_action) =
           { id = action.id
           ; title = action.title
           ; system_image = action.system_image
           ; on_click = (fun () -> t.schedule_event action.on_click)
           }
         in
         Backend.set_sidebar_shell
           t.view
           ~title
           ~compact_top_bar_visible
           ~header_action:(Option.map header_action ~f:render_action)
           ~actions:(List.map actions ~f:render_action)
           ~bottom_search_placeholder
           ~bottom_search_text
           ~bottom_search_on_change:
             (Option.map bottom_search_on_change ~f:(fun on_change ->
                fun text -> t.schedule_event (on_change text)))
           ~bottom_action:(Option.map bottom_action ~f:render_action)
       | Image_node { name; source } ->
         Backend.set_text t.view name;
         Backend.set_image_source t.view source;
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         replace_children []
       | List_row_node
           { title
           ; subtitle
           ; trailing_text
           ; leading_system_image
           ; preview_image_path
           ; content_style
           ; accessory
           ; title_strikethrough
           ; on_click
           ; leading_button
           ; swipe_actions
           ; menu_actions
           } ->
         Backend.set_list_row
           t.view
           ~title
           ~subtitle
           ~trailing_text
           ~leading_system_image
           ~preview_image_path
           ~content_style
           ~accessory
           ~title_strikethrough
           ~leading_button:
             (Option.map leading_button ~f:(fun leading_button ->
                { system_image = leading_button.system_image
                ; selected_system_image = leading_button.selected_system_image
                ; selected = leading_button.selected
                ; accessibility_label = leading_button.accessibility_label
                ; on_click = (fun () -> t.schedule_event leading_button.on_click)
                }))
           ~swipe_actions:
             (List.map swipe_actions ~f:(fun action ->
                { title = action.title
                ; system_image = action.system_image
                ; style = action.style
                ; on_click = (fun () -> t.schedule_event action.on_click)
                }))
           ~menu_actions:
             (List.map menu_actions ~f:(fun action ->
                { title = action.title
                ; system_image = action.system_image
                ; style = action.style
                ; on_click = (fun () -> t.schedule_event action.on_click)
                }));
         Backend.set_on_click
           t.view
           (Option.map on_click ~f:(fun on_click -> fun () -> t.schedule_event on_click));
         Backend.set_on_change t.view None;
         replace_children []
       | Section_node { key = _; title; children } ->
         Backend.set_section t.view ~title;
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         reconcile_positional t children
       | Picker_node { title; selected; on_select; options } ->
         Backend.set_picker
           t.view
           ~title
           ~selected
           ~on_select:(Some (fun id -> t.schedule_event (on_select id)))
           options;
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         replace_children []
       | Photo_picker_node
           { title; system_image; is_title_visible; is_enabled; wants_payload; selected; on_select } ->
         Backend.set_text t.view title;
         Backend.set_system_image t.view system_image;
         Backend.set_title_visible t.view is_title_visible;
         Backend.set_enabled t.view is_enabled;
         Backend.set_image_payload_mode t.view wants_payload;
         Backend.set_placeholder t.view selected;
         Backend.set_on_click t.view None;
         Backend.set_on_change
           t.view
           (if is_enabled
            then Some (fun image_id -> t.schedule_event (on_select image_id))
            else None);
         replace_children []
       | File_exporter_node { title; is_enabled; export } ->
         Backend.set_text t.view title;
         Backend.set_enabled t.view is_enabled;
         Backend.set_file_exporter t.view export;
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         replace_children []
       | Share_link_node share ->
         Backend.set_text t.view share.title;
         Backend.set_enabled t.view share.is_enabled;
         Backend.set_share_link t.view share;
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         replace_children []
       | File_importer_node { title; allowed_content_types; on_select } ->
         Backend.set_text t.view title;
         Backend.set_file_importer
           t.view
           ~allowed_content_types
           ~on_select:(Some (fun content -> t.schedule_event (on_select content)));
         Backend.set_on_click t.view None;
         replace_children []
       | Camera_capture_node { title; wants_payload; captured; on_capture } ->
         Backend.set_text t.view title;
         Backend.set_image_payload_mode t.view wants_payload;
         Backend.set_placeholder t.view captured;
         Backend.set_on_click t.view None;
         Backend.set_on_change
           t.view
           (Some (fun image_id -> t.schedule_event (on_capture image_id)));
         replace_children []
       | Custom_view_node _ ->
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         replace_children []
       | Modified_node _ -> assert false);
      Backend.set_modifiers
        t.view
        ~schedule_event:t.schedule_event
        rendered_modifiers

    and rendered_list_row_callbacks
      t
      ~on_click
      ~(leading_button : row_leading_button option)
      ~(swipe_actions : row_action list)
      ~(menu_actions : row_action list)
      =
      ( Option.map leading_button ~f:(fun leading_button ->
          { system_image = leading_button.system_image
          ; selected_system_image = leading_button.selected_system_image
          ; selected = leading_button.selected
          ; accessibility_label = leading_button.accessibility_label
          ; on_click = (fun () -> t.schedule_event leading_button.on_click)
          })
      , List.map swipe_actions ~f:(fun action ->
          { title = action.title
          ; system_image = action.system_image
          ; style = action.style
          ; on_click = (fun () -> t.schedule_event action.on_click)
          })
      , List.map menu_actions ~f:(fun action ->
          { title = action.title
          ; system_image = action.system_image
          ; style = action.style
          ; on_click = (fun () -> t.schedule_event action.on_click)
          })
      , Option.map on_click ~f:(fun on_click -> fun () -> t.schedule_event on_click)
      )

    and refresh_callbacks t node =
      match node with
      | List_row_node { on_click; leading_button; swipe_actions; menu_actions; _ } ->
        let leading_button, swipe_actions, menu_actions, on_click =
          rendered_list_row_callbacks
            t
            ~on_click
            ~leading_button
            ~swipe_actions
            ~menu_actions
        in
        Backend.refresh_list_row_callbacks
          t.view
          ~on_click
          ~leading_button
          ~swipe_actions
          ~menu_actions
      | _ -> ()

    and update t node =
      let node, modifiers = unwrap_modifiers node in
      let new_kind = backend_kind node in
      if equal_backend_kind t.kind new_kind
      then patch_same_kind t node modifiers
      else (
        destroy t;
        let replacement = mount ~schedule_event:t.schedule_event node in
        t.kind <- replacement.kind;
        t.view <- replacement.view;
        t.fingerprint <- replacement.fingerprint;
        t.children <- replacement.children;
        t.modifier_children <- replacement.modifier_children)

    and patch_child ~schedule_event existing node =
      let original_node = node in
      let base_node, modifiers = unwrap_modifiers node in
      let new_kind = backend_kind base_node in
      let next_fingerprint = fingerprint_parts base_node modifiers in
      match existing with
      | Some child
        when equal_backend_kind child.mounted.kind new_kind
             && can_skip_patch_when_unchanged base_node
             && String.equal child.mounted.fingerprint next_fingerprint ->
        refresh_callbacks child.mounted base_node;
        child.mounted
      | Some child when equal_backend_kind child.mounted.kind new_kind ->
        patch_same_kind child.mounted base_node modifiers;
        child.mounted
      | Some child ->
        destroy child.mounted;
        mount ~schedule_event original_node
      | None -> mount ~schedule_event original_node

    and reconcile_modifiers t modifiers =
      let old_by_index = Int.Table.create () in
      List.iter t.modifier_children ~f:(fun child ->
        Hashtbl.set old_by_index ~key:child.index ~data:child);
      let used = Int.Hash_set.create () in
      let next_modifier_children = ref [] in
      let rendered_modifiers =
        List.mapi modifiers ~f:(fun index modifier ->
          match modifier with
          | Padding insets -> Rendered_padding insets
          | Regular_material_panel { corner_radius } ->
            Rendered_regular_material_panel { corner_radius }
          | Frame frame -> Rendered_frame frame
          | Navigation_title title -> Rendered_navigation_title title
          | Searchable { text; on_change } -> Rendered_searchable { text; on_change }
          | Toolbar items -> Rendered_toolbar items
          | Tap_action { on_click } -> Rendered_tap_action { on_click }
          | Sheet { is_presented; content; on_dismiss } ->
            let content =
              if is_presented
              then (
                Hash_set.add used index;
                let existing =
                  Hashtbl.find old_by_index index
                  |> Option.map ~f:(fun child -> { key = None; mounted = child.mounted })
                in
                let mounted = patch_child ~schedule_event:t.schedule_event existing content in
                next_modifier_children := { index; mounted } :: !next_modifier_children;
                Some mounted.view)
              else None
            in
            Rendered_sheet { is_presented; content; on_dismiss }
          | Alert
              { is_presented
              ; title
              ; message
              ; text
              ; placeholder
              ; on_text_change
              ; actions
              ; on_dismiss
              } ->
            Rendered_alert
              { is_presented
              ; title
              ; message
              ; text
              ; placeholder
              ; on_text_change
              ; actions
              ; on_dismiss
              })
      in
      List.iter t.modifier_children ~f:(fun child ->
        if not (Hash_set.mem used child.index) then destroy child.mounted);
      t.modifier_children <- List.rev !next_modifier_children;
      rendered_modifiers

    and reconcile_positional t nodes =
      let rec loop old_children nodes =
        match old_children, nodes with
        | [], [] -> []
        | old_child :: old_tail, node :: node_tail ->
          { key = None; mounted = patch_child ~schedule_event:t.schedule_event (Some old_child) node }
          :: loop old_tail node_tail
        | [], node :: node_tail ->
          { key = None; mounted = mount ~schedule_event:t.schedule_event node } :: loop [] node_tail
        | old_child :: old_tail, [] ->
          destroy old_child.mounted;
          loop old_tail []
      in
      t.children <- loop t.children nodes;
      Backend.set_children
        t.view
        ~keyed:(List.map t.children ~f:(fun child -> child.key))
        (List.map t.children ~f:(fun child -> child.mounted.view))

    and reconcile_keyed t rows =
      let old_by_key = String.Table.create () in
      List.iter t.children ~f:(fun child ->
        Option.iter child.key ~f:(fun key -> Hashtbl.set old_by_key ~key ~data:child));
      let used = String.Hash_set.create () in
      let children =
        List.map rows ~f:(fun row ->
          Hash_set.add used row.key;
          let old_child = Hashtbl.find old_by_key row.key in
          { key = Some row.key
          ; mounted = patch_child ~schedule_event:t.schedule_event old_child row.node
          })
      in
      List.iter t.children ~f:(fun child ->
        match child.key with
        | Some key when Hash_set.mem used key -> ()
        | _ -> destroy child.mounted);
      t.children <- children;
      Backend.set_children
        t.view
        ~keyed:(List.map children ~f:(fun child -> child.key))
        (List.map children ~f:(fun child -> child.mounted.view))

    and reconcile_tabs t ~selected ~on_select tabs =
      let rows =
        List.map tabs ~f:(fun tab -> { key = tab.id; node = tab.content })
      in
      let rendered_tabs =
        List.map tabs ~f:(fun tab ->
          { id = tab.id
          ; title = tab.title
          ; system_image = tab.system_image
          ; role = tab.role
          })
      in
      reconcile_keyed t rows;
      Backend.set_tabs
        t.view
        ~selected
        ~on_select:(Some (fun id -> t.schedule_event (on_select id)))
        rendered_tabs
    ;;
  end
end

module App = struct
  module Make (Backend : Renderer.Backend) = struct
    module R = Renderer.Make (Backend)

    type t = (node, R.t) Bonsai_native.App_driver.t

    let create ?optimize ~time_source component =
      Bonsai_native.App_driver.create
        ?optimize
        ~time_source
        component
        ~render:(fun ~schedule_event node -> R.mount ~schedule_event node)
        ~update:(fun mounted ~schedule_event:_ node ->
          R.update mounted node;
          mounted)
    ;;

    let flush_and_render = Bonsai_native.App_driver.flush_and_render

    let view t = Option.map (Bonsai_native.App_driver.rendered t) ~f:R.view
  end
end

module For_testing = struct
  module Backend = struct
    module Stats = struct
      type t =
        { created : int
        ; destroyed : int
        ; mutations : int
        }
      [@@deriving sexp_of]
    end

    type view =
      { id : int
      ; kind : backend_kind
      ; mutable text : string option
      ; mutable system_image : string option
      ; mutable button_subtitle : string option
      ; mutable is_title_visible : bool
      ; mutable text_attributes : text_attributes
      ; mutable placeholder : string option
      ; mutable text_field_style : text_field_style
      ; mutable text_field_secure : bool
      ; mutable toggle_is_on : bool
      ; mutable progress_value : float option
      ; mutable children : (string option * view) list
      ; mutable is_enabled : bool
      ; mutable on_click : (unit -> unit) option
      ; mutable on_change : (string -> unit) option
      ; mutable on_toggle : (bool -> unit) option
      ; mutable selected_tab : string option
      ; mutable on_select_tab : (string -> unit) option
      ; mutable tabs : rendered_tab list
      ; mutable sidebar_title : string option
      ; mutable sidebar_compact_top_bar_visible : bool
      ; mutable sidebar_header_action : rendered_sidebar_action option
      ; mutable sidebar_actions : rendered_sidebar_action list
      ; mutable sidebar_bottom_search_placeholder : string option
      ; mutable sidebar_bottom_search_text : string
      ; mutable sidebar_bottom_search_on_change : (string -> unit) option
      ; mutable sidebar_bottom_action : rendered_sidebar_action option
      ; mutable section_title : string option
      ; mutable picker_title : string option
      ; mutable picker_selected : string option
      ; mutable on_select_picker : (string -> unit) option
      ; mutable picker_options : rendered_picker_option list
      ; mutable share_link : share_link option
      ; mutable file_export : file_export option
      ; mutable allowed_content_types : string list
      ; mutable on_import_file : (string -> unit) option
      ; mutable wants_image_payload : bool
      ; mutable image_source : image_source
      ; mutable list_row : string option
      ; mutable row_leading_button : rendered_row_leading_button option
      ; mutable row_actions : rendered_row_action list
      ; mutable row_menu_actions : rendered_row_action list
      ; mutable modifiers : view rendered_modifier list
      ; mutable schedule_event : (unit Effect.t -> unit) option
      }

    let next_id = ref 0
    let created = ref 0
    let destroyed = ref 0
    let mutations = ref 0

    let reset () =
      next_id := 0;
      created := 0;
      destroyed := 0;
      mutations := 0
    ;;

    let stats () : Stats.t =
      { created = !created; destroyed = !destroyed; mutations = !mutations }
    ;;

    let diff_stats (before : Stats.t) (after : Stats.t) : Stats.t =
      { created = after.created - before.created
      ; destroyed = after.destroyed - before.destroyed
      ; mutations = after.mutations - before.mutations
      }
    ;;

    let mutate () = Int.incr mutations

    let create kind =
      Int.incr next_id;
      Int.incr created;
      { id = !next_id
      ; kind
      ; text = None
      ; system_image = None
      ; button_subtitle = None
      ; is_title_visible = true
      ; text_attributes = default_text_attributes
      ; placeholder = None
      ; text_field_style = Rounded_border
      ; text_field_secure = false
      ; toggle_is_on = false
      ; progress_value = None
      ; children = []
      ; is_enabled = true
      ; on_click = None
      ; on_change = None
      ; on_toggle = None
      ; selected_tab = None
      ; on_select_tab = None
      ; tabs = []
      ; sidebar_title = None
      ; sidebar_compact_top_bar_visible = true
      ; sidebar_header_action = None
      ; sidebar_actions = []
      ; sidebar_bottom_search_placeholder = None
      ; sidebar_bottom_search_text = ""
      ; sidebar_bottom_search_on_change = None
      ; sidebar_bottom_action = None
      ; section_title = None
      ; picker_title = None
      ; picker_selected = None
      ; on_select_picker = None
      ; picker_options = []
      ; share_link = None
      ; file_export = None
      ; allowed_content_types = []
      ; on_import_file = None
      ; wants_image_payload = false
      ; image_source = System_image
      ; list_row = None
      ; row_leading_button = None
      ; row_actions = []
      ; row_menu_actions = []
      ; modifiers = []
      ; schedule_event = None
      }
    ;;

    let destroy _ = Int.incr destroyed

    let set_text view text =
      mutate ();
      view.text <- Some text
    ;;

    let set_system_image view system_image =
      mutate ();
      view.system_image <- system_image
    ;;

    let set_button_subtitle view subtitle =
      mutate ();
      view.button_subtitle <- subtitle
    ;;

    let set_title_visible view is_visible =
      mutate ();
      view.is_title_visible <- is_visible
    ;;

    let set_text_attributes view attributes =
      mutate ();
      view.text_attributes <- attributes
    ;;

    let set_placeholder view placeholder =
      mutate ();
      view.placeholder <- placeholder
    ;;

    let set_text_field_style view style =
      mutate ();
      view.text_field_style <- style
    ;;

    let set_text_field_secure view is_secure =
      mutate ();
      view.text_field_secure <- is_secure
    ;;

    let set_toggle view ~is_on ~on_change =
      mutate ();
      view.toggle_is_on <- is_on;
      view.on_toggle <- Some on_change
    ;;

    let set_progress view ~value =
      mutate ();
      view.progress_value <- Some value
    ;;

    let set_spacing _view _spacing = mutate ()

    let set_enabled view is_enabled =
      mutate ();
      view.is_enabled <- is_enabled
    ;;

    let set_children view ~keyed children =
      mutate ();
      view.children <- List.zip_exn keyed children
    ;;

    let set_tabs view ~selected ~on_select tabs =
      mutate ();
      view.selected_tab <- Some selected;
      view.on_select_tab <- on_select;
      view.tabs <- tabs
    ;;

    let set_sidebar_shell
      view
      ~title
      ~compact_top_bar_visible
      ~header_action
      ~actions
      ~bottom_search_placeholder
      ~bottom_search_text
      ~bottom_search_on_change
      ~bottom_action
      =
      mutate ();
      view.sidebar_title <- title;
      view.sidebar_compact_top_bar_visible <- compact_top_bar_visible;
      view.sidebar_header_action <- header_action;
      view.sidebar_actions <- actions;
      view.sidebar_bottom_search_placeholder <- bottom_search_placeholder;
      view.sidebar_bottom_search_text <- bottom_search_text;
      view.sidebar_bottom_search_on_change <- bottom_search_on_change;
      view.sidebar_bottom_action <- bottom_action
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
      ~(leading_button : rendered_row_leading_button option)
      ~(swipe_actions : rendered_row_action list)
      ~(menu_actions : rendered_row_action list)
      =
      mutate ();
      let leading =
        match leading_button with
        | None -> "leading=none"
        | Some leading ->
          sprintf
            "leading=%s:%s"
            leading.system_image
            (Bool.to_string leading.selected)
      in
      let actions =
        swipe_actions
        |> List.map ~f:(fun action ->
          let style =
            match action.style with
            | Default -> "default"
            | Destructive -> "destructive"
          in
          action.title ^ ":" ^ style)
        |> String.concat ~sep:","
      in
      let menu_actions_text =
        menu_actions
        |> List.map ~f:(fun action ->
          let style =
            match action.style with
            | Default -> "default"
            | Destructive -> "destructive"
          in
          action.title ^ ":" ^ style)
        |> String.concat ~sep:","
      in
      view.row_leading_button <- leading_button;
      view.row_actions <- swipe_actions;
      view.row_menu_actions <- menu_actions;
      view.list_row
      <- Some
           (sprintf
              " title=%s subtitle=%s trailing=%s style=%s accessory=%s strikethrough=%s leading-image=%s preview-image=%s %s actions=[%s] menu=[%s]"
              (Sexp.to_string_hum ([%sexp_of: string] title))
              (Sexp.to_string_hum ([%sexp_of: string option] subtitle))
              (Sexp.to_string_hum ([%sexp_of: string option] trailing_text))
              (Sexp.to_string_hum ([%sexp_of: list_row_content_style] content_style))
              (Sexp.to_string_hum ([%sexp_of: list_row_accessory] accessory))
              (Bool.to_string title_strikethrough)
              (Option.value leading_system_image ~default:"none")
              (Option.value preview_image_path ~default:"none")
              leading
              actions
              menu_actions_text)
    ;;

    let refresh_list_row_callbacks
      view
      ~on_click
      ~leading_button
      ~swipe_actions
      ~menu_actions
      =
      view.on_click <- on_click;
      view.on_change <- None;
      view.row_leading_button <- leading_button;
      view.row_actions <- swipe_actions;
      view.row_menu_actions <- menu_actions
    ;;

    let set_section view ~title =
      mutate ();
      view.section_title <- title
    ;;

    let set_picker view ~title ~selected ~on_select options =
      mutate ();
      view.picker_title <- Some title;
      view.picker_selected <- Some selected;
      view.on_select_picker <- on_select;
      view.picker_options <- options
    ;;

    let set_file_exporter view export =
      mutate ();
      view.file_export <- Some export
    ;;

    let set_share_link view share_link =
      mutate ();
      view.share_link <- Some share_link
    ;;

    let set_file_importer view ~allowed_content_types ~on_select =
      mutate ();
      view.allowed_content_types <- allowed_content_types;
      view.on_import_file <- on_select
    ;;

    let set_image_payload_mode view wants_payload =
      mutate ();
      view.wants_image_payload <- wants_payload
    ;;

    let set_image_source view source =
      mutate ();
      view.image_source <- source
    ;;

    let set_on_click view on_click =
      mutate ();
      view.on_click <- on_click
    ;;

    let set_on_change view on_change =
      mutate ();
      view.on_change <- on_change
    ;;

    let set_modifiers view ~schedule_event modifiers =
      mutate ();
      view.modifiers <- modifiers;
      view.schedule_event <- Some schedule_event;
      (match
         List.find_map modifiers ~f:(function
           | Rendered_tap_action { on_click } -> Some on_click
           | _ -> None)
       with
       | None -> ()
       | Some on_click -> view.on_click <- Some (fun () -> schedule_event on_click))
    ;;

    let kind_name = function
      | Label -> "label"
      | Button -> "button"
      | Text_field -> "text-field"
      | Text_editor -> "text-editor"
      | Toggle -> "toggle"
      | Stack Vertical -> "stack(vertical)"
      | Stack Horizontal -> "stack(horizontal)"
      | Scroll_view -> "scroll-view"
      | List -> "list"
      | Navigation_stack -> "navigation-stack"
      | Navigation_link -> "navigation-link"
      | Navigation_split -> "navigation-split"
      | Adaptive_layout -> "adaptive-layout"
      | Tab_view -> "tab-view"
      | Sidebar_split -> "sidebar-split"
      | Image -> "image"
      | List_row -> "list-row"
      | Section -> "section"
      | Picker -> "picker"
      | Photo_picker -> "photo-picker"
      | Share_link -> "share-link"
      | File_exporter -> "file-exporter"
      | File_importer -> "file-importer"
      | Camera_capture -> "camera-capture"
      | Progress_view -> "progress-view"
      | Custom_view kind -> "custom(" ^ kind ^ ")"
    ;;

    let modifier_name = function
      | Rendered_padding _ -> "padding"
      | Rendered_regular_material_panel _ -> "panel"
      | Rendered_frame _ -> "frame"
      | Rendered_navigation_title _ -> "navigation-title"
      | Rendered_searchable _ -> "searchable"
      | Rendered_toolbar _ -> "toolbar"
      | Rendered_tap_action _ -> "tap-action"
      | Rendered_sheet _ -> "sheet"
      | Rendered_alert _ -> "alert"
    ;;

    let rec show_lines ?key view ~indent =
      let spaces = String.make indent ' ' in
      let key =
        match key with
        | None -> ""
        | Some key -> " key=" ^ key
      in
      let text =
        match view.text with
        | None -> ""
        | Some text -> " text=" ^ Sexp.to_string_hum ([%sexp_of: string] text)
      in
      let enabled = if view.is_enabled then "" else " disabled" in
      let system_image =
        match view.system_image with
        | None -> ""
        | Some system_image -> " image=" ^ system_image
      in
      let button_subtitle =
        match view.kind, view.button_subtitle with
        | Button, Some subtitle ->
          " subtitle=" ^ Sexp.to_string_hum ([%sexp_of: string option] (Some subtitle))
        | _ -> ""
      in
      let title_visibility = if view.is_title_visible then "" else " title-hidden" in
      let text_attributes =
        if equal_text_attributes view.text_attributes default_text_attributes
        then ""
        else (
          let sexp = [%sexp_of: text_attributes] view.text_attributes in
          " text_attributes=" ^ Sexp.to_string_hum sexp)
      in
      let placeholder =
        match view.kind, view.placeholder with
        | Photo_picker, _ -> ""
        | _, None -> ""
        | _, Some placeholder ->
          " placeholder=" ^ Sexp.to_string_hum ([%sexp_of: string] placeholder)
      in
      let text_field_style =
        match view.kind with
        | Text_field ->
          " style=" ^ Sexp.to_string_hum ([%sexp_of: text_field_style] view.text_field_style)
        | _ -> ""
      in
      let text_field_secure =
        match view.kind, view.text_field_secure with
        | Text_field, true -> " secure"
        | _ -> ""
      in
      let toggle_selected =
        match view.kind with
        | Toggle -> " selected=" ^ Bool.to_string view.toggle_is_on
        | _ -> ""
      in
      let progress =
        match view.kind, view.progress_value with
        | Progress_view, Some value -> " progress=" ^ Float.to_string value
        | _ -> ""
      in
      let photo_picker =
        match view.kind with
        | Photo_picker ->
          " selected=" ^ Sexp.to_string_hum ([%sexp_of: string option] view.placeholder)
        | _ -> ""
      in
      let camera_capture =
        match view.kind with
        | Camera_capture ->
          " captured=" ^ Sexp.to_string_hum ([%sexp_of: string option] view.placeholder)
        | _ -> ""
      in
      let file_exporter =
        match view.file_export with
        | Some export ->
          sprintf
            " filename=%s content_type=%s"
            export.filename
            export.content_type
        | None -> ""
      in
      let share_link =
        match view.share_link with
        | Some share_link -> " url=" ^ share_link.url
        | None -> ""
      in
      let file_importer =
        match view.kind with
        | File_importer ->
          " allowed_content_types=["
          ^ String.concat ~sep:"," view.allowed_content_types
          ^ "]"
        | _ -> ""
      in
      let payload = if view.wants_image_payload then " payload" else "" in
      let image_source =
        match view.kind, view.image_source with
        | Image, File_image -> " source=file"
        | _ -> ""
      in
      let modifiers =
        match view.modifiers with
        | [] -> ""
        | modifiers ->
          " modifiers=["
          ^ String.concat ~sep:"," (List.map modifiers ~f:modifier_name)
          ^ "]"
      in
      let panel =
        match
          List.find_map view.modifiers ~f:(function
            | Rendered_regular_material_panel { corner_radius } -> Some corner_radius
            | _ -> None)
        with
        | None -> ""
        | Some corner_radius ->
          sprintf " panel=regular-material corner-radius=%g" corner_radius
      in
      let toolbar =
        match
          List.find_map view.modifiers ~f:(function
            | Rendered_toolbar items -> Some items
            | _ -> None)
        with
        | None -> ""
        | Some items ->
          let item_text =
            items
            |> List.map ~f:(fun (item : toolbar_item) ->
              let system_image =
                match item.system_image with
                | None -> ""
                | Some system_image -> ":image=" ^ system_image
              in
              let menu =
                match item.menu_actions with
                | [] -> ""
                | menu_actions ->
                  let action_text =
                    menu_actions
                    |> List.map ~f:(fun (action : toolbar_menu_action) ->
                      let system_image =
                        Option.value action.system_image ~default:"none"
                      in
                      let style =
                        match action.style with
                        | Default -> "default"
                        | Destructive -> "destructive"
                      in
                      action.title ^ ":" ^ system_image ^ ":" ^ style)
                    |> String.concat ~sep:","
                  in
                  ":menu=[" ^ action_text ^ "]"
              in
              sprintf
                "%s:%s:%s%s%s%s"
                item.id
                item.title
                (if item.is_enabled then "enabled" else "disabled")
                system_image
                (if item.is_title_visible then "" else ":title-hidden")
                menu)
            |> String.concat ~sep:","
          in
          " toolbar=[" ^ item_text ^ "]"
      in
      let navigation_title =
        match
          List.find_map view.modifiers ~f:(function
            | Rendered_navigation_title title -> Some title
            | _ -> None)
        with
        | None -> ""
        | Some title -> " navigation-title=" ^ title
      in
      let alert =
        match
          List.find_map view.modifiers ~f:(function
            | Rendered_alert
                { is_presented = true
                ; title
                ; message
                ; text
                ; placeholder
                ; actions
                ; _
                } ->
              Some (title, message, text, placeholder, actions)
            | _ -> None)
        with
        | None -> ""
        | Some (title, message, text, placeholder, actions) ->
          let role_name = function
            | Alert_default -> "default"
            | Alert_cancel -> "cancel"
            | Alert_destructive -> "destructive"
          in
          let action_text =
            actions
            |> List.map ~f:(fun (action : alert_action) ->
              sprintf
                "%s:%s:%s:%s"
                action.id
                action.title
                (role_name action.role)
                (if action.is_enabled then "enabled" else "disabled"))
            |> String.concat ~sep:","
          in
          " alert="
          ^ title
          ^ " message="
          ^ Sexp.to_string_hum ([%sexp_of: string option] message)
          ^ " text="
          ^ Sexp.to_string_hum ([%sexp_of: string option] text)
          ^ " placeholder="
          ^ Sexp.to_string_hum ([%sexp_of: string option] placeholder)
          ^ " actions=["
          ^ action_text
          ^ "]"
      in
      let selected =
        match view.selected_tab with
        | None -> ""
        | Some selected -> " selected=" ^ selected
      in
      let tab_name (tab : rendered_tab) =
        let image =
          match tab.system_image with
          | None -> ""
          | Some image -> ":" ^ image
        in
        let role =
          match tab.role with
          | None -> ""
          | Some Search -> ":search"
        in
        tab.id ^ ":" ^ tab.title ^ image ^ role
      in
      let tabs =
        match view.kind, view.tabs with
        | _, [] -> ""
        | Sidebar_split, tabs ->
          " routes=[" ^ String.concat ~sep:"," (List.map tabs ~f:tab_name) ^ "]"
        | _, tabs ->
          " tabs=[" ^ String.concat ~sep:"," (List.map tabs ~f:tab_name) ^ "]"
      in
      let compact_top_bar =
        match view.kind with
        | Sidebar_split when view.sidebar_compact_top_bar_visible ->
          let title = Option.value view.sidebar_title ~default:"Menu" in
          " sidebar-drawer=full-screen sidebar-padding=12 sidebar-header-title="
          ^ title
          ^ " sidebar-primary-row-height=52 sidebar-selected-corner-radius=12"
          ^ " sidebar-search-style=liquid-glass compact-top-bar=chatgpt-like-menu"
          ^ " header-button-chrome=liquid-glass"
        | Sidebar_split -> " compact-top-bar=hidden"
        | _ -> ""
      in
      let sidebar_action_name (action : rendered_sidebar_action) =
        let image =
          match action.system_image with
          | None -> ""
          | Some image -> ":" ^ image
        in
        action.id ^ ":" ^ action.title ^ image
      in
      let sidebar_header_action =
        match view.kind, view.sidebar_header_action with
        | Sidebar_split, Some action ->
          " sidebar-header-action=" ^ sidebar_action_name action
        | _ -> ""
      in
      let sidebar_actions =
        match view.kind, view.sidebar_actions with
        | Sidebar_split, (_ :: _ as actions) ->
          " sidebar-actions=["
          ^ String.concat ~sep:"," (List.map actions ~f:sidebar_action_name)
          ^ "]"
        | _ -> ""
      in
      let sidebar_bottom_search =
        match view.kind, view.sidebar_bottom_search_placeholder with
        | Sidebar_split, Some placeholder ->
          " sidebar-bottom-search="
          ^ placeholder
          ^ " text="
          ^ String.escaped view.sidebar_bottom_search_text
        | _ -> ""
      in
      let sidebar_bottom_action =
        match view.kind, view.sidebar_bottom_action with
        | Sidebar_split, Some action ->
          " sidebar-bottom-action=" ^ sidebar_action_name action
        | _ -> ""
      in
      let section =
        match view.section_title with
        | None -> ""
        | Some title -> " title=" ^ Sexp.to_string_hum ([%sexp_of: string] title)
      in
      let picker =
        match view.picker_title, view.picker_selected with
        | Some title, Some selected ->
          let option_name (option : rendered_picker_option) =
            option.id ^ ":" ^ option.title
          in
          sprintf
            " title=%s selected=%s options=[%s]"
            (Sexp.to_string_hum ([%sexp_of: string] title))
            selected
            (String.concat ~sep:"," (List.map view.picker_options ~f:option_name))
        | _ -> ""
      in
      let list_row = Option.value view.list_row ~default:"" in
      let child_lines =
        match view.kind, view.children with
        | Navigation_link, [ (_, label); _ ] ->
          (spaces ^ "  label:")
          :: show_lines label ~indent:(indent + 4)
        | _ ->
          List.concat_map view.children ~f:(fun (key, child) ->
            show_lines ?key child ~indent:(indent + 2))
      in
      let sheet_lines =
        List.concat_map view.modifiers ~f:(function
          | Rendered_sheet { is_presented = true; content = Some content; _ } ->
            (spaces ^ "  sheet:") :: show_lines content ~indent:(indent + 4)
          | _ -> [])
      in
      (spaces
       ^ kind_name view.kind
       ^ "#"
       ^ Int.to_string view.id
       ^ key
       ^ text
       ^ text_attributes
       ^ placeholder
       ^ text_field_style
       ^ text_field_secure
       ^ toggle_selected
       ^ progress
       ^ photo_picker
       ^ camera_capture
       ^ share_link
       ^ file_exporter
       ^ file_importer
       ^ payload
       ^ image_source
       ^ panel
       ^ system_image
       ^ button_subtitle
       ^ title_visibility
       ^ enabled
       ^ selected
       ^ tabs
       ^ compact_top_bar
       ^ sidebar_header_action
       ^ sidebar_actions
       ^ sidebar_bottom_search
       ^ sidebar_bottom_action
       ^ section
       ^ picker
       ^ list_row
       ^ modifiers
       ^ toolbar
       ^ navigation_title
       ^ alert)
      :: child_lines
      @ sheet_lines
    ;;

    let show view = String.concat ~sep:"\n" (show_lines view ~indent:0)

    let rec find_exn view ~path =
      match path with
      | [] -> view
      | index :: rest ->
        (match List.nth view.children index with
         | Some (_, child) -> find_exn child ~path:rest
         | None -> failwithf "No child at index %d" index ())
    ;;

    let show_at_path view ~path = show (find_exn view ~path)

    let click_exn view ~path =
      let view = find_exn view ~path in
      match view.on_click with
      | Some f -> f ()
      | None -> failwith "View has no click handler"
    ;;

    let change_text_exn view ~path ~text =
      let view = find_exn view ~path in
      view.text <- Some text;
      match view.on_change with
      | Some f -> f text
      | None -> failwith "View has no text-change handler"
    ;;

    let change_toggle_exn view ~path ~is_on =
      let view = find_exn view ~path in
      view.toggle_is_on <- is_on;
      match view.on_toggle with
      | Some f -> f is_on
      | None -> failwith "View has no toggle-change handler"
    ;;

    let submit_text_exn view ~path =
      let view = find_exn view ~path in
      match view.on_click with
      | Some f -> f ()
      | None -> failwith "View has no text-submit handler"
    ;;

    let select_photo_exn view ~path ~image_id =
      let view = find_exn view ~path in
      view.placeholder <- Some image_id;
      match view.on_change with
      | Some f -> f image_id
      | None -> failwith "View has no photo-selection handler"
    ;;

    let select_photo_payload_exn view ~path ~(payload : image_payload) =
      let view = find_exn view ~path in
      view.placeholder <- Some payload.id;
      match view.on_change with
      | Some f -> f (image_payload_to_event_text payload)
      | None -> failwith "View has no photo-selection handler"
    ;;

    let capture_camera_exn view ~path ~image_id =
      let view = find_exn view ~path in
      view.placeholder <- Some image_id;
      match view.on_change with
      | Some f -> f image_id
      | None -> failwith "View has no camera-capture handler"
    ;;

    let capture_camera_payload_exn view ~path ~(payload : image_payload) =
      let view = find_exn view ~path in
      view.placeholder <- Some payload.id;
      match view.on_change with
      | Some f -> f (image_payload_to_event_text payload)
      | None -> failwith "View has no camera-capture handler"
    ;;

    let import_file_exn view ~path ~content =
      let view = find_exn view ~path in
      match view.on_import_file with
      | Some f -> f content
      | None -> failwith "View has no file-import handler"
    ;;

    let presented_sheet_content_exn view =
      match
        List.find_map view.modifiers ~f:(function
          | Rendered_sheet { is_presented = true; content = Some content; _ } ->
            Some content
          | _ -> None)
      with
      | Some content -> content
      | None -> failwith "View has no presented sheet content"
    ;;

    let click_sheet_exn view ~path ~sheet_path =
      let view = find_exn view ~path in
      click_exn (presented_sheet_content_exn view) ~path:sheet_path
    ;;

    let import_sheet_file_exn view ~path ~sheet_path ~content =
      let view = find_exn view ~path in
      import_file_exn (presented_sheet_content_exn view) ~path:sheet_path ~content
    ;;

    let change_sheet_text_exn view ~path ~sheet_path ~text =
      let view = find_exn view ~path in
      change_text_exn (presented_sheet_content_exn view) ~path:sheet_path ~text
    ;;

    let change_sheet_toggle_exn view ~path ~sheet_path ~is_on =
      let view = find_exn view ~path in
      change_toggle_exn (presented_sheet_content_exn view) ~path:sheet_path ~is_on
    ;;

    let nested_sheet_host_exn view ~path ~host_path =
      let view = find_exn view ~path in
      presented_sheet_content_exn view |> find_exn ~path:host_path
    ;;

    let click_nested_sheet_exn view ~path ~host_path ~sheet_path =
      click_exn (presented_sheet_content_exn (nested_sheet_host_exn view ~path ~host_path)) ~path:sheet_path
    ;;

    let change_nested_sheet_text_exn view ~path ~host_path ~sheet_path ~text =
      change_text_exn
        (presented_sheet_content_exn (nested_sheet_host_exn view ~path ~host_path))
        ~path:sheet_path
        ~text
    ;;

    let select_sheet_photo_exn view ~path ~sheet_path ~image_id =
      let view = find_exn view ~path in
      select_photo_exn (presented_sheet_content_exn view) ~path:sheet_path ~image_id
    ;;

    let select_sheet_photo_payload_exn view ~path ~sheet_path ~payload =
      let view = find_exn view ~path in
      select_photo_payload_exn (presented_sheet_content_exn view) ~path:sheet_path ~payload
    ;;

    let capture_sheet_camera_exn view ~path ~sheet_path ~image_id =
      let view = find_exn view ~path in
      capture_camera_exn (presented_sheet_content_exn view) ~path:sheet_path ~image_id
    ;;

    let capture_sheet_camera_payload_exn view ~path ~sheet_path ~payload =
      let view = find_exn view ~path in
      capture_camera_payload_exn (presented_sheet_content_exn view) ~path:sheet_path ~payload
    ;;

    let schedule_event_exn view effect =
      match view.schedule_event with
      | Some schedule_event -> schedule_event effect
      | None -> failwith "View has no event scheduler"
    ;;

    let change_alert_text_exn view ~text =
      match
        List.find_map view.modifiers ~f:(function
          | Rendered_alert { is_presented = true; on_text_change = Some on_text_change; _ } ->
            Some on_text_change
          | _ -> None)
      with
      | Some on_text_change -> schedule_event_exn view (on_text_change text)
      | None -> failwith "Alert has no text-change handler"
    ;;

    let click_alert_action_exn view ~id =
      match
        List.find_map view.modifiers ~f:(function
          | Rendered_alert { is_presented = true; actions; _ } ->
            List.find actions ~f:(fun action -> String.equal action.id id)
          | _ -> None)
      with
      | Some action when action.is_enabled -> schedule_event_exn view action.on_click
      | Some _ -> failwithf "Alert action %S is disabled" id ()
      | None -> failwithf "Alert has no action with id %S" id ()
    ;;

    let change_nested_sheet_alert_text_exn view ~path ~host_path ~text =
      change_alert_text_exn (nested_sheet_host_exn view ~path ~host_path) ~text
    ;;

    let click_nested_sheet_alert_action_exn view ~path ~host_path ~id =
      click_alert_action_exn (nested_sheet_host_exn view ~path ~host_path) ~id
    ;;

    let change_search_exn view ~path ~text =
      let view = find_exn view ~path in
      match
        List.find_map view.modifiers ~f:(function
          | Rendered_searchable { on_change; _ } -> Some on_change
          | _ -> None)
      with
      | Some on_change -> schedule_event_exn view (on_change text)
      | None -> failwith "View has no searchable modifier"
    ;;

    let click_toolbar_item_exn view ~path ~id =
      let view = find_exn view ~path in
      match
        List.find_map view.modifiers ~f:(function
          | Rendered_toolbar items ->
            List.find items ~f:(fun item -> String.equal item.id id)
          | _ -> None)
      with
      | Some item ->
        if item.is_enabled
        then schedule_event_exn view item.on_click
        else failwithf "Toolbar item %S is disabled" id ()
      | None -> failwithf "View has no toolbar item with id %S" id ()
    ;;

    let click_sheet_toolbar_item_exn view ~path ~id =
      let view = find_exn view ~path in
      click_toolbar_item_exn (presented_sheet_content_exn view) ~path:[] ~id
    ;;

    let click_nested_sheet_toolbar_item_exn view ~path ~host_path ~id =
      click_toolbar_item_exn
        (presented_sheet_content_exn (nested_sheet_host_exn view ~path ~host_path))
        ~path:[]
        ~id
    ;;

    let click_toolbar_menu_action_exn view ~path ~id ~title =
      let view = find_exn view ~path in
      match
        List.find_map view.modifiers ~f:(function
          | Rendered_toolbar items ->
            Option.bind
              (List.find items ~f:(fun item -> String.equal item.id id))
              ~f:(fun item ->
                List.find item.menu_actions ~f:(fun action ->
                  String.equal action.title title))
          | _ -> None)
      with
      | Some action ->
        view.file_export <- action.file_export;
        schedule_event_exn view action.on_click
      | None ->
        failwithf
          "View has no toolbar menu action with id %S and title %S"
          id
          title
          ()
    ;;

    let dismiss_sheet_exn view ~path =
      let view = find_exn view ~path in
      match
        List.find_map view.modifiers ~f:(function
          | Rendered_sheet { is_presented = true; on_dismiss = Some on_dismiss; _ } ->
            Some on_dismiss
          | _ -> None)
      with
      | Some on_dismiss -> schedule_event_exn view on_dismiss
      | None -> failwith "View has no presented dismissible sheet"
    ;;

    let select_tab_exn view ~id =
      match view.on_select_tab with
      | Some f -> f id
      | None -> failwith "View has no tab selection handler"
    ;;

    let change_sidebar_bottom_search_exn view ~text =
      view.sidebar_bottom_search_text <- text;
      match view.sidebar_bottom_search_on_change with
      | Some f -> f text
      | None -> failwith "View has no sidebar bottom search handler"
    ;;

    let select_sidebar_route_exn view ~id =
      match view.on_select_tab with
      | Some f -> f id
      | None -> failwith "View has no sidebar route selection handler"
    ;;

    let click_sidebar_header_action_exn view ~id =
      match view.sidebar_header_action with
      | Some action when String.equal action.id id -> action.on_click ()
      | Some action ->
        failwithf
          "Expected sidebar header action id %s but found %s"
          id
          action.id
          ()
      | None -> failwith "View has no sidebar header action"
    ;;

    let click_sidebar_action_exn view ~id =
      match List.find view.sidebar_actions ~f:(fun action -> String.equal action.id id) with
      | Some action -> action.on_click ()
      | None -> failwithf "View has no sidebar action with id %s" id ()
    ;;

    let click_sidebar_bottom_action_exn view ~id =
      match view.sidebar_bottom_action with
      | Some action when String.equal action.id id -> action.on_click ()
      | Some action ->
        failwithf
          "Expected sidebar bottom action id %s but found %s"
          id
          action.id
          ()
      | None -> failwith "View has no sidebar bottom action"
    ;;

    let select_picker_exn view ~path ~id =
      let view = find_exn view ~path in
      match view.on_select_picker with
      | Some f -> f id
      | None -> failwith "View has no picker selection handler"
    ;;

    let select_sheet_picker_exn view ~path ~sheet_path ~id =
      let view = find_exn view ~path in
      select_picker_exn (presented_sheet_content_exn view) ~path:sheet_path ~id
    ;;

    let click_row_leading_exn view ~path =
      let view = find_exn view ~path in
      match view.row_leading_button with
      | Some leading -> leading.on_click ()
      | None -> failwith "View has no row leading button"
    ;;

    let click_row_action_exn view ~path ~title =
      let view = find_exn view ~path in
      match List.find view.row_actions ~f:(fun action -> String.equal action.title title) with
      | Some action -> action.on_click ()
      | None -> failwithf "View has no row action with title %S" title ()
    ;;

    let click_row_menu_action_exn view ~path ~title =
      let view = find_exn view ~path in
      match
        List.find view.row_menu_actions ~f:(fun action -> String.equal action.title title)
      with
      | Some action -> action.on_click ()
      | None -> failwithf "View has no row menu action with title %S" title ()
    ;;

    let click_sheet_row_menu_action_exn view ~path ~sheet_path ~title =
      let view = find_exn view ~path in
      click_row_menu_action_exn (presented_sheet_content_exn view) ~path:sheet_path ~title
    ;;

    let find_text_exn view ~path =
      let view = find_exn view ~path in
      match view.text with
      | Some text -> text
      | None -> failwith "View has no text"
    ;;
  end
end
