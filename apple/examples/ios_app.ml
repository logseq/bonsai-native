open! Core

module Swiftui = Bonsai_apple_swiftui
module App = Swiftui.App

let mounted_apps = ref []
let window = ref None

let install_root_window ~time_source _app_delegate _application _launch_options =
  let app = App.create ~time_source Xxx.Ios_demo_app.component in
  App.flush_and_render app;
  let root = App.view app |> Option.value_exn in
  window := Some (Swiftui.window root);
  mounted_apps := [ app ];
  true
;;

let main ~time_source =
  Swiftui.run_application (install_root_window ~time_source)
;;

let () = main ~time_source:(Bonsai.Time_source.create ~start:Time_ns.epoch)
