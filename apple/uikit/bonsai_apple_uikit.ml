open! Core
open UIKit
open Objc
open Runtime

module Apple = Bonsai_apple

type view =
  { native : objc_object structure ptr
  ; controller : objc_object structure ptr
  ; kind : Apple.backend_kind
  ; mutable children : view list
  ; table_state : table_state option
  ; mutable data_source : objc_object structure ptr option
  ; mutable click_action : objc_object structure ptr option
  ; mutable click_handler : (unit -> unit) option
  ; mutable click_handler_block : Obj.t option
  ; mutable change_action : objc_object structure ptr option
  ; mutable change_handler : (string -> unit) option
  ; mutable change_handler_block : Obj.t option
  ; mutable search_controller : objc_object structure ptr option
  ; mutable search_delegate : objc_object structure ptr option
  ; mutable tab_items : Apple.rendered_tab list
  ; mutable tab_select_handler : (string -> unit) option
  ; mutable tab_delegate : objc_object structure ptr option
  ; mutable toolbar_actions : objc_object structure ptr list
  ; mutable toolbar_handler_blocks : Obj.t list
  ; mutable presented_sheet : objc_object structure ptr option
  ; mutable frame_constraints : objc_object structure ptr list
  }

and table_state = { mutable rows : view list }

let zero_rect = CoreGraphics.CGRect.make ~x:0. ~y:0. ~width:0. ~height:0.
let nsstring value = new_string value

let init_view cls = cls |> alloc |> UIView.initWithFrame zero_rect
let init_label () = UILabel.self |> alloc |> UILabel.initWithFrame zero_rect
let init_text_field () = UITextField.self |> alloc |> UITextField.initWithFrame zero_rect
let init_text_view () = UITextView.self |> alloc |> UITextView.initWithFrame zero_rect
let init_scroll_view () = UIScrollView.self |> alloc |> UIScrollView.initWithFrame zero_rect
let init_image_view () = UIImageView.self |> alloc |> UIImageView.initWithFrame zero_rect
let init_table_view () =
  UITableView.self |> alloc |> UITableView.initWithFrame' zero_rect ~style:_UITableViewStyleInsetGrouped
;;

let host_controller native =
  let controller = UIViewController.self |> alloc |> init in
  UIViewController.setView native controller;
  controller
;;

let navigation_controller () =
  let root = UIViewController.self |> alloc |> init in
  let navigation =
    UINavigationController.self
    |> alloc
    |> UINavigationController.initWithRootViewController root
  in
  UIViewController.view navigation, navigation
;;

let init_stack axis =
  let stack = UIStackView.self |> alloc |> UIStackView.initWithFrame zero_rect in
  UIStackView.setAxis
    (match axis with
     | Apple.Vertical -> 1
     | Apple.Horizontal -> 0)
    stack;
  UIStackView.setDistribution _UIStackViewDistributionFill stack;
  UIStackView.setAlignment
    (match axis with
     | Apple.Vertical -> _UIStackViewAlignmentCenter
     | Apple.Horizontal -> _UIStackViewAlignmentCenter)
    stack;
  stack
;;

let table_data_source_counter = ref 0

let make_table_data_source state =
  table_data_source_counter := !table_data_source_counter + 1;
  let class_name = "BonsaiNativeTableDataSource" ^ Int.to_string !table_data_source_counter in
  let _ =
    Class.define
      class_name
      ~superclass:NSObject.self
      ~methods:
        [ (UITableViewControllerMethods.tableView'numberOfRowsInSection'
           @@ fun _self _cmd _table _section -> LLong.of_int (List.length state.rows))
        ; (UITableViewControllerMethods.tableView'cellForRowAtIndexPath'
           @@ fun _self _cmd _table index_path ->
           let row = NSIndexPath.row index_path in
           let row_view = List.nth_exn state.rows row in
           let cell =
             UITableViewCell.self
             |> alloc
             |> UITableViewCell.initWithStyle _UITableViewCellStyleDefault ~reuseIdentifier:nil
           in
           let content_view = UITableViewCell.contentView cell in
           UIView.removeFromSuperview row_view.native;
           UIView.addSubview row_view.native content_view;
           UIView.setFrame
             (CoreGraphics.CGRect.make ~x:16. ~y:0. ~width:360. ~height:56.)
             row_view.native;
           UIView.setAutoresizingMask _UIViewAutoresizingFlexibleWidth row_view.native;
           cell)
        ; (UITableViewDelegate.tableView'heightForRowAtIndexPath'
           @@ fun _self _cmd _table _index_path -> 56.)
        ]
  in
  Objc.get_class class_name |> alloc |> init
;;

let create kind =
  let table_state =
    match kind with
    | Apple.List -> Some { rows = [] }
    | _ -> None
  in
  let native, controller =
    match kind with
    | Apple.Navigation_stack -> navigation_controller ()
    | Apple.Navigation_link ->
      let native = init_stack Apple.Vertical in
      native, host_controller native
    | Apple.Navigation_split ->
      let native = init_stack Apple.Vertical in
      native, host_controller native
    | Apple.Adaptive_layout ->
      let native = init_stack Apple.Vertical in
      native, host_controller native
    | Apple.Label ->
      let native = init_label () in
      native, host_controller native
    | Apple.Button ->
      let native = UIButton.self |> UIButtonClass.buttonWithType _UIButtonTypeSystem in
      let configuration = UIButtonConfigurationClass.tintedButtonConfiguration UIButtonConfiguration.self in
      UIButtonConfiguration.setCornerStyle _UIButtonConfigurationCornerStyleCapsule configuration;
      UIButton.setConfiguration configuration native;
      native, host_controller native
    | Apple.Toggle ->
      let native = init_view UIView.self in
      native, host_controller native
    | Apple.Text_field ->
      let field = init_text_field () in
      UITextField.setBorderStyle _UITextBorderStyleRoundedRect field;
      UITextField.setClearButtonMode _UITextFieldViewModeWhileEditing field;
      field, host_controller field
    | Apple.Text_editor ->
      let view = init_text_view () in
      view, host_controller view
    | Apple.Stack axis ->
      let native = init_stack axis in
      native, host_controller native
    | Apple.Scroll_view ->
      let native = init_scroll_view () in
      native, host_controller native
    | Apple.List ->
      let native = init_table_view () in
      native, host_controller native
    | Apple.Tab_view ->
      let controller = UITabBarController.self |> alloc |> init in
      UIViewController.view controller, controller
    | Apple.Sidebar_split ->
      let controller = UITabBarController.self |> alloc |> init in
      UIViewController.view controller, controller
    | Apple.Image ->
      let native = init_image_view () in
      native, host_controller native
    | Apple.List_row -> failwith "Apple.list_row is only supported by the SwiftUI backend"
    | Apple.Section ->
      let native = init_stack Apple.Vertical in
      native, host_controller native
    | Apple.Picker ->
      let native = UIButton.self |> UIButtonClass.buttonWithType _UIButtonTypeSystem in
      native, host_controller native
    | Apple.Photo_picker ->
      let native = UIButton.self |> UIButtonClass.buttonWithType _UIButtonTypeSystem in
      native, host_controller native
    | Apple.File_exporter ->
      let native = UIButton.self |> UIButtonClass.buttonWithType _UIButtonTypeSystem in
      native, host_controller native
    | Apple.Share_link ->
      let native = UIButton.self |> UIButtonClass.buttonWithType _UIButtonTypeSystem in
      native, host_controller native
    | Apple.File_importer ->
      let native = UIButton.self |> UIButtonClass.buttonWithType _UIButtonTypeSystem in
      native, host_controller native
    | Apple.Camera_capture ->
      let native = UIButton.self |> UIButtonClass.buttonWithType _UIButtonTypeSystem in
      native, host_controller native
    | Apple.Custom_view class_name ->
      let native = Objc.get_class class_name |> alloc |> init in
      native, host_controller native
  in
  let data_source = Option.map table_state ~f:make_table_data_source in
  Option.iter data_source ~f:(fun data_source ->
    UITableView.setDataSource data_source native;
    UITableView.setDelegate data_source native);
  { native
  ; controller
  ; kind
  ; children = []
  ; table_state
  ; data_source
  ; click_action = None
  ; click_handler = None
  ; click_handler_block = None
  ; change_action = None
  ; change_handler = None
  ; change_handler_block = None
  ; search_controller = None
  ; search_delegate = None
  ; tab_items = []
  ; tab_select_handler = None
  ; tab_delegate = None
  ; toolbar_actions = []
  ; toolbar_handler_blocks = []
  ; presented_sheet = None
  ; frame_constraints = []
  }
;;

let destroy view = UIView.removeFromSuperview view.native

let set_text view text =
  match view.kind with
  | Apple.Label -> UILabel.setText (nsstring text) view.native
  | Apple.Button -> UIButton.setTitle1 (nsstring text) ~forState:_UIControlStateNormal view.native
  | Apple.Text_field ->
    let current = UITextField.text view.native |> NSString._UTF8String in
    if not (String.equal current text) then UITextField.setText (nsstring text) view.native
  | Apple.Text_editor ->
    let current = UITextView.text view.native |> NSString._UTF8String in
    if not (String.equal current text) then UITextView.setText (nsstring text) view.native
  | Apple.Image ->
    UIImageClass.imageNamed (nsstring text) UIImage.self |> fun image ->
    UIImageView.setImage image view.native
  | Apple.Picker -> UIButton.setTitle1 (nsstring text) ~forState:_UIControlStateNormal view.native
  | Apple.Photo_picker -> UIButton.setTitle1 (nsstring text) ~forState:_UIControlStateNormal view.native
  | Apple.File_exporter -> UIButton.setTitle1 (nsstring text) ~forState:_UIControlStateNormal view.native
  | Apple.Share_link -> UIButton.setTitle1 (nsstring text) ~forState:_UIControlStateNormal view.native
  | Apple.File_importer -> UIButton.setTitle1 (nsstring text) ~forState:_UIControlStateNormal view.native
  | Apple.Camera_capture -> UIButton.setTitle1 (nsstring text) ~forState:_UIControlStateNormal view.native
  | _ -> ()
;;

let set_text_attributes _view _attributes = ()
let set_title_visible view is_visible =
  match view.kind, is_visible with
  | (Apple.Button | Apple.Photo_picker), false ->
    UIButton.setTitle1 (nsstring "") ~forState:_UIControlStateNormal view.native
  | _ -> ()
;;

let set_enabled _view _is_enabled = ()
let set_image_payload_mode _view _wants_payload = ()
let set_image_source _view _source = ()
let set_text_field_style _view _style = ()
let set_text_field_secure _view _is_secure = ()
let set_toggle _view ~is_on:_ ~on_change:_ = ()

let set_placeholder view placeholder =
  match view.kind, placeholder with
  | Apple.Text_field, Some placeholder -> UITextField.setPlaceholder (nsstring placeholder) view.native
  | Apple.Text_field, None -> UITextField.setPlaceholder nil view.native
  | Apple.Text_editor, _ -> ()
  | _ -> ()
;;

let set_spacing view spacing =
  match view.kind, spacing with
  | Apple.Stack _, Some spacing -> UIStackView.setSpacing spacing view.native
  | _ -> ()
;;

let remove_child parent child =
  (match parent.kind with
   | Apple.Stack _ | Apple.List -> UIStackView.removeArrangedSubview child.native parent.native
   | _ -> ());
  UIView.removeFromSuperview child.native
;;

let add_child parent child =
  match parent.kind with
  | Apple.Stack _ -> UIStackView.addArrangedSubview child.native parent.native
  | Apple.Scroll_view | Apple.Navigation_stack -> UIView.addSubview child.native parent.native
  | _ -> UIView.addSubview child.native parent.native
;;

let set_children view ~keyed:_ children =
  match view.kind, view.table_state with
  | Apple.List, Some state ->
    state.rows <- children;
    view.children <- children;
    UITableView.reloadData view.native
  | Apple.Tab_view, _ ->
    view.children <- children
  | Apple.Sidebar_split, _ ->
    view.children <- children
  | _ when List.equal phys_equal view.children children -> ()
  | _ ->
    List.iter view.children ~f:(remove_child view);
    view.children <- children;
    List.iter children ~f:(add_child view)
;;

let action_with_handler f =
  let handler =
    Block.make ~args:Objc_type.[ id ] ~return:Objc_type.void (fun _block _sender -> f ())
  in
  UIActionClass.actionWithHandler handler UIAction.self, Obj.repr handler
;;

let action_with_title title f =
  let handler =
    Block.make ~args:Objc_type.[ id ] ~return:Objc_type.void (fun _block _sender -> f ())
  in
  UIAction.self
  |> UIActionClass.actionWithTitle
       (nsstring title)
       ~image:nil
       ~identifier:nil
       ~handler
  , Obj.repr handler
;;

let set_on_click view handler =
  view.click_handler <- handler;
  match handler, view.click_action with
  | None, Some action ->
    UIControl.removeAction action ~forControlEvents:_UIControlEventTouchUpInside view.native;
    view.click_action <- None;
    view.click_handler_block <- None
  | None, None | Some _, Some _ -> ()
  | Some _, None ->
    let action, handler_block =
      action_with_handler (fun () ->
        Option.iter view.click_handler ~f:(fun handler -> handler ()))
    in
    view.click_handler_block <- Some handler_block;
    UIControl.addAction action ~forControlEvents:_UIControlEventTouchUpInside view.native;
    view.click_action <- Some action
;;

let set_on_change view handler =
  view.change_handler <- handler;
  match view.kind, handler, view.change_action with
  | Apple.Text_editor, _, _ -> ()
  | _, None, Some action ->
    UIControl.removeAction action ~forControlEvents:_UIControlEventEditingChanged view.native;
    view.change_action <- None;
    view.change_handler_block <- None
  | _, None, None | _, Some _, Some _ -> ()
  | _, Some _, None ->
    let action, handler_block =
      action_with_handler (fun () ->
        let text = UITextField.text view.native |> NSString._UTF8String in
        Option.iter view.change_handler ~f:(fun handler -> handler text))
    in
    view.change_handler_block <- Some handler_block;
    UIControl.addAction action ~forControlEvents:_UIControlEventEditingChanged view.native;
    view.change_action <- Some action
;;

let set_list_row
  _view
  ~title:_
  ~subtitle:_
  ~trailing_text:_
  ~leading_system_image:_
  ~preview_image_path:_
  ~content_style:_
  ~accessory:_
  ~title_strikethrough:_
  ~leading_button:_
  ~swipe_actions:_
  ~menu_actions:_
  =
  failwith "Apple.list_row is only supported by the SwiftUI backend"
;;

let set_sidebar_shell
  _view
  ~header_action:_
  ~actions:_
  ~bottom_search_placeholder:_
  ~bottom_search_text:_
  ~bottom_search_on_change:_
  ~bottom_action:_
  =
  failwith "unimplemented"
;;

let refresh_list_row_callbacks
  _view
  ~on_click:_
  ~leading_button:_
  ~swipe_actions:_
  ~menu_actions:_
  =
  failwith "unimplemented"
;;

let nsarray values =
  let array = NSMutableArray.self |> NSMutableArrayClass.arrayWithCapacity (List.length values) in
  List.iter values ~f:(fun value -> NSMutableArray.addObject value array);
  array
;;

let install_tab_item (tab : Apple.rendered_tab) controller =
  let title = nsstring tab.title in
  let image =
    Option.value_map tab.system_image ~default:nil ~f:(fun system_image ->
      UIImage.self |> UIImageClass.systemImageNamed (nsstring system_image))
  in
  let item =
    UITabBarItem.self |> alloc |> UITabBarItem.initWithTitle title ~image ~selectedImage:nil
  in
  UIViewController.setTitle title controller;
  UIViewController.setTabBarItem item controller
;;

let tab_index_by_id tabs id =
  List.findi tabs ~f:(fun _ (tab : Apple.rendered_tab) -> String.equal tab.id id)
  |> Option.map ~f:fst
;;

let selected_tab_id view selected_controller =
  List.find_mapi view.children ~f:(fun index child ->
    if phys_equal child.controller selected_controller
    then List.nth view.tab_items index |> Option.map ~f:(fun tab -> tab.Apple.id)
    else None)
;;

let ensure_tab_delegate view =
  match view.tab_delegate with
  | Some delegate_ -> delegate_
  | None ->
    let class_name = "BonsaiNativeTabDelegate" ^ Int.to_string (Oo.id (object end)) in
    let _ =
      Class.define
        class_name
        ~superclass:NSObject.self
        ~methods:
          [ (Define.method_spec
               ~cmd:(selector "tabBarController:didSelectViewController:")
               ~typ:(id @-> id @-> returning void)
               ~enc:"v32@0:8@16@24"
             @@ fun _self _cmd _tab_controller selected_controller ->
             selected_tab_id view selected_controller
             |> Option.iter ~f:(fun id ->
               Option.iter view.tab_select_handler ~f:(fun handler -> handler id)))
          ]
    in
    let delegate_ = Objc.get_class class_name |> alloc |> init in
    view.tab_delegate <- Some delegate_;
    delegate_
;;

let apply_tabs view ~selected =
  if (not (List.is_empty view.children))
     && List.length view.tab_items = List.length view.children
  then (
    List.iter2_exn view.tab_items view.children ~f:(fun tab child ->
      install_tab_item tab child.controller);
    UITabBarController.setViewControllers
      (nsarray (List.map view.children ~f:(fun child -> child.controller)))
      view.controller;
    tab_index_by_id view.tab_items selected
    |> Option.iter ~f:(fun index -> UITabBarController.setSelectedIndex index view.controller))
;;

let set_tabs view ~selected ~on_select tabs =
  view.tab_items <- tabs;
  view.tab_select_handler <- on_select;
  match view.kind with
  | Apple.Tab_view | Apple.Sidebar_split ->
    let delegate_ = ensure_tab_delegate view in
    UITabBarController.setDelegate delegate_ view.controller;
    apply_tabs view ~selected
  | _ -> ()
;;

let set_section _view ~title:_ = ()

let set_picker
  view
  ~title
  ~selected
  ~on_select:_
  (options : Apple.rendered_picker_option list)
  =
  let selected_title =
    options
    |> List.find ~f:(fun option -> String.equal option.Apple.id selected)
    |> Option.map ~f:(fun option -> option.Apple.title)
    |> Option.value ~default:selected
  in
  UIButton.setTitle1
    (nsstring (title ^ ": " ^ selected_title))
    ~forState:_UIControlStateNormal
    view.native
;;

let set_file_exporter _view _export = ()
let set_share_link _view _share_link = ()

let set_file_importer _view ~allowed_content_types:_ ~on_select:_ = ()

let make_search_delegate ~schedule_event ~on_change =
  let class_name = "BonsaiNativeSearchDelegate" ^ Int.to_string (Oo.id (object end)) in
  let _ =
    Class.define
      class_name
      ~superclass:NSObject.self
      ~methods:
        [ (UISearchBarDelegate.searchBar'textDidChange'
           @@ fun _self _cmd _search_bar text ->
           schedule_event (on_change (NSString._UTF8String text)))
        ]
  in
  Objc.get_class class_name |> alloc |> init
;;

let install_searchable view ~schedule_event ~text ~on_change =
  let search_controller =
    match view.search_controller with
    | Some search_controller -> search_controller
    | None ->
      let search_controller =
        UISearchController.self |> alloc |> UISearchController.initWithSearchResultsController nil
      in
      view.search_controller <- Some search_controller;
      let navigation_item = UIViewController.navigationItem view.controller in
      UINavigationItem.setSearchController search_controller navigation_item;
      search_controller
  in
  let search_bar = UISearchController.searchBar search_controller in
  UISearchBar.setText (nsstring text) search_bar;
  let delegate_ = make_search_delegate ~schedule_event ~on_change in
  UISearchBar.setDelegate delegate_ search_bar;
  view.search_delegate <- Some delegate_
;;

let install_toolbar view ~schedule_event items =
  let actions, buttons =
    List.map items ~f:(fun (item : Apple.toolbar_item) ->
      let action, handler_block =
        action_with_title item.Apple.title (fun () -> schedule_event item.Apple.on_click)
      in
      let button = UIBarButtonItem.self |> alloc |> UIBarButtonItem.initWithPrimaryAction action in
      UIBarButtonItem.setEnabled item.is_enabled button;
      (action, handler_block), button)
    |> List.unzip
  in
  view.toolbar_actions <- List.map actions ~f:fst;
  view.toolbar_handler_blocks <- List.map actions ~f:snd;
  let navigation_item = UIViewController.navigationItem view.controller in
  UINavigationItem.setRightBarButtonItems (nsarray buttons) navigation_item
;;

let set_navigation_title view title = UIViewController.setTitle (nsstring title) view.controller

let apply_padding view insets =
  let insets =
    UIEdgeInsets.init
      ~top:insets.Apple.top
      ~left:insets.leading
      ~bottom:insets.bottom
      ~right:insets.trailing
  in
  UIView.setLayoutMargins insets view.native
;;

let apply_frame view (frame : Apple.frame) =
  if not (List.is_empty view.frame_constraints)
  then NSLayoutConstraintClass.deactivateConstraints (nsarray view.frame_constraints) NSLayoutConstraint.self;
  view.frame_constraints <- [];
  let constraints =
    [ Option.map frame.Apple.width ~f:(fun width ->
        NSLayoutDimension.constraintEqualToConstant width (UIView.widthAnchor view.native))
    ; Option.map frame.height ~f:(fun height ->
        NSLayoutDimension.constraintEqualToConstant height (UIView.heightAnchor view.native))
    ]
    |> List.filter_opt
  in
  if not (List.is_empty constraints)
  then (
    UIView.setTranslatesAutoresizingMaskIntoConstraints false view.native;
    NSLayoutConstraintClass.activateConstraints (nsarray constraints) NSLayoutConstraint.self;
    view.frame_constraints <- constraints)
;;

let install_sheet view ~is_presented ~content =
  match is_presented, content, view.presented_sheet with
  | true, Some content, None ->
    let sheet_controller = UIViewController.self |> alloc |> init in
    UIViewController.setView content.native sheet_controller;
    UIViewController.presentViewController sheet_controller ~animated:true ~completion:null view.controller;
    view.presented_sheet <- Some sheet_controller
  | true, Some content, Some sheet_controller ->
    UIViewController.setView content.native sheet_controller
  | false, _, Some sheet_controller ->
    UIViewController.dismissViewControllerAnimated true ~completion:null sheet_controller;
    view.presented_sheet <- None
  | _ -> ()
;;

let set_modifiers view ~schedule_event modifiers =
  let saw_navigation_title = ref false in
  List.iter modifiers ~f:(function
    | Apple.Rendered_padding insets -> apply_padding view insets
    | Apple.Rendered_frame frame -> apply_frame view frame
    | Apple.Rendered_searchable { text; on_change } ->
      install_searchable view ~schedule_event ~text ~on_change
    | Apple.Rendered_toolbar items -> install_toolbar view ~schedule_event items
    | Apple.Rendered_sheet { is_presented; content; on_dismiss = _ } ->
      install_sheet view ~is_presented ~content
    | Apple.Rendered_alert _ -> failwith "unimplemented"
    | Apple.Rendered_navigation_title title ->
      saw_navigation_title := true;
      set_navigation_title view title);
  if not !saw_navigation_title then set_navigation_title view ""
;;

module Backend = struct
  type nonrec view = view

  let create = create
  let destroy = destroy
  let set_text = set_text
  let set_text_attributes = set_text_attributes
  let set_enabled = set_enabled
  let set_placeholder = set_placeholder
  let set_text_field_style = set_text_field_style
  let set_text_field_secure = set_text_field_secure
  let set_toggle = set_toggle
  let set_spacing = set_spacing
  let set_children = set_children
  let set_tabs = set_tabs
  let set_sidebar_shell = set_sidebar_shell
  let set_list_row = set_list_row
  let refresh_list_row_callbacks = refresh_list_row_callbacks
  let set_section = set_section
  let set_picker = set_picker
  let set_file_exporter = set_file_exporter
  let set_share_link = set_share_link
  let set_file_importer = set_file_importer
  let set_image_payload_mode = set_image_payload_mode
  let set_image_source = set_image_source
  let set_on_click = set_on_click
  let set_on_change = set_on_change
  let set_modifiers = set_modifiers
end

module Renderer = Apple.Renderer.Make (Backend)
module App = Apple.App.Make (Backend)

let native view = view.native
let controller view = view.controller
