open! Core

module Apple = Bonsai_apple

let component _graph =
  Bonsai.return
    (Apple.navigation_stack
       [ Apple.list
           [ "Today"; "Tasks"; "Settings" ]
           ~key:Fn.id
           ~row:(fun title -> Apple.text title)
       ])
;;

let () = ignore component
