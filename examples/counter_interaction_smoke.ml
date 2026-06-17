open! Core

let contains text ~substring = String.substr_index text ~pattern:substring |> Option.is_some

let () =
  let app =
    Bonsai_android.App.create
      ~time_source:(Bonsai.Time_source.create ~start:Time_ns.epoch)
      Counter_component.component
  in
  let before = Bonsai_android.App.render_json app in
  if not (contains before ~substring:"Count: 0")
  then failwithf "expected initial render to contain Count: 0, got: %s" before ();
  Bonsai_android.App.dispatch_click app 1;
  let after = Bonsai_android.App.render_json app in
  if not (contains after ~substring:"Count: 1")
  then failwithf "expected click dispatch to contain Count: 1, got: %s" after ();
  print_endline after
;;
