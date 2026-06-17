open! Core

let app_by_id =
  let table = String.Table.create () in
  List.iter Android_demo_components.metadata ~f:(fun (id, _) ->
    Hashtbl.set
      table
      ~key:id
      ~data:
        (lazy
          (Bonsai_android.App.create
             ~time_source:(Bonsai.Time_source.create ~start:Time_ns.epoch)
             (Android_demo_components.component_by_id id))));
  table
;;

let app_for demo_id =
  let demo_id = Android_demo_components.normalize_id demo_id in
  Hashtbl.find_exn app_by_id demo_id |> Lazy.force
;;

let render demo_id = Bonsai_android.App.render_json (app_for demo_id)

let dispatch_click demo_id event_id =
  Bonsai_android.App.dispatch_click (app_for demo_id) event_id
;;

let dispatch_change demo_id event_id text =
  Bonsai_android.App.dispatch_change (app_for demo_id) event_id ~text
;;

let () =
  Callback.register "bonsai_android_render" render;
  Callback.register "bonsai_android_dispatch_click" dispatch_click;
  Callback.register "bonsai_android_dispatch_change" dispatch_change
;;
