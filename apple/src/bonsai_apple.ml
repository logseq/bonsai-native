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

type text_attributes =
  { style : text_style
  ; weight : text_weight
  ; color : text_color
  }
[@@deriving sexp_of, equal]

type row_action_style =
  | Default
  | Destructive
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

type list_row =
  { title : string
  ; subtitle : string option
  ; trailing_text : string option
  ; title_strikethrough : bool
  ; leading_button : row_leading_button option
  ; swipe_actions : row_action list
  }

type tab_role = Search [@@deriving sexp_of, equal]

type rendered_tab =
  { id : string
  ; title : string
  ; system_image : string option
  ; role : tab_role option
  }
[@@deriving sexp_of, equal]

type axis =
  | Vertical
  | Horizontal
[@@deriving sexp_of, equal]

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
[@@deriving sexp_of, equal]

type node =
  | Text of
      { text : string
      ; attributes : text_attributes
      }
  | Button_node of
      { title : string
      ; on_click : unit Effect.t
      }
  | Text_field_node of
      { text : string
      ; placeholder : string option
      ; on_change : string -> unit Effect.t
      }
  | Stack_node of
      { axis : axis
      ; spacing : float option
      ; children : node list
      }
  | Scroll_view_node of node
  | List_node of keyed_node list
  | Navigation_stack_node of node list
  | Tab_view_node of
      { selected : string
      ; on_select : string -> unit Effect.t
      ; tabs : tab list
      }
  | Image_node of string
  | List_row_node of list_row
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

let default_text_attributes = { style = Body; weight = Regular; color = Primary }

let text ?(style = Body) ?(weight = Regular) ?(color = Primary) value =
  Text { text = value; attributes = { style; weight; color } }
;;

let button title ~on_click = Button_node { title; on_click }

let text_field ?placeholder ~text ~on_change () =
  Text_field_node { text; placeholder; on_change }
;;

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

let navigation_stack children = Navigation_stack_node children

let tab ~id ~title ?system_image ?role content =
  { id; title; system_image; role; content }
;;

let tab_view ~selected ~on_select tabs =
  let seen = String.Hash_set.create () in
  List.iter tabs ~f:(fun tab ->
    if Hash_set.mem seen tab.id then failwithf "duplicate Bonsai Apple tab id: %s" tab.id ();
    Hash_set.add seen tab.id);
  Tab_view_node { selected; on_select; tabs }
;;

let image name = Image_node name
let list_row row = List_row_node row
let custom_view ?key ~kind () = Custom_view_node { key; kind }

let default_insets = { top = 8.; leading = 8.; bottom = 8.; trailing = 8. }
let padding ?(insets = default_insets) node = Modified_node (Padding insets, node)
let frame ?width ?height node = Modified_node (Frame { width; height }, node)
let searchable ~text ~on_change node = Modified_node (Searchable { text; on_change }, node)
let toolbar_item ~id ~title ~on_click = { id; title; on_click }
let toolbar items node = Modified_node (Toolbar items, node)

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
  | Stack_node { axis; _ } -> Stack axis
  | Scroll_view_node _ -> Scroll_view
  | List_node _ -> List
  | Navigation_stack_node _ -> Navigation_stack
  | Tab_view_node _ -> Tab_view
  | Image_node _ -> Image
  | List_row_node _ -> List_row
  | Custom_view_node { kind; _ } -> Custom_view kind
  | Modified_node _ -> assert false
;;

module Renderer = struct
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

    let rec mount ~schedule_event node =
      let node, modifiers = unwrap_modifiers node in
      let kind = backend_kind node in
      let t =
        { kind
        ; view = Backend.create kind
        ; schedule_event
        ; children = []
        ; modifier_children = []
        }
      in
      patch_same_kind t node modifiers;
      t

    and patch_same_kind t node modifiers =
      let replace_children children =
        List.iter t.children ~f:(fun child -> destroy child.mounted);
        t.children <- children;
        Backend.set_children
          t.view
          ~keyed:(List.map children ~f:(fun child -> child.key))
          (List.map children ~f:(fun child -> child.mounted.view))
      in
      let rendered_modifiers = reconcile_modifiers t modifiers in
      Backend.set_modifiers
        t.view
        ~schedule_event:t.schedule_event
        rendered_modifiers;
      (match node with
       | Text { text; attributes } ->
         Backend.set_text t.view text;
         Backend.set_text_attributes t.view attributes;
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         replace_children []
       | Button_node { title; on_click } ->
         Backend.set_text t.view title;
         Backend.set_on_click t.view (Some (fun () -> t.schedule_event on_click));
         Backend.set_on_change t.view None;
         replace_children []
       | Text_field_node { text; placeholder; on_change } ->
         Backend.set_text t.view text;
         Backend.set_placeholder t.view placeholder;
         Backend.set_on_click t.view None;
         Backend.set_on_change
           t.view
           (Some (fun text -> t.schedule_event (on_change text)));
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
       | Tab_view_node { selected; on_select; tabs } ->
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         reconcile_tabs t ~selected ~on_select tabs
       | Image_node name ->
         Backend.set_text t.view name;
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         replace_children []
       | List_row_node
           { title
           ; subtitle
           ; trailing_text
           ; title_strikethrough
           ; leading_button
           ; swipe_actions
           } ->
         Backend.set_list_row
           t.view
           ~title
           ~subtitle
           ~trailing_text
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
                }));
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         replace_children []
       | Custom_view_node _ ->
         Backend.set_on_click t.view None;
         Backend.set_on_change t.view None;
         replace_children []
       | Modified_node _ -> assert false)

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
        t.children <- replacement.children;
        t.modifier_children <- replacement.modifier_children)

    and patch_child ~schedule_event existing node =
      let original_node = node in
      let base_node, modifiers = unwrap_modifiers node in
      let new_kind = backend_kind base_node in
      match existing with
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
          | Frame frame -> Rendered_frame frame
          | Searchable { text; on_change } -> Rendered_searchable { text; on_change }
          | Toolbar items -> Rendered_toolbar items
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
            Rendered_sheet { is_presented; content; on_dismiss })
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

    type t =
      { driver : node Bonsai_driver.t
      ; mutable mounted : R.t option
      }

    let create ?optimize ~time_source component =
      let instrumentation = Bonsai_driver.Instrumentation.default_for_test_handles () in
      let driver = Bonsai_driver.create ?optimize ~instrumentation ~time_source component in
      { driver; mounted = None }
    ;;

    let rec flush_and_render t =
      Bonsai_driver.flush t.driver;
      let node = Bonsai_driver.result t.driver in
      (match t.mounted with
       | None ->
         t.mounted
         <- Some (R.mount ~schedule_event:(schedule_event_and_render t) node)
       | Some mounted -> R.update mounted node);
      Bonsai_driver.trigger_lifecycles t.driver

    and schedule_event_and_render t event =
      Bonsai_driver.schedule_event t.driver event;
      flush_and_render t
    ;;

    let view t = Option.map t.mounted ~f:R.view
  end
end

module For_testing = struct
  module Backend = struct
    module Stats = struct
      type t =
        { created : int
        ; destroyed : int
        }
      [@@deriving sexp_of]
    end

    type view =
      { id : int
      ; kind : backend_kind
      ; mutable text : string option
      ; mutable text_attributes : text_attributes
      ; mutable placeholder : string option
      ; mutable children : (string option * view) list
      ; mutable on_click : (unit -> unit) option
      ; mutable on_change : (string -> unit) option
      ; mutable selected_tab : string option
      ; mutable on_select_tab : (string -> unit) option
      ; mutable tabs : rendered_tab list
      ; mutable list_row : string option
      ; mutable row_leading_button : rendered_row_leading_button option
      ; mutable row_actions : rendered_row_action list
      ; mutable modifiers : view rendered_modifier list
      ; mutable schedule_event : (unit Effect.t -> unit) option
      }

    let next_id = ref 0
    let created = ref 0
    let destroyed = ref 0

    let reset () =
      next_id := 0;
      created := 0;
      destroyed := 0
    ;;

    let stats () : Stats.t = { created = !created; destroyed = !destroyed }

    let diff_stats (before : Stats.t) (after : Stats.t) : Stats.t =
      { created = after.created - before.created
      ; destroyed = after.destroyed - before.destroyed
      }
    ;;

    let create kind =
      Int.incr next_id;
      Int.incr created;
      { id = !next_id
      ; kind
      ; text = None
      ; text_attributes = default_text_attributes
      ; placeholder = None
      ; children = []
      ; on_click = None
      ; on_change = None
      ; selected_tab = None
      ; on_select_tab = None
      ; tabs = []
      ; list_row = None
      ; row_leading_button = None
      ; row_actions = []
      ; modifiers = []
      ; schedule_event = None
      }
    ;;

    let destroy _ = Int.incr destroyed
    let set_text view text = view.text <- Some text
    let set_text_attributes view attributes = view.text_attributes <- attributes
    let set_placeholder view placeholder = view.placeholder <- placeholder
    let set_spacing _view _spacing = ()

    let set_children view ~keyed children =
      view.children <- List.zip_exn keyed children
    ;;

    let set_tabs view ~selected ~on_select tabs =
      view.selected_tab <- Some selected;
      view.on_select_tab <- on_select;
      view.tabs <- tabs
    ;;

    let set_list_row
      view
      ~title
      ~subtitle
      ~trailing_text
      ~title_strikethrough
      ~(leading_button : rendered_row_leading_button option)
      ~(swipe_actions : rendered_row_action list)
      =
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
      view.row_leading_button <- leading_button;
      view.row_actions <- swipe_actions;
      view.list_row
      <- Some
           (sprintf
              " title=%s subtitle=%s trailing=%s strikethrough=%s %s actions=[%s]"
              (Sexp.to_string_hum ([%sexp_of: string] title))
              (Sexp.to_string_hum ([%sexp_of: string option] subtitle))
              (Sexp.to_string_hum ([%sexp_of: string option] trailing_text))
              (Bool.to_string title_strikethrough)
              leading
              actions)
    ;;

    let set_on_click view on_click = view.on_click <- on_click
    let set_on_change view on_change = view.on_change <- on_change
    let set_modifiers view ~schedule_event modifiers =
      view.modifiers <- modifiers;
      view.schedule_event <- Some schedule_event
    ;;

    let kind_name = function
      | Label -> "label"
      | Button -> "button"
      | Text_field -> "text-field"
      | Stack Vertical -> "stack(vertical)"
      | Stack Horizontal -> "stack(horizontal)"
      | Scroll_view -> "scroll-view"
      | List -> "list"
      | Navigation_stack -> "navigation-stack"
      | Tab_view -> "tab-view"
      | Image -> "image"
      | List_row -> "list-row"
      | Custom_view kind -> "custom(" ^ kind ^ ")"
    ;;

    let modifier_name = function
      | Rendered_padding _ -> "padding"
      | Rendered_frame _ -> "frame"
      | Rendered_searchable _ -> "searchable"
      | Rendered_toolbar _ -> "toolbar"
      | Rendered_sheet _ -> "sheet"
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
      let text_attributes =
        if equal_text_attributes view.text_attributes default_text_attributes
        then ""
        else (
          let sexp = [%sexp_of: text_attributes] view.text_attributes in
          " text_attributes=" ^ Sexp.to_string_hum sexp)
      in
      let placeholder =
        match view.placeholder with
        | None -> ""
        | Some placeholder ->
          " placeholder=" ^ Sexp.to_string_hum ([%sexp_of: string] placeholder)
      in
      let modifiers =
        match view.modifiers with
        | [] -> ""
        | modifiers ->
          " modifiers=["
          ^ String.concat ~sep:"," (List.map modifiers ~f:modifier_name)
          ^ "]"
      in
      let selected =
        match view.selected_tab with
        | None -> ""
        | Some selected -> " selected=" ^ selected
      in
      let tabs =
        match view.tabs with
        | [] -> ""
        | tabs ->
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
          " tabs=[" ^ String.concat ~sep:"," (List.map tabs ~f:tab_name) ^ "]"
      in
      let list_row = Option.value view.list_row ~default:"" in
      let child_lines =
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
       ^ selected
       ^ tabs
       ^ list_row
       ^ modifiers)
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

    let schedule_event_exn view effect =
      match view.schedule_event with
      | Some schedule_event -> schedule_event effect
      | None -> failwith "View has no event scheduler"
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
      | Some item -> schedule_event_exn view item.on_click
      | None -> failwithf "View has no toolbar item with id %S" id ()
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

    let find_text_exn view ~path =
      let view = find_exn view ~path in
      match view.text with
      | Some text -> text
      | None -> failwith "View has no text"
    ;;
  end
end
