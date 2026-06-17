open! Core

let () =
  let demo_id =
    match Sys.get_argv () with
    | [| _; demo_id |] -> demo_id
    | _ -> "counter"
  in
  let app =
    Bonsai_android.App.create
      ~time_source:(Bonsai.Time_source.create ~start:Time_ns.epoch)
      (Android_demo_components.component_by_id demo_id)
  in
  print_endline (Bonsai_android.App.render_json app)
;;
