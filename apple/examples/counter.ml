module Apple = Bonsai_apple

let component graph =
  let count, set_count = Apple.state graph ~key:"count" 0 in
  Apple.vstack
    [ Apple.text (Int.to_string count)
    ; Apple.button "Increment" ~on_click:(set_count (count + 1))
    ]
;;

let () = ignore component
