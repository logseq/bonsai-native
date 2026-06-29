module Apple = Bonsai_apple
module Backend = Apple.For_testing.Backend
module App = Apple.App.Make (Backend)

let require condition message = if not condition then failwith message

let contains text ~substring =
  let text_length = String.length text in
  let substring_length = String.length substring in
  let rec loop index =
    if index + substring_length > text_length
    then false
    else if String.sub text index substring_length = substring
    then true
    else loop (index + 1)
  in
  substring_length = 0 || loop 0
;;

let count_substrings text ~substring =
  let text_length = String.length text in
  let substring_length = String.length substring in
  let rec loop index count =
    if substring_length = 0 || index + substring_length > text_length
    then count
    else if String.sub text index substring_length = substring
    then loop (index + substring_length) (count + 1)
    else loop (index + 1) count
  in
  loop 0 0
;;

let substring_index text ~substring ~from =
  let text_length = String.length text in
  let substring_length = String.length substring in
  let rec loop index =
    if substring_length = 0
    then Some index
    else if index + substring_length > text_length
    then None
    else if String.sub text index substring_length = substring
    then Some index
    else loop (index + 1)
  in
  loop from
;;

let read_file path =
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in channel)
    (fun () ->
       let length = in_channel_length channel in
       really_input_string channel length)
;;

let swiftui_source_path = "../swiftui/BonsaiNativeSwiftUI.swift"
let swiftui_backend_source_path = "../swiftui/bonsai_apple_swiftui.ml"
let swiftui_dune_path = "../swiftui/dune"
let apple_source_path = "../src/bonsai_apple.ml"
let bootstrap_ios_script_path = "../../scripts/bootstrap-ios-jane.sh"

let test_navigation_value_links_keep_primary_tap_for_link () =
  let source = read_file swiftui_source_path in
  require
    (count_substrings
       source
       ~substring:"navigationLinkLabel(suppressRowActions: true)"
     >= 2)
    "both value-based and destination-based NavigationLink labels should suppress \
     nested row actions so the primary tap opens the link"
;;

let test_navigation_links_render_without_system_link_chrome () =
  let source = read_file swiftui_source_path in
  let value_link_start =
    match
      substring_index
        source
        ~substring:"NavigationLink(value: navigationValue)"
        ~from:0
    with
    | Some index -> index
    | None -> failwith "value-based NavigationLink branch not found"
  in
  let destination_link_start =
    match substring_index source ~substring:"NavigationLink {" ~from:value_link_start with
    | Some index -> index
    | None -> failwith "destination NavigationLink branch not found"
  in
  let first_plain_style =
    match substring_index source ~substring:".buttonStyle(.plain)" ~from:value_link_start with
    | Some index -> index
    | None -> failwith "value-based NavigationLink plain style not found"
  in
  let second_plain_style =
    match
      substring_index source ~substring:".buttonStyle(.plain)" ~from:destination_link_start
    with
    | Some index -> index
    | None -> failwith "destination NavigationLink plain style not found"
  in
  require
    (first_plain_style < destination_link_start)
    "value-based NavigationLink should use plain button style so inline links do not \
     show system link chrome";
  require
    (second_plain_style > destination_link_start)
    "destination NavigationLink should use plain button style so inline links do not \
     show system link chrome"
;;

let test_navigation_value_links_do_not_preempt_system_push () =
  let source = read_file swiftui_source_path in
  let value_link_start =
    match
      substring_index
        source
        ~substring:"if let navigationValue = node.navigationLinkValue"
        ~from:0
    with
    | Some index -> index
    | None -> failwith "value-based NavigationLink branch not found"
  in
  let destination_link_start =
    match
      substring_index
        source
        ~substring:"} else {\n        NavigationLink {"
        ~from:value_link_start
    with
    | Some index -> index
    | None -> failwith "destination NavigationLink branch not found"
  in
  let value_branch =
    String.sub source value_link_start (destination_link_start - value_link_start)
  in
  require
    (not (contains value_branch ~substring:"simultaneousGesture"))
    "value-based NavigationLink should let NavigationStack update path first so push/pop \
     and header transitions remain native"
;;

let test_compact_sidebar_close_paths_share_swift_animation () =
  let source = read_file swiftui_source_path in
  let expected_direct_close_paths = 3 in
  require
    (count_substrings source ~substring:"setCompactSidebarOpen(false)"
     >= expected_direct_close_paths)
    "compact sidebar overlay and drag close paths should go through \
     setCompactSidebarOpen(false) for the Swift drawer animation, keyboard dismissal, \
     haptic, and drag-state reset";
  require
    (count_substrings source ~substring:"performSidebarAction(action)" >= 2)
    "compact sidebar action taps should share the data-driven action helper";
  require
    (contains source ~substring:"selectSidebarActionRoute(selectedTab")
    "compact sidebar actions should select the route locally before the OCaml rerender";
  require
    (contains source ~substring:"node.selectedTabId = selectedTab")
    "compact sidebar route selection should update the selected route in the Swift \
     animation transaction";
  require
    (count_substrings source ~substring:"closeCompactSidebarIfNeeded(action)" = 1)
    "compact sidebar action close policy should stay centralized";
  require
    (count_substrings source ~substring:"isCompactSidebarOpen = false" = 1)
    "compact sidebar close paths should not mutate isCompactSidebarOpen directly \
     outside its @State initial value"
;;

let test_native_list_uses_stable_node_identity () =
  let source = read_file swiftui_source_path in
  require
    (not
       (contains
          source
          ~substring:"ForEach(Array(node.children.enumerated()), id: \\.offset)"))
    "SwiftUI List rows should use the stable BonsaiNativeNode id, not the row offset, \
     so appending rows does not recycle every row identity";
  require
    (not (contains source ~substring:".id(index)"))
    "SwiftUI List scroll identifiers should use the stable node id instead of the row \
     offset";
  require
    (contains source ~substring:"proxy.scrollTo(targetID)")
    "focused-row scrolling should target the focused BonsaiNativeNode id"
;;

let test_list_virtualization_probe_does_not_log_per_row_events () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"list_update reason=")
    "list virtualization probe should keep summary update logs for device verification";
  require
    (contains source ~substring:"BONSAI_NATIVE_LIST_DEBUG")
    "list virtualization probe should be opt-in so row appear bookkeeping is not on the \
     scroll hot path by default";
  require
    (not (contains source ~substring:"appearedRowsByList"))
    "list virtualization probe should not retain a set of every row that has ever \
     appeared; that cost grows with scroll distance";
  require
    (not (contains source ~substring:"unique_appeared_rows"))
    "list virtualization probe logs should not require unbounded per-row history";
  require
    (not (contains source ~substring:"row_appear list="))
    "list virtualization probe should not log every row appear event because that makes \
     scrolling measurements noisy";
  require
    (not (contains source ~substring:"row_disappear list="))
    "list virtualization probe should not log every row disappear event because that \
     makes scrolling measurements noisy"
;;

let test_swiftui_library_builds_in_default_ios_context () =
  let source = read_file swiftui_dune_path in
  require
    (contains source ~substring:"default.ios")
    "dune -x ios uses the default.ios target context; bonsai_apple.swiftui must be \
     enabled there so iOS sysroot installs do not keep stale SwiftUI artifacts";
  require
    (contains source ~substring:"public_name bonsai_apple.swiftui")
    "the default.ios context coverage should apply to the public SwiftUI sublibrary"
;;

let test_lazy_list_renders_rows_in_testing_backend () =
  Backend.reset ();
  let app =
    App.create (fun _graph ->
      Apple.lazy_list ~length:3
        ~key:(fun index -> "row-" ^ string_of_int index)
        ~row:(fun index -> Apple.text ("Lazy " ^ string_of_int index))
        ())
  in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"text=\"Lazy 0\"")
    "testing backend should materialize lazy list rows for assertions";
  require
    (contains rendered ~substring:"text=\"Lazy 2\"")
    "testing backend should render all lazy list rows"
;;

let test_lazy_list_patches_cached_rows () =
  Backend.reset ();
  let app =
    App.create (fun graph ->
      let count, set_count = Apple.state graph ~key:"count" 0 in
      Apple.vstack
        [
          Apple.lazy_list ~length:1 ~key:(fun _ -> "stable-row")
            ~row:(fun _ -> Apple.text ("Lazy " ^ string_of_int count))
            ();
          Apple.button "Increment" ~on_click:(set_count (count + 1));
        ])
  in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (String.equal (Backend.find_text_exn root ~path:[ 0; 0 ]) "Lazy 0")
    "initial lazy row should render state";
  Backend.click_exn root ~path:[ 1 ];
  require
    (String.equal (Backend.find_text_exn root ~path:[ 0; 0 ]) "Lazy 1")
    "cached lazy row should patch when state changes"
;;

let test_lazy_list_renderer_uses_indexed_keys () =
  let source = read_file apple_source_path in
  require
    (not (contains source ~substring:"duplicate Apple lazy_list key"))
    "lazy list construction should not eagerly scan every key; keys are validated only for \
     materialized rows";
  require
    (not (contains source ~substring:"Array.init length key"))
    "lazy list renderer should not eagerly allocate keys for every row"
  ;
  require
    (not (contains source ~substring:"List.init length key"))
    "lazy list fingerprint should not call the row key callback for every row";
  require
    (contains source ~substring:"let find_lazy_row_by_key")
    "lazy list renderer should be able to reuse a mounted row after its index changes";
  require
    (contains
       source
       ~substring:
         "match find_lazy_row_by_key t ~target_index:index ~target_key:row_key with")
    "lazy list stale scans should distinguish moved rows from rows whose content or focus \
     changed";
  require
    (not
       (contains source
          ~substring:
            "if String.equal cached_key row_key\n                      then stale_indices\n                      else index :: stale_indices"))
    "lazy list stale scans should not destroy moved rows just because their index key \
     changed";
  require
    (contains source ~substring:"Hashtbl.remove t.lazy_rows cached_index")
    "lazy list renderer should move a cached row from its old index to its new index \
     instead of rebuilding it";
  require
    (contains
       source
       ~substring:"Hashtbl.replace t.lazy_rows cached_index")
    "lazy list renderer should keep the displaced row cached so adjacent moved rows are \
     reused instead of remounted";
  require
    (contains source ~substring:"Hashtbl.replace t.lazy_rows cached_index\n                        displaced")
    "lazy list renderer should preserve the displaced row record when rekeying moved rows";
  require
    (not (contains source ~substring:"if index >= length then None"))
    "lazy list focus handling should not scan every row key to find a focused row"
;;

let test_lazy_list_marks_moved_target_indices_stale () =
  let source = read_file apple_source_path in
  require
    (contains source ~substring:"| Some _ -> index :: stale_indices")
    "lazy list stale scans should invalidate a visible target index when its cached row \
     key moved from another index; otherwise old footer rows can remain visible in the \
     middle after load more"
;;

let test_swiftui_lazy_list_uses_native_row_provider () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"lazyListProviderId")
    "SwiftUI backend should store a native lazy list provider id";
  require
    (contains source ~substring:"lazyListRowCount")
    "SwiftUI backend should store only the lazy list row count";
  require
    (not (contains source ~substring:"lazyListRowKeys"))
    "SwiftUI backend should not store every lazy row key because that scales with the \
     entire list";
  require
    (contains source ~substring:"renderCallback(providerId, Int32(index))")
    "SwiftUI lazy list rows should be rendered through the provider on demand";
  require
    (contains source ~substring:"releaseCachedRow(index: candidate")
    "SwiftUI lazy lists should release cached OCaml rows from retained-cache trimming, \
     not from every row disappear"
;;

let test_swiftui_lazy_list_loads_rows_on_appear () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"BonsaiNativeLazyListRowView(")
    "SwiftUI lazy lists should use a row wrapper so ForEach can stay lightweight";
  require
    (contains source ~substring:"private func loadRow()")
    "SwiftUI lazy list rows should construct OCaml rows from onAppear";
  require
    (contains source ~substring:"loadRow()")
    "SwiftUI lazy list row construction should happen in onAppear so the row does not \
     display a blank placeholder first";
  require
    (contains source ~substring:"DispatchQueue.main.async")
    "SwiftUI lazy list row release should be deferred so disappearing rows cannot re-enter \
     OCaml during a render pass";
  require
    (not
       (contains source ~substring:"if let child = renderLazyListRow(providerId:"))
    "SwiftUI lazy lists should not call the OCaml row provider directly inside the \
     ForEach body because SwiftUI may evaluate off-screen rows"
;;

let test_swiftui_lazy_list_uses_native_list_for_row_actions () =
  let source = read_file swiftui_source_path in
  require
    (not (contains source ~substring:"lazyScrollList(providerId: providerId, proxy: proxy)"))
    "lazy provider lists should not bypass native List, because ScrollView/LazyVStack \
     does not support native swipe delete or long-press row moves";
  require
    (not (contains source ~substring:"private func lazyScrollList"))
    "lazy provider lists should use the native List path with onDelete/onMove";
  require
    (contains source ~substring:"private func nativeList(_ proxy: ScrollViewProxy) -> some View")
    "lazy provider lists should retain the native List path";
  require
    (contains source ~substring:".onDelete { offsets in")
    "lazy provider native List rows should expose native swipe delete";
  require
    (contains source ~substring:".onMove { source, destination in")
    "lazy provider native List rows should expose native row move"
;;

let test_swiftui_native_list_disables_implicit_row_count_animation () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:".transaction { transaction in\n      transaction.animation = nil\n    }")
    "lazy provider native List should disable implicit row-count animations so append-only \
     load-more updates do not hitch active scrolling"
;;

let test_swiftui_lazy_list_move_updates_visible_order_immediately () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"private struct BonsaiNativeLazyListMovePreview")
    "lazy provider row moves should use a lightweight local preview so native List \
     updates immediately after a drag";
  require
    (contains source ~substring:"@State private var lazyListMovePreview")
    "the move preview should be view-local state rather than rebuilding OCaml rows";
  require
    (contains source ~substring:"ForEach(0..<node.lazyListRowCount, id: \\.self)")
    "lazy provider List rows should be driven by range identity so native List does not \
     pre-resolve every row key";
  require
    (contains source ~substring:"lazyListMovePreview =\n      BonsaiNativeLazyListMovePreview")
    "native onMove should update the local order before waiting for OCaml to render";
  require
    (contains source ~substring:"private func commitLazyListMove(fromIndex: Int, toOffset: Int)")
    "lazy provider row moves should commit to OCaml after the local preview is visible";
  require
    (contains source ~substring:"private final class BonsaiNativeRenderedFrameScheduler")
    "lazy provider row moves should use a frame scheduler, not an executor yield, before \
     committing to OCaml";
  require
    (contains
       source
       ~substring:
         "BonsaiNativeRenderedFrameScheduler.shared.runAfterRenderedFrame { [model] in")
    "lazy provider row moves should wait until after SwiftUI can render the local preview \
     before committing to OCaml";
  require
    (not (contains source ~substring:"await Task.yield()"))
    "Task.yield only yields the Swift executor and does not guarantee the List preview has \
     presented a frame";
  require
    (not (contains source ~substring:"Array(0..<node.lazyListRowCount)"))
    "lazy move preview must not allocate an array for every row in large journals"
;;

let test_swiftui_list_debug_perf_log_uses_swift_safe_interpolation () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"private func debugDouble(_ value: Double, digits: Int)")
    "debug list perf logs should format doubles with a narrow helper";
  require
    (not
       (contains
          source
          ~substring:
            "String(\n        format:\n          \"list_perf seconds=%.2f list=%@"))
    "debug list perf logs should not use one large String(format:) call with Swift Int \
     values because iOS 26 reports format-specifier mismatches"
;;

let test_swiftui_frame_probe_can_run_without_list_debug_bookkeeping () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"BONSAI_NATIVE_FRAME_DEBUG")
    "frame gap logging should have a frame-only mode so profiling can avoid per-row \
     list debug bookkeeping on the scroll hot path";
  require
    (contains source
       ~substring:
         "ProcessInfo.processInfo.environment[\"BONSAI_NATIVE_FRAME_DEBUG\"] == \"1\"")
    "frame-only mode should be enabled independently from BONSAI_NATIVE_LIST_DEBUG";
  require
    (contains source
       ~substring:
         "ProcessInfo.processInfo.environment[\"BONSAI_NATIVE_LIST_DEBUG\"] == \"1\"")
    "per-row list virtualization logs should remain separately gated"
;;

let test_swiftui_frame_probe_logs_slow_lazy_row_renders () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"func markLazyRowRender")
    "frame-only profiling should be able to attribute frame gaps to slow lazy row renders";
  require
    (contains source ~substring:"lazy_row_render_slow")
    "slow lazy row render logs should have a stable event name for scroll-phase diagnosis";
  require
    (contains source ~substring:"guard isEnabled && elapsedMs >= 4 else { return }")
    "slow lazy row render logging should be thresholded so frame-only profiling does not \
     log every row on the scroll hot path";
  require
    (contains source
       ~substring:"BonsaiNativeFrameProbe.shared.markLazyRowRender")
    "lazy row rendering should report slow rows to the frame probe without requiring full \
     list debug bookkeeping"
;;

let test_swiftui_frame_probe_reports_scroll_phase_row_lifecycle_counts () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"lazy_body=%d lazy_appear=%d lazy_disappear=%d")
    "frame-only reports should include lazy row lifecycle counts for scroll-phase \
     attribution";
  require
    (contains source ~substring:"media_create=%d media_destroy=%d")
    "frame-only reports should include media view lifecycle counts";
  require
    (contains source ~substring:"func markLazyRowBody")
    "lazy row body evaluations should be counted without enabling full list debug";
  require
    (contains source ~substring:"func markMediaViewCreated")
    "media view creation should be counted without enabling full list debug"
;;

let test_swiftui_host_model_is_only_observed_by_root_view () =
  let source = read_file swiftui_source_path in
  require
    (count_substrings source ~substring:"@ObservedObject var model: BonsaiNativeHostModel" = 1)
    "only the root SwiftUI view should observe BonsaiNativeHostModel; child rows use it as \
     an event dispatcher, otherwise every root update invalidates visible rows"
;;

let test_swiftui_lazy_list_row_is_equatable () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"BonsaiNativeLazyListRowView: View, Equatable")
    "lazy list rows should be Equatable so root updates do not recompute unchanged visible \
     row bodies";
  require
    (contains source ~substring:"static func ==")
    "lazy list row equality should compare stable row identity inputs";
  require
    (contains source ~substring:".equatable()")
    "lazy list rows should opt into SwiftUI EquatableView body skipping"
;;

let test_swiftui_lazy_list_visible_index_tracking_stays_off_scroll_hot_path () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"trackVisibleIndexAppear()")
    "lazy row appear should delegate visible-index tracking to a guarded helper";
  require
    (contains source ~substring:"trackVisibleIndexDisappear()")
    "lazy row disappear should delegate visible-index tracking to a guarded helper";
  require
    (contains source ~substring:"if BonsaiNativeListVirtualizationProbe.shared.isDebugEnabled")
    "visible-index bookkeeping should only run when full list debug is explicitly enabled"
;;

let test_swiftui_lazy_list_does_not_keep_slot_collection () =
  let source = read_file swiftui_source_path in
  require
    (not (contains source ~substring:"BonsaiNativeLazyListRowSlots"))
    "lazy list should not keep a slot collection because SwiftUI repeatedly walks \
     collection ids";
  require
    (not (contains source ~substring:"BonsaiNativeLazyListRowSlot"))
    "lazy list should not allocate row slot values for every row";
  require
    (contains source ~substring:"lazyListMovePreview?.sourceIndex(for: position) ?? position")
    "range-based rows should still honor the local move preview"
;;

let test_swiftui_lazy_list_foreach_does_not_resolve_all_row_keys () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"ForEach(0..<node.lazyListRowCount, id: \\.self)")
    "lazy lists should use range identity so SwiftUI List does not resolve every row key \
     while diffing large collections";
  require
    (not (contains source ~substring:"ForEach(slots)"))
    "lazy lists should not feed a key-backed slot collection to ForEach because SwiftUI \
     repeatedly walks all ids";
  require
    (contains source ~substring:"lazyListRowPosition(\n          providerId: providerId")
    "range-based rows should still resolve the current source row when SwiftUI asks for \
     that position"
;;

let test_swiftui_lazy_list_disappear_does_not_enqueue_release_work () =
  let source = read_file swiftui_source_path in
  require
    (not (contains source ~substring:"scheduleRelease()"))
    "lazy row disappear should not enqueue deferred release closures on the scroll hot \
     path; retained cache trimming owns provider release";
  require
    (not (contains source ~substring:"BonsaiNativeLazyRowDetachScheduler"))
    "lazy row detach scheduler should not exist when disappear no longer detaches rows";
  require
    (not (contains source ~substring:"releaseToken"))
    "lazy row state should not carry release tokens when disappear does not detach rows"
;;

let test_ios_bootstrap_prefers_checkout_sources_for_local_packages () =
  let source = read_file bootstrap_ios_script_path in
  require
    (contains source ~substring:"$repo_root/$package.opam")
    "iOS bootstrap should detect packages that live in the current checkout";
  require
    (contains source ~substring:"printf '%s\\n' \"$repo_root\"")
    "iOS bootstrap should build local packages from the current checkout so Swift assets \
     installed into ios-sysroot cannot lag behind source edits";
  require
    (contains source ~substring:"find \"$sources_dir\"")
    "iOS bootstrap should still fall back to opam switch sources for external packages"
;;

let test_swiftui_lazy_list_refreshes_visible_rows_after_provider_update () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"lazyListVersion")
    "SwiftUI lazy lists should publish a version each time OCaml updates the row provider";
  require
    (contains source ~substring:"lazyListInvalidatedIndices")
    "SwiftUI lazy lists should receive the exact stale row indices from the OCaml provider";
  require
    (contains source ~substring:"invalidatedIndexPointer")
    "the OCaml-to-Swift bridge should pass stale indices with lazy list row updates";
  require
    (contains source ~substring:"node.lazyListInvalidatedIndices.contains(sourceIndex)")
    "lazy row positions should mark only invalidated source indices for refresh";
  require
    (not (contains source ~substring:"version: node.lazyListVersion"))
    "SwiftUI lazy rows should not receive the global provider version because append-only \
     pagination should not re-evaluate every retained row body";
  require
    (not (contains source ~substring:"totalRows: node.lazyListRowCount"))
    "SwiftUI lazy rows should not receive the global row count because append-only \
     pagination should not re-evaluate every retained row body";
  require
    (not (contains source ~substring:".onChange(of: version)"))
    "SwiftUI lazy rows should not observe the global provider version; invalidated rows \
     should refresh through their own appear/load path";
  require
    (contains source
       ~substring:
         "refreshGeneration: node.lazyListInvalidatedIndices.contains(sourceIndex)")
    "SwiftUI lazy rows should receive a per-row refresh generation so only invalidated \
     rows refresh after provider updates";
  require
    (contains source
       ~substring:
         "key: bonsaiNativeLazyRowKey(owner: node, providerId: providerId, index: sourceIndex)")
    "SwiftUI lazy row cache identity should use the stable provider row key";
  require
    (not (contains source ~substring:"key: \"\\(node.lazyListVersion):\\(index)\""))
    "global provider version should not be part of every row key because append-only \
     pagination should not invalidate all visible row caches";
  require
    (contains source ~substring:"let owner: BonsaiNativeNode")
    "SwiftUI lazy row wrappers should not observe the whole list owner";
  require
    (not (contains source ~substring:"@ObservedObject var owner: BonsaiNativeNode"))
    "list-level lazy list publishes should not invalidate every retained row wrapper";
  require
    (not (contains source ~substring:"@State private var child: BonsaiNativeNode?"))
    "SwiftUI lazy row wrappers should not store rendered child nodes in row-local state \
     because List cells are reused while scrolling";
  require
    (not (contains source ~substring:"@State private var isVisible"))
    "lazy row visibility should not be SwiftUI state because every List appear/disappear \
     would re-evaluate row bodies while scrolling";
  require
    (not (contains source ~substring:"@State private var releaseToken"))
    "lazy row release tokens should not be SwiftUI state because release scheduling is \
     not visual state";
  require
    (not (contains source ~substring:"@State private var focusedDisappearToken"))
    "focused-row disappear tokens should not be SwiftUI state because scroll lifecycle \
     bookkeeping should not invalidate row bodies";
  require
    (contains source ~substring:"private final class BonsaiNativeLazyListRowState")
    "non-visual lazy row lifecycle bookkeeping should live in a reference state holder";
  require
    (contains source ~substring:"private var cachedRenderedChild: BonsaiNativeNode?")
    "SwiftUI lazy row wrappers should read rendered child nodes from the owner row cache";
  require
    (contains source ~substring:".onChange(of: refreshGeneration)")
    "SwiftUI lazy rows should refresh when OCaml invalidates their own source index, even \
     if the row key is unchanged";
  require
    (contains source ~substring:"private func refreshRow()")
    "SwiftUI lazy rows should call the OCaml row provider again for visible cached rows";
  require
    (contains source ~substring:"let nextVersion = Int(version)")
    "SwiftUI lazy list provider updates should use the OCaml renderer's version instead \
     of bumping on every append";
  require
    (contains source
       ~substring:
         "if !providerInvalidatedIndices.isEmpty && node.lazyListVersion != nextVersion")
    "append-only lazy list provider updates should not publish lazyListVersion because \
     no visible row needs a refresh";
  require
    (not (contains source ~substring:"if node.lazyListVersion != nextVersion"))
    "lazy list provider updates should not publish a version for pure row-count changes";
  require
    (not (contains source ~substring:"node.lazyListVersion &+= 1"))
    "SwiftUI lazy list provider updates should not refresh visible rows for pure append \
     updates"
;;

let test_swiftui_lazy_list_retained_cache_stays_small () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"owner.lazyListVisibleIndices.count")
    "SwiftUI lazy list retained cache should scale with the number of visible rows";
  require
    (contains source ~substring:"min(384, max(128, visibleBudget * 8))")
    "SwiftUI lazy lists should keep enough nearby rows for fast scrolling while \
     preserving a bounded cache for very large lists";
  require
    (not (contains source ~substring:"let maxRetainedRows = 32"))
    "SwiftUI lazy list retained cache should not be almost the same size as one visible \
     screen on iPhone"
;;

let test_swiftui_lazy_list_logs_ui_row_lifecycle_counts () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"BonsaiNativeRowLifecycleProbeView(listID: listID)")
    "lazy row lifecycle logging should use a platform view probe attached to each row";
  require
    (contains source ~substring:"bonsaiNativeLifecycleProbeBackground")
    "lifecycle probes should only be attached when list debug logging is enabled";
  require
    (not (contains source ~substring:"BonsaiNativeLazyRowLifecycleToken"))
    "lazy row lifecycle logging should not use StateObject tokens because they change row \
     retention behavior";
  require
    (not (contains source ~substring:"BonsaiNativeMediaViewLifecycleToken"))
    "media lifecycle logging should not use StateObject tokens because they change media \
     retention behavior";
  require
    (contains source ~substring:"uiRowCreated(listID:")
    "lazy row wrappers should log creation so leaked SwiftUI/UI rows can be counted";
  require
    (contains source ~substring:"uiRowDestroyed(listID:")
    "lazy row wrappers should log destruction so retained UI rows can be distinguished \
     from retained OCaml provider rows";
  require
    (contains source ~substring:"ui_row_live=")
    "list_perf logs should include currently live SwiftUI row wrappers";
  require
    (contains source ~substring:"ui_row_created=")
    "list_perf logs should include cumulative SwiftUI row wrapper creation count";
  require
    (contains source ~substring:"ui_row_destroyed=")
    "list_perf logs should include cumulative SwiftUI row wrapper destruction count";
  require
    (contains source ~substring:"media_view_live=")
    "list_perf logs should include live media view count because WebKit/image rows can \
     leak separately from text rows";
  require
    (contains source ~substring:"body=")
    "list_perf logs should include lazy row body evaluation count so SwiftUI invalidation \
     can be separated from OCaml row rendering"
;;

let test_swiftui_lazy_list_uses_stable_row_keys_for_identity () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"bonsaiNativeLazyRowKeyCallback")
    "lazy provider lists should expose the OCaml row key to SwiftUI";
  require
    (contains source ~substring:"let key: String")
    "lazy provider row views should carry the stable row key";
  require
    (contains source ~substring:"guard owner.lazyListRowKeyByIndex[index] == key")
    "lazy provider row views should use the stable row key to guard cached content";
  require
    (contains source ~substring:"&& lhs.key == rhs.key")
    "lazy provider row equality should include the stable row key";
  require
    (not (contains source ~substring:"key: \"\\(index)\""))
    "lazy provider row cache keys should not be derived from the mutable row index"
;;

let test_swiftui_lazy_list_disappear_defers_detach_without_releasing_cache () =
  let source = read_file swiftui_source_path in
  require
    (not (contains source ~substring:"DispatchQueue.main.asyncAfter(deadline: .now() + 0.8)"))
    "lazy row disappear should not enqueue deferred detach work during scroll";
  require
    (not (contains source ~substring:"rowState.releaseToken"))
    "lazy row disappear should not carry release tokens after cache trimming owns release";
  require
    (contains source ~substring:"releaseCachedRow(index: candidate")
    "retained cache trimming should still release rows when the cache exceeds its budget"
;;

let test_swiftui_lazy_list_blurs_focused_row_after_disappear () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"listFocusedRowDisappearEventId")
    "SwiftUI lists should store a native event for the focused row leaving the viewport";
  require
    (contains source ~substring:"scheduleFocusedRowDisappear()")
    "lazy row disappear should schedule focused-row blur independently of cache release";
  require
    (contains source ~substring:"guard owner.listFocusedRowIndex == index else { return }")
    "only the focused lazy row should trigger the disappear event";
  require
    (contains source ~substring:"model.sendClick(owner.listFocusedRowDisappearEventId)")
    "focused lazy row disappearance should notify OCaml so editing exits when the row \
     leaves the visible viewport";
  require
    (contains source ~substring:"blurFocusedRowForUserScroll")
    "user scrolling the list should also blur the focused row because SwiftUI may keep \
     offscreen rows alive"
;;

let test_swiftui_lazy_list_setters_skip_unchanged_published_values () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"if !node.children.isEmpty {\n    node.children = []")
    "lazy list updates should not publish an unchanged empty children array on every \
     render";
  require
    (contains source ~substring:"if node.lazyListProviderId != providerId")
    "lazy list updates should not republish the same provider id";
  require
    (contains source
       ~substring:
         "if !providerInvalidatedIndices.isEmpty && node.lazyListVersion != nextVersion")
    "lazy list updates should not republish the same provider version and should skip \
     version publishes for append-only updates";
  require
    (contains source ~substring:"if node.lazyListRowCount != rowCount")
    "lazy list updates should not republish the same row count";
  require
    (contains source ~substring:"if node.listRefreshEventId != nextRefreshEventId")
    "list behavior updates should not republish unchanged refresh callbacks";
  require
    (contains source ~substring:"if node.listFocusedRowIndex != nextFocusedRowIndex")
    "focused row updates should not publish when focus did not change"
;;

let test_swiftui_navigation_setter_skips_unchanged_published_values () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"if node.navigationPath != nextPath")
    "navigation stack updates should not republish an unchanged path on every render";
  require
    (contains source ~substring:"if node.navigationPathEventId != nextEventId")
    "navigation stack updates should not republish an unchanged path callback";
  require
    (contains source ~substring:"if node.navigationDestinationIds != nextDestinationIds")
    "navigation stack updates should not republish unchanged destination ids"
;;

let test_swiftui_change_events_emit_immediately_on_main_thread () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"private func dispatchEvent(animation: Animation? = nil, _ emit: @escaping () -> Void)")
    "SwiftUI event dispatch should share one main-thread-aware path";
  require
    (contains source ~substring:"if Thread.isMainThread {\n      performEmit()")
    "SwiftUI change events triggered by native gestures should emit immediately on the \
     main thread instead of waiting one extra runloop";
  require
    (contains source ~substring:"DispatchQueue.main.async(execute: performEmit)")
    "SwiftUI event dispatch should still hop to the main thread when called from \
     background callbacks"
;;

let test_swiftui_delete_at_start_does_not_use_keyboard_handoff_delay () =
  let source = read_file swiftui_source_path in
  require
    (not (contains source ~substring:"BonsaiNativeKeyboardHandoff"))
    "delete-at-start should not use a hidden text field to hold first responder";
  require
    (not (contains source ~substring:"retainKeyboard(from:"))
    "delete-at-start should let the newly focused row become first responder";
  require
    (not (contains source ~substring:"asyncAfter(deadline: .now() + 0.05)"))
    "delete-at-start focus should not rely on short timed retries";
  require
    (not (contains source ~substring:"asyncAfter(deadline: .now() + 0.15)"))
    "delete-at-start focus should not rely on row replacement timeout retries";
  require
    (not (contains source ~substring:"asyncAfter(deadline: .now() + 0.4)"))
    "delete-at-start focus should not rely on hidden keyboard handoff timeout";
  require
    (contains source ~substring:"func requestFocus()")
    "delete-aware text fields should keep an explicit focus request";
  require
    (contains source ~substring:"guard !wantsFocus || !isFirstResponder else { return }")
    "focused text fields should not enqueue focus retries on every render while already \
     first responder";
  require
    (contains source ~substring:"if node.isTextFieldFocused != isFocused")
    "text-field focus setters should not publish unchanged focus values";
  require
    (contains source ~substring:"override func didMoveToWindow()")
    "delete-aware text fields should focus when the replacement row is mounted"
;;

let counter graph =
  let count, set_count = Apple.state graph ~key:"count" 0 in
  Apple.vstack
    [ Apple.text (string_of_int count)
    ; Apple.button "Increment" ~on_click:(set_count (count + 1))
    ]
;;

let test_event_rerenders_component_state () =
  Backend.reset ();
  let app = App.create counter in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require (Backend.find_text_exn root ~path:[ 0 ] = "0") "initial count should be 0";
  Backend.click_exn root ~path:[ 1 ];
  require (Backend.find_text_exn root ~path:[ 0 ] = "1") "click should rerender count"
;;

let test_scoped_state_is_independent () =
  let scoped key graph =
    Apple.scope graph ~key (fun graph ->
      let count, set_count = Apple.state graph ~key:"count" 0 in
      Apple.button (key ^ ":" ^ string_of_int count) ~on_click:(set_count (count + 1)))
  in
  Backend.reset ();
  let app =
    App.create (fun graph -> Apple.vstack [ scoped "a" graph; scoped "b" graph ])
  in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require (Backend.find_text_exn root ~path:[ 0 ] = "a:0") "initial a count should be 0";
  require (Backend.find_text_exn root ~path:[ 1 ] = "b:0") "initial b count should be 0";
  Backend.click_exn root ~path:[ 0 ];
  require (Backend.find_text_exn root ~path:[ 0 ] = "a:1") "a should update";
  require (Backend.find_text_exn root ~path:[ 1 ] = "b:0") "b should not update"
;;

let test_tab_selection_updates_state () =
  Backend.reset ();
  let component graph =
    let selected, set_selected = Apple.state graph ~key:"selected" "counter" in
    Apple.tab_view
      ~selected
      ~on_select:set_selected
      [ Apple.tab ~id:"counter" ~title:"Counter" (Apple.text "Counter")
      ; Apple.tab ~id:"search" ~title:"Search" ~role:Apple.Search (Apple.text "Search")
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  Backend.select_tab_exn root ~id:"search";
  require
    (Backend.find_text_exn root ~path:[ 1 ] = "Search")
    "tab selection should keep tab content mounted"
;;

let test_sidebar_history_actions_are_separate_and_clickable () =
  Backend.reset ();
  let component graph =
    let selected, set_selected = Apple.state graph ~key:"selected" "compose" in
    let event, set_event = Apple.state graph ~key:"event" "none" in
    Apple.sidebar_split
      ~title:"Workspace"
      ~actions:
        [ Apple.sidebar_action
            ~id:"queue"
            ~title:"Queue"
            ~system_image:"tray"
            ~on_click:(set_event "queue")
            ()
        ]
      ~history_title:"Recent"
      ~history_actions:
        [ Apple.sidebar_action
            ~id:"history-item-1"
            ~title:"Open sample item"
            ~subtitle:"Preview: Open sample item"
            ~on_click:(set_event "history-item")
            ~menu_actions:
              [ { title = "Rename"
                ; system_image = Some "pencil"
                ; style = Apple.Default
                ; on_click = set_event "rename"
                }
              ]
            ()
        ]
      ~selected
      ~on_select:set_selected
      [ Apple.tab ~id:"compose" ~title:"Compose" (Apple.text event) ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"sidebar-actions=[queue:Queue:tray]")
    "primary sidebar action should render separately";
  require
    (contains rendered ~substring:"sidebar-history-title=Recent")
    "history title should render";
  require
    (contains
       rendered
       ~substring:
         "sidebar-history-actions=[history-item-1:Open sample item:preview=Preview: Open \
          sample item:menu=[Rename:pencil:default]]")
    "history action should render separately";
  require
    (contains rendered ~substring:"sidebar-history-menu-presentation=context-menu")
    "history actions should use Swift-style context menus instead of replacing the row \
     button";
  Backend.click_sidebar_history_action_exn root ~id:"history-item-1";
  require
    (Backend.find_text_exn root ~path:[ 0 ] = "history-item")
    "history action click should run";
  Backend.click_sidebar_history_action_menu_action_exn
    root
    ~id:"history-item-1"
    ~title:"Rename";
  require
    (Backend.find_text_exn root ~path:[ 0 ] = "rename")
    "history action menu click should run"
;;

let test_sidebar_actions_can_keep_compact_drawer_open () =
  Backend.reset ();
  let component graph =
    let selected, set_selected = Apple.state graph ~key:"selected" "library" in
    let event, set_event = Apple.state graph ~key:"event" "none" in
    Apple.sidebar_split
      ~title:"Workspace"
      ~header_action:
        (Apple.sidebar_action
           ~id:"account"
           ~title:"Account"
           ~avatar_initial:"?"
           ~closes_sidebar:false
           ~on_click:(set_event "settings")
           ())
      ~actions:
        [ Apple.sidebar_action
            ~selects_tab:"compose"
            ~id:"queue"
            ~title:"Queue"
            ~system_image:"tray"
            ~on_click:(set_event "queue")
            ()
        ; Apple.sidebar_action
            ~id:"library"
            ~title:"Library"
            ~system_image:"rectangle.stack"
            ~on_click:(set_event "library")
            ()
        ; Apple.sidebar_action
            ~id:"run-action"
            ~title:"Run"
            ~system_image:"rectangle.stack.badge.play"
            ~closes_sidebar:false
            ~on_click:(set_event "run")
            ()
        ]
      ~selected
      ~on_select:set_selected
      [ Apple.tab ~id:"library" ~title:"Library" (Apple.text event)
      ; Apple.tab ~id:"compose" ~title:"Compose" (Apple.text event)
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"queue:Queue:tray:selects=compose")
    "sidebar action should expose the route it selects when it differs from its action id";
  require
    (contains rendered ~substring:"sidebar-header-action=account:Account:avatar=?:keeps-sidebar")
    "header action should expose that it keeps the compact sidebar open";
  require
    (contains
       rendered
       ~substring:"run-action:Run:rectangle.stack.badge.play:keeps-sidebar")
    "sheet-style sidebar actions should expose that they keep the compact sidebar open";
  Backend.click_sidebar_header_action_exn root ~id:"account";
  require
    (String.equal (Backend.find_text_exn root ~path:[ 0 ]) "settings")
    "header action click should still run";
  Backend.click_sidebar_action_exn root ~id:"run-action";
  require
    (String.equal (Backend.find_text_exn root ~path:[ 0 ]) "run")
    "non-closing sidebar action click should still run"
;;

let test_compact_sidebar_top_bar_uses_system_toolbar_item_chrome () =
  Backend.reset ();
  let component graph =
    let selected, set_selected = Apple.state graph ~key:"selected" "library" in
    Apple.sidebar_split
      ~title:"Workspace"
      ~selected
      ~on_select:set_selected
      [ Apple.tab ~id:"library" ~title:"Library" (Apple.text "Library") ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains
       rendered
       ~substring:
         "compact-top-bar=system-toolbar toolbaritem-leading=sidebar-toggle \
          toolbaritem-title=navigation-title")
    "compact top bar should use system toolbar items like the Swift header";
  require
    (contains rendered ~substring:"toolbaritem-leading-chrome=liquid-glass")
    "compact sidebar leading toolbar item should use the same liquid glass chrome as \
     Swift";
  require
    (contains
       rendered
       ~substring:
         "sidebar-safe-area-padding=swift top=max-safe-area-plus-5-or-54 \
          bottom=max-safe-area-or-34")
    "compact sidebar should use the same safe-area padding as the Swift drawer";
  require
    (contains
       rendered
       ~substring:"sidebar-shell-background=home-body-ignores-safe-area-outside-clip")
    "compact sidebar shell background should cover the top and bottom safe areas";
  require
    (contains
       rendered
       ~substring:"sidebar-bottom-controls=safe-area-inset keyboard-padding top-padding=10")
    "compact sidebar bottom controls should keep Swift safe-area inset layout while \
     padding above the keyboard";
  require
    (contains
       rendered
       ~substring:
         "sidebar-scroll-disabled=dragging content-scroll-disabled=open-or-dragging")
    "compact sidebar should disable scroll during the same drawer states as Swift";
  require
    (contains
       rendered
       ~substring:
         "sidebar-route-selection-animation=swift-interactive-spring \
          route-change-and-close")
    "compact sidebar route selection should animate route changes and drawer close";
  require
    (contains
       rendered
       ~substring:"sidebar-edge-gesture=enabled-when-compact-top-bar-visible")
    "compact sidebar edge gesture should follow the same route gating as Swift";
  require
    (contains
       rendered
       ~substring:
         "sidebar-open-close=swift-interactive-spring keyboard-dismiss haptic-on-change")
    "compact sidebar should use the same open and close interaction behavior as Swift"
;;

let test_compact_sidebar_bottom_search_tracks_keyboard () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"sidebarKeyboardBottomPadding")
    "compact sidebar bottom search should add keyboard-aware bottom padding instead of \
     staying behind the keyboard";
  require
    (contains source ~substring:"keyboardWillChangeFrameNotification")
    "compact sidebar should observe keyboard frame changes for the custom full-screen \
     drawer";
  require
    (contains source ~substring:".padding(.bottom, sidebarKeyboardBottomPadding)")
    "compact sidebar bottom search should relayout above the keyboard instead of only \
     applying a visual offset"
;;

let test_compact_sidebar_keyboard_tracking_stays_on_drawer_root () =
  let source = read_file swiftui_source_path in
  let split_start =
    match substring_index source ~substring:"private var compactSidebarSplitView" ~from:0 with
    | Some index -> index
    | None -> failwith "compactSidebarSplitView not found"
  in
  let content_start =
    match substring_index source ~substring:"private var compactSidebarContent" ~from:split_start with
    | Some index -> index
    | None -> failwith "compactSidebarContent not found"
  in
  let split_source = String.sub source split_start (content_start - split_start) in
  let sidebar_content_start =
    match substring_index split_source ~substring:"compactSidebarContent" ~from:0 with
    | Some index -> index
    | None -> failwith "compactSidebarContent call not found"
  in
  let route_detail_start =
    match substring_index split_source ~substring:"ZStack(alignment: .top)" ~from:sidebar_content_start with
    | Some index -> index
    | None -> failwith "selected route detail stack not found"
  in
  let sidebar_content_source =
    String.sub split_source sidebar_content_start (route_detail_start - sidebar_content_start)
  in
  require
    (not
       (contains
          sidebar_content_source
          ~substring:"UIResponder.keyboardWillChangeFrameNotification"))
    "compact sidebar keyboard notifications should be attached to the drawer root, not \
     the sidebar content subtree; when the focused search field changes keyboard layout \
     the content subtree can stop reporting the correct overlap";
  require
    (contains source ~substring:".padding(.bottom, sidebarKeyboardBottomPadding)")
    "compact sidebar bottom controls should use keyboard padding so the search field \
     gets relaid out above the keyboard instead of only being visually offset";
  require
    (not (contains source ~substring:".offset(y: -sidebarKeyboardBottomPadding)"))
    "compact sidebar bottom controls should not rely on a pure visual offset because it \
     can still leave the search field under the keyboard interaction region"
;;

let test_compact_sidebar_keeps_presented_sheets_interactive () =
  let source = read_file swiftui_source_path in
  require
    (not (contains source ~substring:".disabled(isCompactSidebarOpen)"))
    "compact sidebar should not disable the selected route subtree because app-level \
     sheets are attached there in the OCaml backend; disabling that subtree makes \
     modal sheets open but do not respond to taps"
;;

let test_multiple_sheet_modifiers_install_only_presented_sheet () =
  let source = read_file swiftui_backend_source_path in
  require
    (contains source ~substring:"pending_sheet")
    "SwiftUI backend should arbitrate multiple sheet modifiers through a pending sheet \
     instead of letting a later false sheet overwrite an earlier presented one";
  require
    (contains source ~substring:"install_pending_sheet")
    "SwiftUI backend should install the chosen sheet once after scanning modifiers"
;;

let test_sheet_content_host_fills_sheet_background () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"bonsaiSheetContentHost")
    "SwiftUI sheets should wrap native content in a common host container";
  require
    (contains
       source
       ~substring:".frame(maxWidth: .infinity, maxHeight: .infinity")
    "SwiftUI sheet host should fill the sheet instead of letting intrinsic-width content \
     leave uncovered side gutters";
  require
    (contains source ~substring:".background(bonsaiHomeBodyBackground")
    "SwiftUI sheet host should paint the app body background across the full sheet"
;;

let test_sheet_content_host_preserves_leading_content_alignment () =
  let source = read_file swiftui_source_path in
  let host_start =
    match substring_index source ~substring:"private func bonsaiSheetContentHost" ~from:0 with
    | Some index -> index
    | None -> failwith "bonsaiSheetContentHost not found"
  in
  let detents_start =
    match substring_index source ~substring:"private var sheetPresentationDetents" ~from:host_start with
    | Some index -> index
    | None -> failwith "sheetPresentationDetents not found after bonsaiSheetContentHost"
  in
  let host_source = String.sub source host_start (detents_start - host_start) in
  require
    (contains host_source ~substring:"ZStack(alignment: .topLeading)")
    "SwiftUI sheet host should paint a full-width background without forcing sheet \
     content into the horizontal center";
  require
    (contains host_source ~substring:"alignment: .topLeading")
    "SwiftUI sheet host should keep sheet content leading-aligned while the host \
     background fills the sheet"
;;

let test_custom_label_buttons_use_full_label_hit_target () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"customButtonLabelHitTarget")
    "custom label buttons should wrap their label content in a shared full-frame hit \
     target";
  require
    (contains source ~substring:".contentShape(Rectangle())")
    "custom label buttons should use the whole label frame as the tappable area instead \
     of only the visible glyphs"
;;

let test_image_semantic_color_renders () =
  Backend.reset ();
  let component _graph =
    Apple.hstack
      [ Apple.image ~color:Apple.Green "checkmark.circle.fill"
      ; Apple.image ~color:Apple.Red "xmark.circle.fill"
      ; Apple.image "circle"
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"text=\"checkmark.circle.fill\" image-color=green")
    "green image color should render";
  require
    (contains rendered ~substring:"text=\"xmark.circle.fill\" image-color=red")
    "red image color should render";
  require
    (not (contains rendered ~substring:"text=\"circle\" image-color="))
    "default image color should not render"
;;

let test_button_label_renders_custom_clickable_content () =
  Backend.reset ();
  let component graph =
    let selected, set_selected = Apple.state graph ~key:"selected" false in
    Apple.button_label
      ~is_enabled:(not selected)
      ~on_click:(set_selected true)
      (Apple.hstack
         ~spacing:10.
         [ Apple.image ~color:Apple.Green "checkmark.circle.fill"
         ; Apple.text "Alpha"
         ; Apple.spacer ()
         ])
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"button#")
    "custom label button should render as a button";
  require
    (contains rendered ~substring:"stack(horizontal)")
    "custom label button should keep its horizontal label content";
  require
    (contains rendered ~substring:"text=\"checkmark.circle.fill\" image-color=green")
    "custom label button should render its image child";
  Backend.click_exn root ~path:[];
  require
    (contains (Backend.show root) ~substring:"button#")
    "button should remain mounted after click";
  require
    (contains (Backend.show root) ~substring:" disabled")
    "click should run the button action"
;;

let test_hide_list_row_separator_modifier_renders () =
  Backend.reset ();
  let app =
    App.create (fun _graph ->
      Apple.list [ "row" ]
        ~key:(fun value -> value)
        ~row:(fun value -> Apple.text value |> Apple.hide_list_row_separator))
  in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains (Backend.show root) ~substring:"hide-list-row-separator")
    "row separator visibility should be exposed as a render modifier"
;;

let test_text_field_delete_backward_at_start_event () =
  Backend.reset ();
  let component graph =
    let deleted, set_deleted = Apple.state graph ~key:"deleted" false in
    Apple.vstack
      [
        Apple.text_field ~text:""
          ~placeholder:"Block"
          ~on_change:(fun _ -> Apple.Action.ignore)
          ~on_delete_backward_at_start:(set_deleted true)
          ();
        Apple.text (if deleted then "deleted" else "idle");
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  Backend.delete_backward_at_start_text_exn root ~path:[ 0 ];
  App.flush_and_render app;
  let rendered =
    match App.view app with
    | Some root -> Backend.show root
    | None -> failwith "app did not render"
  in
  require
    (contains rendered ~substring:"text=\"deleted\"")
    "delete backward at the start of a text field should dispatch its event"
;;

let test_text_field_focus_renders () =
  Backend.reset ();
  let component _graph =
    Apple.text_field ~text:"Focused" ~placeholder:"Block" ~is_focused:true
      ~on_change:(fun _ -> Apple.Action.ignore)
      ()
  in
  let app = App.create component in
  App.flush_and_render app;
  let rendered =
    match App.view app with
    | Some root -> Backend.show root
    | None -> failwith "app did not render"
  in
  require (contains rendered ~substring:"text-field#") rendered;
  require
    (contains rendered ~substring:" focused")
    "focused text field should expose focus state to the backend"
;;

let test_text_field_native_clear_button_renders_and_clears () =
  Backend.reset ();
  let component graph =
    let text, set_text = Apple.state graph ~key:"text" "Draft" in
    Apple.text_field
      ~style:Apple.Pill
      ~clear_button:Apple.While_editing
      ~text
      ~placeholder:"New item"
      ~on_change:set_text
      ()
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains (Backend.show root) ~substring:"native-clear-button=while-editing")
    "text fields should expose native clear-button mode instead of requiring app-level \
     trailing buttons";
  Backend.clear_text_exn root ~path:[];
  require
    (contains (Backend.show root) ~substring:"text=\"\"")
    "native clear button should dispatch the text field change handler with an empty \
     value"
;;

let test_button_renders_bordered_prominent_style () =
  Backend.reset ();
  let component _graph =
    Apple.button
      ~style:Apple.Bordered_prominent
      ~system_image:"eye"
      "Reveal answer"
      ~on_click:Apple.Action.ignore
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains
       (Backend.show root)
       ~substring:"text=\"Reveal answer\" image=eye button-style=bordered-prominent")
    "bordered prominent button style should be visible to native renderers"
;;

let test_button_renders_plain_style () =
  Backend.reset ();
  let component _graph =
    Apple.button
      ~style:Apple.Plain
      ~system_image:"arrow.up"
      ~is_title_visible:false
      "Send"
      ~on_click:Apple.Action.ignore
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains
       (Backend.show root)
       ~substring:"text=\"Send\" image=arrow.up button-style=plain title-hidden")
    "plain button style should be visible to native renderers"
;;

let test_on_appear_event_rerenders_component_state () =
  Backend.reset ();
  let component graph =
    let count, set_count = Apple.state graph ~key:"count" 0 in
    Apple.vstack
      [ Apple.text (string_of_int count)
      ; Apple.text "sentinel" |> Apple.on_appear ~on_appear:(set_count (count + 1))
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require (Backend.find_text_exn root ~path:[ 0 ] = "0") "initial count should be 0";
  Backend.appear_exn root ~path:[ 1 ];
  require (Backend.find_text_exn root ~path:[ 0 ] = "1") "appear should rerender count"
;;

let test_searchable_renders_prompt () =
  Backend.reset ();
  let component _graph =
    Apple.navigation_stack
      [ Apple.text "Items"
        |> Apple.searchable ~text:"" ~prompt:"Search items" ~on_change:(fun _ ->
          Apple.Action.ignore)
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains (Backend.show root) ~substring:"searchable-prompt=\"Search items\"")
    "searchable prompt should be visible to native renderers"
;;

let test_picker_renders_segmented_style () =
  Backend.reset ();
  let component _graph =
    Apple.picker
      ~style:Apple.Segmented
      ~title:"Item type"
      ~selected:"basic"
      ~on_select:(fun _ -> Apple.Action.ignore)
      [ Apple.picker_option ~id:"basic" ~title:"Basic"
      ; Apple.picker_option ~id:"single" ~title:"Single"
      ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains (Backend.show root) ~substring:"picker-style=segmented")
    "segmented picker style should be visible to native renderers"
;;

let test_liquid_glass_panel_renders () =
  Backend.reset ();
  let component _graph =
    Apple.text "Review"
    |> Apple.liquid_glass_panel
         ~corner_radius:22.
         ~is_transparent:true
         ~tint_color:Apple.Green
         ~tint_opacity:0.1
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains
       rendered
       ~substring:"panel=liquid-glass corner-radius=22 transparent=true tint=green:0.1")
    "liquid glass panel should be visible to native renderers"
;;

let test_pill_text_field_uses_liquid_glass_chrome () =
  Backend.reset ();
  let component _graph =
    Apple.text_field
      ~style:Apple.Pill
      ~text:""
      ~placeholder:"New item"
      ~on_change:(fun _ -> Apple.Action.ignore)
      ()
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains
       rendered
       ~substring:
         "placeholder=\"New item\" style=pill chrome=liquid-glass corner-radius=26")
    "pill text fields should render with Swift-style liquid glass chrome"
;;

let test_plain_text_field_renders_plain_style () =
  Backend.reset ();
  let component _graph =
    Apple.text_field
      ~style:Apple.Plain_text
      ~text:""
      ~placeholder:"Search"
      ~on_change:(fun _ -> Apple.Action.ignore)
      ()
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"placeholder=\"Search\" style=plain")
    "plain text fields should expose SwiftUI plain text field style"
;;

let test_frame_renders_max_width () =
  Backend.reset ();
  let component _graph =
    Apple.text "Full width" |> Apple.frame ~max_width:infinity
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"frame:_x_:inf")
    "frame should expose max width for SwiftUI maxWidth layout"
;;

let test_file_image_can_render_swift_image_file_style () =
  Backend.reset ();
  let component _graph =
    Apple.image_file ~max_height:180. ~corner_radius:8. "/tmp/preview.png"
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"source=file")
    "file images should render from the filesystem";
  require
    (contains rendered ~substring:"image-style=max-height:\"180\":corner-radius:\"8\"")
    "file images should expose Swift image file sizing and clipping"
;;

let test_swiftui_image_view_supports_remote_urls () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"AsyncImage(url:")
    "SwiftUI file image nodes should render remote image URLs with AsyncImage"
;;

let test_swiftui_image_view_reserves_requested_height_before_load () =
  let source = read_file swiftui_source_path in
  require
    (count_substrings source ~substring:"minHeight: node.imageMaxHeight" >= 3)
    "SwiftUI image views should reserve the requested image height before and after \
     loading so rows do not change height while scrolling"
;;

let test_swiftui_custom_view_supports_youtube_webkit_iframes () =
  let source = read_file swiftui_source_path in
  require (contains source ~substring:"import WebKit") "YouTube iframes should use WebKit";
  require
    (contains source ~substring:"BonsaiNativeYouTubeIframeView")
    "custom youtube views should render through a dedicated WebKit view";
  require
    (contains source ~substring:"WKWebView")
    "custom youtube views should be backed by WKWebView";
  require
    (contains source ~substring:"youtubePayload")
    "custom views should recognize youtube payloads by kind"
;;

let test_youtube_iframe_does_not_steal_list_row_gestures () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"BonsaiNativeDeferredYouTubeIframeView(payload: payload)")
    "youtube iframe rows should render a lightweight preview first so scrolling does not \
     create WKWebView instances";
  require
    (contains source ~substring:"@State private var isLoaded = false")
    "youtube iframe previews should only create WebKit after an explicit user action";
  require
    (contains source ~substring:"BonsaiNativeYouTubeIframeView(payload: payload)")
    "loaded youtube iframes should not steal List row swipe or long-press move gestures";
  require
    (contains source ~substring:".allowsHitTesting(false)")
    "loaded youtube iframes should opt out of hit testing";
  require
    (contains source ~substring:"webView.isUserInteractionEnabled = false")
    "the underlying WKWebView should not receive row gesture touches"
;;

let test_swiftui_prefers_inter_for_typography () =
  let source = read_file swiftui_source_path in
  require
    (contains source ~substring:"private let bonsaiNativePreferredFontFamily = \"Inter\"")
    "SwiftUI runtime should define Inter as the preferred app font family";
  require
    (contains source ~substring:"Font.custom(bonsaiNativePreferredFontFamily")
    "SwiftUI runtime should use Font.custom so Inter is preferred when available";
  require
    (contains source ~substring:"private func textFont(_ style: Int32, weight: Int32) -> Font")
    "text nodes should resolve style and weight through the Inter-preferred font helper";
  require
    (contains source ~substring:".font(textFont(node.textStyle, weight: node.textWeight))")
    "label text should use the Inter-preferred font helper instead of direct system fonts";
  require
    (contains source ~substring:".font(bonsaiNativePreferredFont(size:")
    "custom-sized runtime text should use the Inter-preferred font helper"
;;

let test_keyboard_dismiss_controls_renders () =
  Backend.reset ();
  let component _graph =
    Apple.form
      [ Apple.section
          ~key:"Fields"
          [ Apple.text_field ~text:"" ~on_change:(fun _ -> Apple.Action.ignore) () ]
      ]
    |> Apple.keyboard_dismiss_controls
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains (Backend.show root) ~substring:"modifiers=[keyboard-dismiss-controls]")
    "keyboard dismiss controls should be visible to native renderers"
;;

let test_scroll_dismisses_keyboard_renders () =
  Backend.reset ();
  let component _graph =
    Apple.scroll_view (Apple.text "Transcript") |> Apple.scroll_dismisses_keyboard
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"modifiers=[scroll-dismisses-keyboard]")
    "scroll-only keyboard dismissal should render without keyboard toolbar controls";
  require
    (not (contains rendered ~substring:"keyboard-dismiss-controls"))
    "scroll-only keyboard dismissal should not add keyboard toolbar controls"
;;

let test_secondary_fill_panel_renders () =
  Backend.reset ();
  let component _graph =
    Apple.text "You: Hello" |> Apple.secondary_fill_panel ~corner_radius:18. ~opacity:0.12
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"panel=secondary-fill corner-radius=18 opacity=0.12")
    "secondary fill panel should expose Swift user message bubble chrome"
;;

let test_context_menu_renders_and_clicks_actions () =
  Backend.reset ();
  let copied = ref false in
  let component _graph =
    Apple.text "Message"
    |> Apple.context_menu
         [ { title = "Copy"
           ; system_image = Some "doc.on.doc"
           ; style = Apple.Default
           ; on_click = Apple.Action.of_thunk (fun () -> copied := true)
           }
         ; { title = "Delete"
           ; system_image = Some "trash"
           ; style = Apple.Destructive
           ; on_click = Apple.Action.ignore
           }
         ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains
       rendered
       ~substring:"context-menu=[Copy:doc.on.doc:default,Delete:trash:destructive]")
    "context menus should expose SwiftUI message actions";
  Backend.click_context_menu_action_exn root ~path:[] ~title:"Copy";
  require !copied "context menu actions should be clickable"
;;

let test_copy_text_to_clipboard_action_updates_test_clipboard () =
  Backend.reset ();
  Apple.copy_text_to_clipboard "Copied text" ();
  require
    (Backend.clipboard_text () = Some "Copied text")
    "copy text action should update the backend clipboard"
;;

let test_copy_image_file_to_clipboard_action_updates_test_clipboard () =
  Backend.reset ();
  Apple.copy_image_file_to_clipboard "/tmp/photo.png" ();
  require
    (Backend.clipboard_image_file () = Some "/tmp/photo.png")
    "copy image file action should update the backend clipboard image file"
;;

let test_toggle_audio_file_playback_action_updates_test_playback_state () =
  Backend.reset ();
  Apple.toggle_audio_file_playback "/tmp/recording.m4a" ();
  require
    (Backend.playing_audio_file () = Some "/tmp/recording.m4a")
    "toggle audio action should start playback for the file";
  Apple.toggle_audio_file_playback "/tmp/recording.m4a" ();
  require
    (Option.is_none (Backend.playing_audio_file ()))
    "toggle audio action should pause the currently playing file";
  Apple.toggle_audio_file_playback "/tmp/other.m4a" ();
  require
    (Backend.playing_audio_file () = Some "/tmp/other.m4a")
    "toggle audio action should switch to a different file"
;;

let test_audio_recording_actions_update_testing_backend () =
  Backend.reset ();
  require
    (not (Backend.is_audio_recording ()))
    "audio recorder should start idle in the testing backend";
  Apple.start_audio_recording ();
  require (Backend.is_audio_recording ()) "start recording action should mark recording";
  let result = Apple.stop_audio_recording_and_transcribe () in
  require
    (not (Backend.is_audio_recording ()))
    "stop recording action should return the testing backend to idle";
  require
    (String.equal result.transcript "Voice note")
    "stop recording should return the transcript";
  require
    (String.equal result.local_path "/tmp/voice-note.m4a")
    "stop recording should return the audio file path";
  require
    (String.equal result.filename "voice-note.m4a")
    "stop recording should return the audio filename";
  require
    (String.equal result.content_type "audio/mp4")
    "stop recording should return the audio content type";
  require (result.byte_size = 42) "stop recording should return the byte size"
;;

let test_toolbar_item_can_render_share_link () =
  Backend.reset ();
  let component _graph =
    Apple.text "Preview"
    |> Apple.toolbar
         [ Apple.toolbar_item
             ~id:"share"
             ~title:"Share"
             ~system_image:"square.and.arrow.up"
             ~is_title_visible:false
             ~share_url:"file:///tmp/photo.png"
             ~on_click:Apple.Action.ignore
             ()
         ]
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains
       (Backend.show root)
       ~substring:
         "toolbar=[share:Share:enabled:image=square.and.arrow.up:title-hidden:share-url=file:///tmp/photo.png]")
    "toolbar share items should expose the ShareLink URL";
  require
    (contains (Backend.show root) ~substring:"toolbar-presentation=system-toolbaritem")
    "toolbar actions should render through system ToolbarItem chrome";
  require
    (contains (Backend.show root) ~substring:"toolbaritem-chrome=system-default")
    "toolbar actions should keep the system ToolbarItem button chrome"
;;

let test_movable_rows_move_only_the_group_children () =
  Backend.reset ();
  let filteri list ~f =
    let rec loop index = function
      | [] -> []
      | value :: rest ->
        if f index value then value :: loop (index + 1) rest else loop (index + 1) rest
    in
    loop 0 list
  in
  let split_at index list =
    let rec loop remaining prefix rest =
      if remaining <= 0
      then List.rev prefix, rest
      else (
        match rest with
        | [] -> List.rev prefix, []
        | value :: tail -> loop (remaining - 1) (value :: prefix) tail)
    in
    loop index [] list
  in
  let choice_rows choices =
    match choices with
    | _question :: first :: second :: _hint :: _ -> [ first; second ]
    | _ -> []
  in
  let component graph =
    let choices, set_choices =
      Apple.state graph ~key:"choices" [ "Question"; "Beta"; "Alpha"; "Hint" ]
    in
    let move_choice ~from_index ~to_index =
      match choices with
      | question :: first :: second :: hint :: tail ->
        let rows = [ first; second ] in
        let item = List.nth rows from_index in
        let remaining = filteri rows ~f:(fun index _ -> index <> from_index) in
        let insert_index = if to_index > from_index then to_index - 1 else to_index in
        let before, after = split_at insert_index remaining in
        set_choices ([ question ] @ before @ [ item ] @ after @ (hint :: tail))
      | _ -> Apple.Action.ignore
    in
    Apple.list
      [ Apple.section
          ~key:"Item"
          [ Apple.text (List.nth choices 0)
          ; Apple.movable_rows
              ~edit_mode:true
              ~on_move:move_choice
              (choice_rows choices)
              ~key:(fun choice -> choice)
              ~row:Apple.text
          ; Apple.text (List.nth choices 3)
          ]
      ]
      ~key:Apple.section_key
      ~row:(fun node -> node)
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  let rendered = Backend.show root in
  require
    (contains rendered ~substring:"movable-rows#")
    "movable rows should render as a separate group inside a section";
  require
    (contains rendered ~substring:"edit-mode on-move")
    "movable rows should expose Swift edit mode and move behavior";
  Backend.move_rows_exn root ~path:[ 0; 1 ] ~from_index:0 ~to_index:2;
  require
    (contains (Backend.show root) ~substring:"text=\"Question\"")
    "non-movable rows should stay in the section";
  require
    (String.equal (Backend.find_text_exn root ~path:[ 0; 1; 0 ]) "Alpha")
    "moving the first movable row after the second should update that group"
;;

let test_list_marks_focused_row_for_native_scroll () =
  Backend.reset ();
  let component _graph =
    Apple.list
      ~focused_row_key:"third"
      [ "first"; "second"; "third" ]
      ~key:(fun row -> row)
      ~row:(fun row ->
        Apple.text_field
          ~text:row
          ~is_focused:(String.equal row "third")
          ~on_change:(fun _ -> Apple.Action.ignore)
          ())
  in
  let app = App.create component in
  App.flush_and_render app;
  let root =
    match App.view app with
    | Some root -> root
    | None -> failwith "app did not render"
  in
  require
    (contains (Backend.show root) ~substring:"focused-row=third")
    "focused list row should be exposed so the native list can keep it visible"
;;

let test_focused_row_scroll_keeps_row_visible_without_centering () =
  let source = read_file swiftui_source_path in
  require
    (not (contains source ~substring:"proxy.scrollTo(index, anchor: .center)"))
    "focused row scrolling should keep the row visible without forcing it to the center";
  require
    (contains source ~substring:"proxy.scrollTo(targetID)")
    "focused row scrolling should let SwiftUI choose the minimal scroll needed to reveal it"
;;

let () =
  test_event_rerenders_component_state ();
  test_scoped_state_is_independent ();
  test_tab_selection_updates_state ();
  test_sidebar_history_actions_are_separate_and_clickable ();
  test_sidebar_actions_can_keep_compact_drawer_open ();
  test_compact_sidebar_top_bar_uses_system_toolbar_item_chrome ();
  test_compact_sidebar_bottom_search_tracks_keyboard ();
  test_compact_sidebar_keyboard_tracking_stays_on_drawer_root ();
  test_compact_sidebar_keeps_presented_sheets_interactive ();
  test_multiple_sheet_modifiers_install_only_presented_sheet ();
  test_sheet_content_host_fills_sheet_background ();
  test_sheet_content_host_preserves_leading_content_alignment ();
  test_custom_label_buttons_use_full_label_hit_target ();
  test_navigation_value_links_do_not_preempt_system_push ();
  test_navigation_links_render_without_system_link_chrome ();
  test_compact_sidebar_close_paths_share_swift_animation ();
  test_native_list_uses_stable_node_identity ();
  test_list_virtualization_probe_does_not_log_per_row_events ();
  test_swiftui_library_builds_in_default_ios_context ();
  test_lazy_list_renders_rows_in_testing_backend ();
  test_lazy_list_patches_cached_rows ();
  test_lazy_list_renderer_uses_indexed_keys ();
  test_lazy_list_marks_moved_target_indices_stale ();
  test_swiftui_lazy_list_uses_native_row_provider ();
  test_swiftui_lazy_list_loads_rows_on_appear ();
  test_swiftui_lazy_list_uses_native_list_for_row_actions ();
  test_swiftui_native_list_disables_implicit_row_count_animation ();
  test_swiftui_lazy_list_move_updates_visible_order_immediately ();
  test_swiftui_list_debug_perf_log_uses_swift_safe_interpolation ();
  test_swiftui_frame_probe_can_run_without_list_debug_bookkeeping ();
  test_swiftui_frame_probe_logs_slow_lazy_row_renders ();
  test_swiftui_frame_probe_reports_scroll_phase_row_lifecycle_counts ();
  test_swiftui_host_model_is_only_observed_by_root_view ();
  test_swiftui_lazy_list_row_is_equatable ();
  test_swiftui_lazy_list_visible_index_tracking_stays_off_scroll_hot_path ();
  test_swiftui_lazy_list_does_not_keep_slot_collection ();
  test_swiftui_lazy_list_foreach_does_not_resolve_all_row_keys ();
  test_swiftui_lazy_list_disappear_does_not_enqueue_release_work ();
  test_ios_bootstrap_prefers_checkout_sources_for_local_packages ();
  test_swiftui_lazy_list_refreshes_visible_rows_after_provider_update ();
  test_swiftui_lazy_list_retained_cache_stays_small ();
  test_swiftui_lazy_list_logs_ui_row_lifecycle_counts ();
  test_swiftui_lazy_list_uses_stable_row_keys_for_identity ();
  test_swiftui_lazy_list_disappear_defers_detach_without_releasing_cache ();
  test_swiftui_lazy_list_blurs_focused_row_after_disappear ();
  test_swiftui_lazy_list_setters_skip_unchanged_published_values ();
  test_swiftui_navigation_setter_skips_unchanged_published_values ();
  test_swiftui_change_events_emit_immediately_on_main_thread ();
  test_swiftui_delete_at_start_does_not_use_keyboard_handoff_delay ();
  test_navigation_value_links_keep_primary_tap_for_link ();
  test_image_semantic_color_renders ();
  test_button_label_renders_custom_clickable_content ();
  test_hide_list_row_separator_modifier_renders ();
  test_text_field_delete_backward_at_start_event ();
  test_text_field_focus_renders ();
  test_text_field_native_clear_button_renders_and_clears ();
  test_button_renders_bordered_prominent_style ();
  test_button_renders_plain_style ();
  test_on_appear_event_rerenders_component_state ();
  test_searchable_renders_prompt ();
  test_picker_renders_segmented_style ();
  test_liquid_glass_panel_renders ();
  test_pill_text_field_uses_liquid_glass_chrome ();
  test_plain_text_field_renders_plain_style ();
  test_frame_renders_max_width ();
  test_file_image_can_render_swift_image_file_style ();
  test_swiftui_image_view_supports_remote_urls ();
  test_swiftui_image_view_reserves_requested_height_before_load ();
  test_swiftui_custom_view_supports_youtube_webkit_iframes ();
  test_youtube_iframe_does_not_steal_list_row_gestures ();
  test_swiftui_prefers_inter_for_typography ();
  test_keyboard_dismiss_controls_renders ();
  test_scroll_dismisses_keyboard_renders ();
  test_secondary_fill_panel_renders ();
  test_context_menu_renders_and_clicks_actions ();
  test_copy_text_to_clipboard_action_updates_test_clipboard ();
  test_copy_image_file_to_clipboard_action_updates_test_clipboard ();
  test_toggle_audio_file_playback_action_updates_test_playback_state ();
  test_audio_recording_actions_update_testing_backend ();
  test_toolbar_item_can_render_share_link ();
  test_movable_rows_move_only_the_group_children ();
  test_list_marks_focused_row_for_native_scroll ();
  test_focused_row_scroll_keeps_row_visible_without_centering ()
;;
