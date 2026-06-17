open! Core

let contains text ~substring = String.substr_index text ~pattern:substring |> Option.is_some

let assert_contains json substring =
  if not (contains json ~substring)
  then failwithf "expected JSON to contain %S, got: %s" substring json ()
;;

let () =
  let open Bonsai_android in
  let node =
    navigation_stack
      [ list
          [ "today"; "tasks"; "settings" ]
          ~key:Fn.id
          ~row:(fun title -> text title)
        |> searchable ~text:"ta" ~on_change:(fun _ -> Effect.Ignore)
        |> toolbar
             [ toolbar_item ~id:"add" ~title:"Add" ~on_click:Effect.Ignore
             ; toolbar_item ~id:"done" ~title:"Done" ~on_click:Effect.Ignore
             ]
        |> sheet
             ~is_presented:true
             ~content:(vstack [ text "Details"; image "star" ])
             ~on_dismiss:Effect.Ignore
      ; custom_view ~key:"native-map" ~kind:"map" ()
      ]
  in
  let bridge = Bridge.render ~schedule_event:ignore node in
  let json = Bridge.json bridge in
  List.iter
    [ "\"type\":\"navigationStack\""
    ; "\"type\":\"searchable\""
    ; "\"type\":\"toolbar\""
    ; "\"type\":\"sheet\""
    ; "\"type\":\"image\""
    ; "\"type\":\"customView\""
    ]
    ~f:(assert_contains json);
  print_endline json
;;
