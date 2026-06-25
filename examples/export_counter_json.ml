let () =
  let demo_id =
    match Sys.argv with
    | [| _; demo_id |] -> demo_id
    | _ -> "counter"
  in
  let app = Bonsai_android.App.create (Android_demo_components.component_by_id demo_id) in
  print_endline (Bonsai_android.App.render_json app)
;;
