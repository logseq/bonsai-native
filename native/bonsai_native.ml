open! Core

module Effect = Bonsai.Effect

type edge_insets =
  { top : float
  ; start : float
  ; bottom : float
  ; end_ : float
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

type node =
  | Text of string
  | Button of
      { title : string
      ; on_click : unit Effect.t
      }
  | Text_field of
      { text : string
      ; placeholder : string option
      ; on_change : string -> unit Effect.t
      }
  | Stack of
      { axis : [ `Vertical | `Horizontal ]
      ; spacing : float option
      ; children : node list
      }
  | Scroll_view of node
  | List of keyed_node list
  | Navigation_stack of node list
  | Image of string
  | Custom_view of
      { key : string option
      ; kind : string
      }
  | Modified of modifier * node

and keyed_node =
  { key : string
  ; node : node
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

let text value = Text value
let button title ~on_click = Button { title; on_click }

let text_field ?placeholder ~text ~on_change () =
  Text_field { text; placeholder; on_change }
;;

let vstack ?spacing children = Stack { axis = `Vertical; spacing; children }
let hstack ?spacing children = Stack { axis = `Horizontal; spacing; children }
let scroll_view child = Scroll_view child
let navigation_stack children = Navigation_stack children
let image name = Image name
let custom_view ?key ~kind () = Custom_view { key; kind }

let list rows ~key ~row =
  let seen = String.Hash_set.create () in
  List
    (List.map rows ~f:(fun value ->
       let key = key value in
       if Hash_set.mem seen key then failwithf "duplicate Bonsai Native list key: %s" key ();
       Hash_set.add seen key;
       { key; node = row value }))
;;

let default_insets = { top = 8.; start = 8.; bottom = 8.; end_ = 8. }
let padding ?(insets = default_insets) node = Modified (Padding insets, node)
let frame ?width ?height node = Modified (Frame { width; height }, node)

let searchable ~text ~on_change node = Modified (Searchable { text; on_change }, node)
let toolbar_item ~id ~title ~on_click = { id; title; on_click }
let toolbar items node = Modified (Toolbar items, node)

let sheet ~is_presented ~content ?on_dismiss node =
  Modified (Sheet { is_presented; content; on_dismiss }, node)
;;

module Bridge = struct
  type event_handler =
    | Click of unit Effect.t
    | Change of (string -> unit Effect.t)

  type t =
    { json : string
    ; schedule_event : unit Effect.t -> unit
    ; handlers : event_handler Int.Table.t
    }

  let json t = t.json

  let escape_json value =
    let buffer = Buffer.create (String.length value) in
    String.iter value ~f:(function
      | '"' -> Buffer.add_string buffer "\\\""
      | '\\' -> Buffer.add_string buffer "\\\\"
      | '\n' -> Buffer.add_string buffer "\\n"
      | '\r' -> Buffer.add_string buffer "\\r"
      | '\t' -> Buffer.add_string buffer "\\t"
      | char -> Buffer.add_char buffer char);
    Buffer.contents buffer
  ;;

  let string value = sprintf "\"%s\"" (escape_json value)
  let field name value = sprintf "\"%s\":%s" name value
  let object_ fields = sprintf "{%s}" (String.concat fields ~sep:",")
  let array values = sprintf "[%s]" (String.concat values ~sep:",")
  let bool value = if value then "true" else "false"

  let float value =
    let value = Float.to_string value in
    if String.is_suffix value ~suffix:"." then value ^ "0" else value
  ;;

  let option_float = function
    | None -> "null"
    | Some value -> float value
  ;;

  let rec unwrap_modifiers node =
    match node with
    | Modified (modifier, node) ->
      let node, modifiers = unwrap_modifiers node in
      node, modifier :: modifiers
    | node -> node, []
  ;;

  let render ~schedule_event node =
    let next_event_id = ref 0 in
    let handlers = Int.Table.create () in
    let register handler =
      Int.incr next_event_id;
      let id = !next_event_id in
      Hashtbl.set handlers ~key:id ~data:handler;
      id
    in
    let rec render_node node =
      let node, modifiers = unwrap_modifiers node in
      let modifier_field = field "modifiers" (array (List.map modifiers ~f:render_modifier)) in
      match node with
      | Text value ->
        object_ [ field "type" (string "text"); field "text" (string value); modifier_field ]
      | Button { title; on_click } ->
        let event_id = register (Click on_click) in
        object_
          [ field "type" (string "button")
          ; field "text" (string title)
          ; field "eventId" (Int.to_string event_id)
          ; modifier_field
          ]
      | Text_field { text; placeholder; on_change } ->
        let event_id = register (Change on_change) in
        object_
          [ field "type" (string "textField")
          ; field "text" (string text)
          ; field "placeholder" (Option.value_map placeholder ~default:"null" ~f:string)
          ; field "eventId" (Int.to_string event_id)
          ; modifier_field
          ]
      | Stack { axis; spacing; children } ->
        object_
          [ field
              "type"
              (string
                 (match axis with
                  | `Vertical -> "vstack"
                  | `Horizontal -> "hstack"))
          ; field "spacing" (option_float spacing)
          ; field "children" (array (List.map children ~f:render_node))
          ; modifier_field
          ]
      | Scroll_view child ->
        object_
          [ field "type" (string "scrollView")
          ; field "child" (render_node child)
          ; modifier_field
          ]
      | List rows ->
        object_
          [ field "type" (string "list")
          ; field
              "rows"
              (array
                 (List.map rows ~f:(fun { key; node } ->
                    object_ [ field "key" (string key); field "node" (render_node node) ])))
          ; modifier_field
          ]
      | Navigation_stack children ->
        object_
          [ field "type" (string "navigationStack")
          ; field "children" (array (List.map children ~f:render_node))
          ; modifier_field
          ]
      | Image name ->
        object_
          [ field "type" (string "image"); field "name" (string name); modifier_field ]
      | Custom_view { key; kind } ->
        object_
          [ field "type" (string "customView")
          ; field "kind" (string kind)
          ; field "key" (Option.value_map key ~default:"null" ~f:string)
          ; modifier_field
          ]
      | Modified _ -> assert false
    and render_modifier = function
      | Padding { top; start; bottom; end_ } ->
        object_
          [ field "type" (string "padding")
          ; field "top" (float top)
          ; field "start" (float start)
          ; field "bottom" (float bottom)
          ; field "end" (float end_)
          ]
      | Frame { width; height } ->
        object_
          [ field "type" (string "frame")
          ; field "width" (option_float width)
          ; field "height" (option_float height)
          ]
      | Searchable { text; on_change } ->
        let event_id = register (Change on_change) in
        object_
          [ field "type" (string "searchable")
          ; field "text" (string text)
          ; field "eventId" (Int.to_string event_id)
          ]
      | Toolbar items ->
        object_
          [ field "type" (string "toolbar")
          ; field
              "items"
              (array
                 (List.map items ~f:(fun { id; title; on_click } ->
                    let event_id = register (Click on_click) in
                    object_
                      [ field "id" (string id)
                      ; field "title" (string title)
                      ; field "eventId" (Int.to_string event_id)
                      ])))
          ]
      | Sheet { is_presented; content; on_dismiss } ->
        object_
          [ field "type" (string "sheet")
          ; field "isPresented" (bool is_presented)
          ; field "content" (render_node content)
          ; field
              "dismissEventId"
              (Option.value_map
                 on_dismiss
                 ~default:"null"
                 ~f:(fun effect -> register (Click effect) |> Int.to_string))
          ]
    in
    { json = render_node node; schedule_event; handlers }
  ;;

  let dispatch_click t id =
    match Hashtbl.find t.handlers id with
    | Some (Click effect) -> t.schedule_event effect
    | Some (Change _) | None -> ()
  ;;

  let dispatch_change t id ~text =
    match Hashtbl.find t.handlers id with
    | Some (Change effect) -> t.schedule_event (effect text)
    | Some (Click _) | None -> ()
  ;;
end

module App = struct
  type t =
    { driver : node Bonsai_driver.t
    ; mutable bridge : Bridge.t option
    }

  let create ?optimize ~time_source component =
    let instrumentation = Bonsai_driver.Instrumentation.default_for_test_handles () in
    let driver = Bonsai_driver.create ?optimize ~instrumentation ~time_source component in
    { driver; bridge = None }
  ;;

  let flush t =
    Bonsai_driver.flush t.driver;
    let node = Bonsai_driver.result t.driver in
    t.bridge
    <- Some
         (Bridge.render
            ~schedule_event:(fun event -> Bonsai_driver.schedule_event t.driver event)
            node);
    Bonsai_driver.trigger_lifecycles t.driver
  ;;

  let render_json t =
    flush t;
    t.bridge |> Option.value_exn |> Bridge.json
  ;;

  let dispatch_click t event_id =
    Option.iter t.bridge ~f:(fun bridge -> Bridge.dispatch_click bridge event_id)
  ;;

  let dispatch_change t event_id ~text =
    Option.iter t.bridge ~f:(fun bridge -> Bridge.dispatch_change bridge event_id ~text)
  ;;
end
