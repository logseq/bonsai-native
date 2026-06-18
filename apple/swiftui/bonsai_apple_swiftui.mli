open! Core

module Apple = Bonsai_apple

type application_delegate = nativeint
type application = nativeint
type launch_options = nativeint
type controller
type window

module Backend : Apple.Renderer.Backend
module Renderer : module type of Apple.Renderer.Make (Backend)
module App : module type of Apple.App.Make (Backend)

val run_application
  :  (application_delegate -> application -> launch_options -> bool)
  -> unit

val controller : Backend.view -> controller
val update_controller : controller -> Backend.view -> unit
val release_controller : controller -> unit
val window : Backend.view -> window
val release_window : window -> unit
