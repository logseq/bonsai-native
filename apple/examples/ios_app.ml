open! Core
open UIKit
open Runtime

module App = Bonsai_apple_uikit.App

let mounted_apps = ref []
let window = ref None
let centered_controller_counter = ref 0

let nsstring value = new_string value

let nsarray values =
  let array = NSMutableArray.self |> NSMutableArrayClass.arrayWithCapacity (List.length values) in
  List.iter values ~f:(fun value -> NSMutableArray.addObject value array);
  array
;;

let flexible_size_mask = _UIViewAutoresizingFlexibleWidth lor _UIViewAutoresizingFlexibleHeight

let flexible_center_mask =
  _UIViewAutoresizingFlexibleTopMargin
  lor _UIViewAutoresizingFlexibleBottomMargin
  lor _UIViewAutoresizingFlexibleLeftMargin
  lor _UIViewAutoresizingFlexibleRightMargin
;;

let max_float a b = if Float.(a > b) then a else b
let min_float a b = if Float.(a < b) then a else b

let center_root_view ~root_view ~host_view =
  UIView.layoutIfNeeded root_view;
  let host_size = UIView.bounds host_view |> CoreGraphics.CGRect.size in
  let host_width = CoreGraphics.CGSize.width host_size in
  let host_height = CoreGraphics.CGSize.height host_size in
  let fitting_size = UIView.sizeThatFits host_size root_view in
  let content_width =
    CoreGraphics.CGSize.width fitting_size |> max_float 160. |> min_float host_width
  in
  let content_height = CoreGraphics.CGSize.height fitting_size |> max_float 96. in
  UIView.setFrame
    (CoreGraphics.CGRect.make
       ~x:((host_width -. content_width) /. 2.)
       ~y:((host_height -. content_height) /. 2.)
       ~width:content_width
       ~height:content_height)
    root_view;
  UIView.layoutIfNeeded root_view
;;

let layout_root_view_in_safe_area ~root_view ~host_view =
  let bounds = UIView.bounds host_view in
  let size = CoreGraphics.CGRect.size bounds in
  let insets = UIView.safeAreaInsets host_view in
  let x = UIEdgeInsets.left insets in
  let y = UIEdgeInsets.top insets in
  let width = CoreGraphics.CGSize.width size -. x -. UIEdgeInsets.right insets in
  let height = CoreGraphics.CGSize.height size -. y -. UIEdgeInsets.bottom insets in
  UIView.setFrame (CoreGraphics.CGRect.make ~x ~y ~width ~height) root_view;
  UIView.layoutIfNeeded root_view
;;

let layout_controller ~root_view ~layout =
  centered_controller_counter := !centered_controller_counter + 1;
  let class_name =
    "BonsaiNativeTabController" ^ Int.to_string !centered_controller_counter
  in
  let _ =
    Class.define
      class_name
      ~superclass:UIViewController.self
      ~methods:
        [ (UIViewControllerMethods.viewDidLayoutSubviews
           @@ fun self _cmd ->
           let host_view = UIViewController.view self in
           layout ~root_view ~host_view)
        ]
  in
  Objc.get_class class_name |> alloc |> init
;;

let install_tab_item ~title ~icon controller =
  let title = nsstring title in
  let image = UIImage.self |> UIImageClass.systemImageNamed (nsstring icon) in
  let item =
    UITabBarItem.self |> alloc |> UITabBarItem.initWithTitle title ~image ~selectedImage:nil
  in
  UIViewController.setTitle title controller;
  UIViewController.setTabBarItem item controller
;;

let create_tab ~time_source ~screen_bounds ~background_color ~title ~icon ~centered component =
  let app = App.create ~time_source component in
  App.flush_and_render app;
  let controller =
    match App.view app with
    | None -> UIViewController.self |> alloc |> init
    | Some root ->
      let root_view = Bonsai_apple_uikit.native root in
      let controller =
        layout_controller
          ~root_view
          ~layout:(if centered then center_root_view else layout_root_view_in_safe_area)
      in
      let host_view = UIView.self |> alloc |> UIView.initWithFrame screen_bounds in
      UIView.setBackgroundColor background_color host_view;
      UIView.setAutoresizingMask flexible_size_mask host_view;
      UIViewController.setView host_view controller;
      UIView.setBackgroundColor background_color root_view;
      if centered
      then (
        UIStackView.setAlignment _UIStackViewAlignmentCenter root_view;
        UIView.setAutoresizingMask flexible_center_mask root_view;
        UIView.addSubview root_view host_view;
        center_root_view ~root_view ~host_view)
      else (
        UIView.setAutoresizingMask flexible_size_mask root_view;
        UIView.addSubview root_view host_view);
      controller
  in
  install_tab_item ~title ~icon controller;
  app, controller
;;

let create_tabs ~time_source ~screen_bounds ~background_color =
  [ create_tab
      ~time_source
      ~screen_bounds
      ~background_color
      ~title:"Counter"
      ~icon:"plus.circle"
      ~centered:true
      Counter.component
  ; create_tab
      ~time_source
      ~screen_bounds
      ~background_color
      ~title:"Todo"
      ~icon:"checklist"
      ~centered:false
      Todo.component
  ; create_tab
      ~time_source
      ~screen_bounds
      ~background_color
      ~title:"Search"
      ~icon:"magnifyingglass"
      ~centered:false
      Searchable_list.component
    ]
;;

let initial_tab_index () =
  let initial_tab =
    match Sys.getenv "BONSAI_NATIVE_INITIAL_TAB" with
    | Some value -> Some value
    | None -> Sys.getenv "BONSAI_APPLE_INITIAL_TAB"
  in
  match initial_tab |> Option.bind ~f:Int.of_string_opt with
  | Some index when index >= 0 && index <= 2 -> index
  | _ -> 0
;;

let install_root_view ~time_source app_delegate _cmd _application _launch_options =
  let screen_bounds = UIScreen.self |> UIScreenClass.mainScreen |> UIScreen.bounds in
  let background_color = UIColor.self |> UIColorClass.systemBackgroundColor in
  let win = UIWindow.self |> alloc |> UIWindow.initWithFrame screen_bounds in
  UIView.setBackgroundColor background_color win;
  let tab_controller = UITabBarController.self |> alloc |> init in
  let tabs = create_tabs ~time_source ~screen_bounds ~background_color in
  mounted_apps := List.map tabs ~f:fst;
  UITabBarController.setViewControllers (tabs |> List.map ~f:snd |> nsarray) tab_controller;
  UITabBarController.setSelectedIndex (initial_tab_index ()) tab_controller;
  UIWindow.setRootViewController tab_controller win;
  UIWindow.makeKeyAndVisible win;
  window := Some win;
  ignore app_delegate;
  true
;;

let main ~time_source =
  let _ =
    Class.define
      "BonsaiNativeDemosAppDelegate"
      ~superclass:UIResponder.self
      ~methods:
        [ (UIApplicationDelegate.application'didFinishLaunchingWithOptions'
           @@ install_root_view ~time_source)
        ]
  in
  _UIApplicationMain
    0
    (Objc.from_voidp Objc.string Objc.null)
    nil
    (new_string "BonsaiNativeDemosAppDelegate")
  |> exit
;;

let () = main ~time_source:(Bonsai.Time_source.create ~start:Time_ns.epoch)
