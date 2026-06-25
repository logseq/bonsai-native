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
[@@deriving sexp_of]

type file_export =
  { filename : string
  ; content_type : string
  ; content : string
  }

type share_link =
  { title : string
  ; url : string
  ; is_enabled : bool
  }

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
  ; is_enabled : bool
  ; on_click : unit Effect.t
  ; menu_actions : toolbar_menu_action list
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
[@@deriving sexp_of]

type text_weight =
  | Regular
  | Semibold
  | Bold
[@@deriving sexp_of]

type text_color =
  | Primary
  | Secondary
  | Tertiary
[@@deriving sexp_of]

type text_field_style =
  | Rounded_border
  | Pill
[@@deriving sexp_of]

type text_attributes =
  { style : text_style
  ; weight : text_weight
  ; color : text_color
  }
[@@deriving sexp_of]

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

type tab_role = Search [@@deriving sexp_of]

type tab
type sidebar_action

type rendered_tab =
  { id : string
  ; title : string
  ; system_image : string option
  ; role : tab_role option
  }
[@@deriving sexp_of]

type rendered_sidebar_action =
  { id : string
  ; title : string
  ; system_image : string option
  ; on_click : unit -> unit
  }

type node

val text
  :  ?style:text_style
  -> ?weight:text_weight
  -> ?color:text_color
  -> string
  -> node

val button : ?is_enabled:bool -> string -> on_click:unit Effect.t -> node
val text_field
  :  ?placeholder:string
  -> ?style:text_field_style
  -> ?is_secure:bool
  -> ?on_submit:unit Effect.t
  -> text:string
  -> on_change:(string -> unit Effect.t)
  -> unit
  -> node
val toggle : string -> is_on:bool -> on_change:(bool -> unit Effect.t) -> node
val text_editor
  :  ?placeholder:string
  -> text:string
  -> on_change:(string -> unit Effect.t)
  -> unit
  -> node

val vstack : ?spacing:float -> node list -> node
val hstack : ?spacing:float -> node list -> node
val scroll_view : node -> node
val list : 'a list -> key:('a -> string) -> row:('a -> node) -> node
val section : key:string -> ?title:string -> node list -> node
val section_key : node -> string
val picker_option : id:string -> title:string -> picker_option
val picker
  :  title:string
  -> selected:string
  -> on_select:(string -> unit Effect.t)
  -> picker_option list
  -> node
val navigation_stack : node list -> node
val navigation_split : sidebar:node -> content:node -> detail:node -> node
val adaptive_layout : compact:node -> regular:node -> node
val tab : id:string -> title:string -> ?system_image:string -> ?role:tab_role -> node -> tab
val tab_view : selected:string -> on_select:(string -> unit Effect.t) -> tab list -> node
val sidebar_action
  :  id:string
  -> title:string
  -> ?system_image:string
  -> on_click:unit Effect.t
  -> unit
  -> sidebar_action
val sidebar_split
  :  ?header_action:sidebar_action
  -> ?actions:sidebar_action list
  -> ?bottom_search_placeholder:string
  -> ?bottom_search_text:string
  -> ?bottom_search_on_change:(string -> unit Effect.t)
  -> ?bottom_action:sidebar_action
  -> selected:string
  -> on_select:(string -> unit Effect.t)
  -> tab list
  -> node
val image : string -> node
val photo_picker
  :  ?is_enabled:bool
  -> title:string
  -> ?selected:string
  -> on_select:(string -> unit Effect.t)
  -> unit
  -> node
val photo_picker_payload
  :  ?is_enabled:bool
  -> title:string
  -> ?selected:string
  -> on_select:(image_payload -> unit Effect.t)
  -> unit
  -> node
val file_exporter
  :  ?is_enabled:bool
  -> title:string
  -> filename:string
  -> content_type:string
  -> content:string
  -> unit
  -> node
val share_link : ?is_enabled:bool -> title:string -> url:string -> unit -> node
val file_importer
  :  title:string
  -> allowed_content_types:string list
  -> on_select:(string -> unit Effect.t)
  -> unit
  -> node
val camera_capture
  :  title:string
  -> ?captured:string
  -> on_capture:(string -> unit Effect.t)
  -> unit
  -> node
val camera_capture_payload
  :  title:string
  -> ?captured:string
  -> on_capture:(image_payload -> unit Effect.t)
  -> unit
  -> node
val list_row : list_row -> node
val custom_view : ?key:string -> kind:string -> unit -> node
val padding : ?insets:edge_insets -> node -> node
val frame : ?width:float -> ?height:float -> node -> node
val navigation_title : string -> node -> node
val searchable : text:string -> on_change:(string -> unit Effect.t) -> node -> node
val toolbar_item
  :  ?system_image:string
  -> ?is_enabled:bool
  -> ?menu_actions:toolbar_menu_action list
  -> id:string
  -> title:string
  -> on_click:unit Effect.t
  -> unit
  -> toolbar_item
val toolbar : toolbar_item list -> node -> node
val sheet
  :  is_presented:bool
  -> content:node
  -> ?on_dismiss:unit Effect.t
  -> node
  -> node

type axis =
  | Vertical
  | Horizontal
[@@deriving sexp_of]

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
  | Custom_view of string
[@@deriving sexp_of]

type modifier =
  | Padding of edge_insets
  | Frame of frame
  | Navigation_title of string
  | Searchable of
      { text : string
      ; on_change : string -> unit Effect.t
      }
  | Toolbar of toolbar_item list
  | Sheet of
      { is_presented : bool
      ; content : node
      ; on_dismiss : unit Effect.t option
      }

type 'view rendered_modifier =
  | Rendered_padding of edge_insets
  | Rendered_frame of frame
  | Rendered_navigation_title of string
  | Rendered_searchable of
      { text : string
      ; on_change : string -> unit Effect.t
      }
  | Rendered_toolbar of toolbar_item list
  | Rendered_sheet of
      { is_presented : bool
      ; content : 'view option
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

type rendered_picker_option =
  { id : string
  ; title : string
  }

module Renderer : sig
  module type Backend = sig
    type view

    val create : backend_kind -> view
    val destroy : view -> unit
    val set_text : view -> string -> unit
    val set_text_attributes : view -> text_attributes -> unit
    val set_placeholder : view -> string option -> unit
    val set_text_field_style : view -> text_field_style -> unit
    val set_text_field_secure : view -> bool -> unit
    val set_toggle : view -> is_on:bool -> on_change:(bool -> unit) -> unit
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
    val set_on_click : view -> (unit -> unit) option -> unit
    val set_on_change : view -> (string -> unit) option -> unit
    val set_enabled : view -> bool -> unit
    val set_modifiers
      :  view
      -> schedule_event:(unit Effect.t -> unit)
      -> view rendered_modifier list
      -> unit
  end

  module Make (Backend : Backend) : sig
    type t

    val mount : schedule_event:(unit Effect.t -> unit) -> node -> t
    val update : t -> node -> unit
    val view : t -> Backend.view
  end
end

module App : sig
  module Make (Backend : Renderer.Backend) : sig
    type t

    val create
      :  ?optimize:bool
      -> time_source:Bonsai.Time_source.t
      -> (Bonsai.graph -> node Bonsai.t)
      -> t

    val flush_and_render : t -> unit
    val view : t -> Backend.view option
  end
end

module For_testing : sig
  module Backend : sig
    include Renderer.Backend

    module Stats : sig
      type t =
        { created : int
        ; destroyed : int
        ; mutations : int
        }
      [@@deriving sexp_of]
    end

    val reset : unit -> unit
    val stats : unit -> Stats.t
    val diff_stats : Stats.t -> Stats.t -> Stats.t
    val show : view -> string
    val click_exn : view -> path:int list -> unit
    val change_text_exn : view -> path:int list -> text:string -> unit
    val change_toggle_exn : view -> path:int list -> is_on:bool -> unit
    val submit_text_exn : view -> path:int list -> unit
    val select_photo_exn : view -> path:int list -> image_id:string -> unit
    val capture_camera_exn : view -> path:int list -> image_id:string -> unit
    val select_photo_payload_exn
      :  view
      -> path:int list
      -> payload:image_payload
      -> unit
    val capture_camera_payload_exn
      :  view
      -> path:int list
      -> payload:image_payload
      -> unit
    val import_file_exn : view -> path:int list -> content:string -> unit
    val click_sheet_exn : view -> path:int list -> sheet_path:int list -> unit
    val select_sheet_picker_exn
      :  view
      -> path:int list
      -> sheet_path:int list
      -> id:string
      -> unit
    val import_sheet_file_exn
      :  view
      -> path:int list
      -> sheet_path:int list
      -> content:string
      -> unit
    val change_sheet_text_exn
      :  view
      -> path:int list
      -> sheet_path:int list
      -> text:string
      -> unit
    val change_sheet_toggle_exn
      :  view
      -> path:int list
      -> sheet_path:int list
      -> is_on:bool
      -> unit
    val click_sheet_toolbar_item_exn : view -> path:int list -> id:string -> unit
    val click_nested_sheet_exn
      :  view
      -> path:int list
      -> host_path:int list
      -> sheet_path:int list
      -> unit
    val change_nested_sheet_text_exn
      :  view
      -> path:int list
      -> host_path:int list
      -> sheet_path:int list
      -> text:string
      -> unit
    val select_sheet_photo_exn
      :  view
      -> path:int list
      -> sheet_path:int list
      -> image_id:string
      -> unit
    val capture_sheet_camera_exn
      :  view
      -> path:int list
      -> sheet_path:int list
      -> image_id:string
      -> unit
    val select_sheet_photo_payload_exn
      :  view
      -> path:int list
      -> sheet_path:int list
      -> payload:image_payload
      -> unit
    val capture_sheet_camera_payload_exn
      :  view
      -> path:int list
      -> sheet_path:int list
      -> payload:image_payload
      -> unit
    val change_search_exn : view -> path:int list -> text:string -> unit
    val click_toolbar_item_exn : view -> path:int list -> id:string -> unit
    val click_toolbar_menu_action_exn : view -> path:int list -> id:string -> title:string -> unit
    val dismiss_sheet_exn : view -> path:int list -> unit
    val select_tab_exn : view -> id:string -> unit
    val change_sidebar_bottom_search_exn : view -> text:string -> unit
    val select_sidebar_route_exn : view -> id:string -> unit
    val click_sidebar_header_action_exn : view -> id:string -> unit
    val click_sidebar_action_exn : view -> id:string -> unit
    val click_sidebar_bottom_action_exn : view -> id:string -> unit
    val select_picker_exn : view -> path:int list -> id:string -> unit
    val click_row_leading_exn : view -> path:int list -> unit
    val click_row_action_exn : view -> path:int list -> title:string -> unit
    val click_row_menu_action_exn : view -> path:int list -> title:string -> unit
    val find_text_exn : view -> path:int list -> string
  end
end
