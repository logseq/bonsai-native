open! Core

module Apple = Bonsai_apple

let component graph =
  let open Bonsai.Let_syntax in
  let count, set_count = Bonsai.state 0 graph in
  let%arr count and set_count in
  Apple.vstack
    [ Apple.text (Int.to_string count)
    ; Apple.button "Increment" ~on_click:(set_count (count + 1))
    ]
;;

let () = ignore component
