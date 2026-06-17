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
  ; mutable toolbar_actions : objc_object structure ptr list
  ; mutable toolbar_handler_blocks : Obj.t list
  ; mutable presented_sheet : objc_object structure ptr option
  }

and table_state = { mutable rows : view list }

let zero_rect = CoreGraphics.CGRect.make ~x:0. ~y:0. ~width:0. ~height:0.
let nsstring value = new_string value

let init_view cls = cls |> alloc |> UIView.initWithFrame zero_rect
let init_label () = UILabel.self |> alloc |> UILabel.initWithFrame zero_rect
let init_text_field () = UITextField.self |> alloc |> UITextField.initWithFrame zero_rect
let init_scroll_view () = UIScrollView.self |> alloc |> UIScrollView.initWithFrame zero_rect
let init_image_view () = UIImageView.self |> alloc |> UIImageView.initWithFrame zero_rect
let init_table_view () = UITableView.self |> alloc |> UITableView.initWithFrame' zero_rect ~style:_UITableViewStylePlain

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
  UIStackView.setAlignment _UIStackViewAlignmentFill stack;
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
             (CoreGraphics.CGRect.make ~x:16. ~y:0. ~width:320. ~height:44.)
             row_view.native;
           UIView.setAutoresizingMask _UIViewAutoresizingFlexibleWidth row_view.native;
           cell)
        ; (UITableViewDelegate.tableView'heightForRowAtIndexPath'
           @@ fun _self _cmd _table _index_path -> 44.)
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
    | Apple.Label ->
      let native = init_label () in
      native, host_controller native
    | Apple.Button ->
      let native = UIButton.self |> UIButtonClass.buttonWithType _UIButtonTypeSystem in
      native, host_controller native
    | Apple.Text_field ->
      let field = init_text_field () in
      UITextField.setBorderStyle _UITextBorderStyleRoundedRect field;
      UITextField.setClearButtonMode _UITextFieldViewModeWhileEditing field;
      field, host_controller field
    | Apple.Stack axis ->
      let native = init_stack axis in
      native, host_controller native
    | Apple.Scroll_view ->
      let native = init_scroll_view () in
      native, host_controller native
    | Apple.List ->
      let native = init_table_view () in
      native, host_controller native
    | Apple.Image ->
      let native = init_image_view () in
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
  ; toolbar_actions = []
  ; toolbar_handler_blocks = []
  ; presented_sheet = None
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
  | Apple.Image ->
    UIImageClass.imageNamed (nsstring text) UIImage.self |> fun image ->
    UIImageView.setImage image view.native
  | _ -> ()
;;

let set_placeholder view placeholder =
  match view.kind, placeholder with
  | Apple.Text_field, Some placeholder -> UITextField.setPlaceholder (nsstring placeholder) view.native
  | Apple.Text_field, None -> UITextField.setPlaceholder nil view.native
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
  match handler, view.change_action with
  | None, Some action ->
    UIControl.removeAction action ~forControlEvents:_UIControlEventEditingChanged view.native;
    view.change_action <- None;
    view.change_handler_block <- None
  | None, None | Some _, Some _ -> ()
  | Some _, None ->
    let action, handler_block =
      action_with_handler (fun () ->
        let text = UITextField.text view.native |> NSString._UTF8String in
        Option.iter view.change_handler ~f:(fun handler -> handler text))
    in
    view.change_handler_block <- Some handler_block;
    UIControl.addAction action ~forControlEvents:_UIControlEventEditingChanged view.native;
    view.change_action <- Some action
;;

let nsarray values =
  let array = NSMutableArray.self |> NSMutableArrayClass.arrayWithCapacity (List.length values) in
  List.iter values ~f:(fun value -> NSMutableArray.addObject value array);
  array
;;

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
    List.map items ~f:(fun item ->
      let action, handler_block =
        action_with_title item.Apple.title (fun () -> schedule_event item.Apple.on_click)
      in
      let button = UIBarButtonItem.self |> alloc |> UIBarButtonItem.initWithPrimaryAction action in
      (action, handler_block), button)
    |> List.unzip
  in
  view.toolbar_actions <- List.map actions ~f:fst;
  view.toolbar_handler_blocks <- List.map actions ~f:snd;
  let navigation_item = UIViewController.navigationItem view.controller in
  UINavigationItem.setRightBarButtonItems (nsarray buttons) navigation_item
;;

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

let apply_frame view frame =
  match frame.Apple.width, frame.height with
  | None, None -> ()
  | width, height ->
    UIView.setFrame
      (CoreGraphics.CGRect.make
         ~x:0.
         ~y:0.
         ~width:(Option.value width ~default:0.)
         ~height:(Option.value height ~default:0.))
      view.native
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
  List.iter modifiers ~f:(function
    | Apple.Rendered_padding insets -> apply_padding view insets
    | Apple.Rendered_frame frame -> apply_frame view frame
    | Apple.Rendered_searchable { text; on_change } ->
      install_searchable view ~schedule_event ~text ~on_change
    | Apple.Rendered_toolbar items -> install_toolbar view ~schedule_event items
    | Apple.Rendered_sheet { is_presented; content; on_dismiss = _ } ->
      install_sheet view ~is_presented ~content)
;;

module Backend = struct
  type nonrec view = view

  let create = create
  let destroy = destroy
  let set_text = set_text
  let set_placeholder = set_placeholder
  let set_spacing = set_spacing
  let set_children = set_children
  let set_on_click = set_on_click
  let set_on_change = set_on_change
  let set_modifiers = set_modifiers
end

module Renderer = Apple.Renderer.Make (Backend)
module App = Apple.App.Make (Backend)

let native view = view.native
