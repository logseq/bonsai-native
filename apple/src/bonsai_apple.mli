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

type toolbar_item =
  { id : string
  ; title : string
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

type text_attributes =
  { style : text_style
  ; weight : text_weight
  ; color : text_color
  }
[@@deriving sexp_of]

type row_action_style =
  | Default
  | Destructive
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

type list_row =
  { title : string
  ; subtitle : string option
  ; trailing_text : string option
  ; title_strikethrough : bool
  ; leading_button : row_leading_button option
  ; swipe_actions : row_action list
  }

type tab_role = Search [@@deriving sexp_of]

type tab

type rendered_tab =
  { id : string
  ; title : string
  ; system_image : string option
  ; role : tab_role option
  }
[@@deriving sexp_of]

type node

val text
  :  ?style:text_style
  -> ?weight:text_weight
  -> ?color:text_color
  -> string
  -> node

val button : string -> on_click:unit Effect.t -> node
val text_field
  :  ?placeholder:string
  -> text:string
  -> on_change:(string -> unit Effect.t)
  -> unit
  -> node

val vstack : ?spacing:float -> node list -> node
val hstack : ?spacing:float -> node list -> node
val scroll_view : node -> node
val list : 'a list -> key:('a -> string) -> row:('a -> node) -> node
val navigation_stack : node list -> node
val tab : id:string -> title:string -> ?system_image:string -> ?role:tab_role -> node -> tab
val tab_view : selected:string -> on_select:(string -> unit Effect.t) -> tab list -> node
val image : string -> node
val list_row : list_row -> node
val custom_view : ?key:string -> kind:string -> unit -> node
val padding : ?insets:edge_insets -> node -> node
val frame : ?width:float -> ?height:float -> node -> node
val searchable : text:string -> on_change:(string -> unit Effect.t) -> node -> node
val toolbar_item : id:string -> title:string -> on_click:unit Effect.t -> toolbar_item
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
  | Stack of axis
  | Scroll_view
  | List
  | Navigation_stack
  | Tab_view
  | Image
  | List_row
  | Custom_view of string
[@@deriving sexp_of]

type modifier =
  | Padding of edge_insets
  | Frame of frame
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

module Renderer : sig
  module type Backend = sig
    type view

    val create : backend_kind -> view
    val destroy : view -> unit
    val set_text : view -> string -> unit
    val set_text_attributes : view -> text_attributes -> unit
    val set_placeholder : view -> string option -> unit
    val set_spacing : view -> float option -> unit
    val set_children : view -> keyed:(string option) list -> view list -> unit
    val set_tabs
      :  view
      -> selected:string
      -> on_select:(string -> unit) option
      -> rendered_tab list
      -> unit
    val set_list_row
      :  view
      -> title:string
      -> subtitle:string option
      -> trailing_text:string option
      -> title_strikethrough:bool
      -> leading_button:rendered_row_leading_button option
      -> swipe_actions:rendered_row_action list
      -> unit
    val set_on_click : view -> (unit -> unit) option -> unit
    val set_on_change : view -> (string -> unit) option -> unit
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
        }
      [@@deriving sexp_of]
    end

    val reset : unit -> unit
    val stats : unit -> Stats.t
    val diff_stats : Stats.t -> Stats.t -> Stats.t
    val show : view -> string
    val click_exn : view -> path:int list -> unit
    val change_text_exn : view -> path:int list -> text:string -> unit
    val change_search_exn : view -> path:int list -> text:string -> unit
    val click_toolbar_item_exn : view -> path:int list -> id:string -> unit
    val dismiss_sheet_exn : view -> path:int list -> unit
    val select_tab_exn : view -> id:string -> unit
    val click_row_leading_exn : view -> path:int list -> unit
    val click_row_action_exn : view -> path:int list -> title:string -> unit
    val find_text_exn : view -> path:int list -> string
  end
end
