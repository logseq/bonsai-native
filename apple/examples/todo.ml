module Apple = Bonsai_apple

type todo =
  { id : string
  ; title : string
  }

let component graph =
  let input, set_input = Apple.state graph ~key:"input" "" in
  let todos, set_todos = Apple.state graph ~key:"todos" [] in
  let add =
    if input = ""
    then Apple.Effect.ignore
    else set_todos ({ id = input; title = input } :: todos)
  in
  Apple.vstack
    ~spacing:12.
    [ (Apple.hstack
         ~spacing:8.
         [ Apple.text_field ~text:input ~placeholder:"New task" ~on_change:set_input ()
           |> Apple.frame ~width:260.
        ; Apple.button "Add" ~on_click:add
        ]
       |> Apple.frame ~width:360. ~height:44.)
    ; (Apple.list todos ~key:(fun todo -> todo.id) ~row:(fun todo -> Apple.text todo.title)
       |> Apple.frame ~width:360. ~height:620.)
    ]
;;

let () = ignore component
