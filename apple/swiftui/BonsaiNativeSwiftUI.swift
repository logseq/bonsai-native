import SwiftUI
import UIKit

public typealias BonsaiNativeEventCallback = @convention(c) (Int32, UnsafePointer<CChar>?) -> Void
public typealias BonsaiNativeLaunchCallback =
  @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Bool

@objc(BonsaiNativeAppDelegate)
private final class BonsaiNativeAppDelegate: NSObject, UIApplicationDelegate {
  static var launchCallback: BonsaiNativeLaunchCallback?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    BonsaiNativeAppDelegate.launchCallback?(
      Unmanaged.passUnretained(self).toOpaque(),
      Unmanaged.passUnretained(application).toOpaque(),
      nil
    ) ?? true
  }
}

private enum NodeKind: Int32 {
  case label = 0
  case button = 1
  case textField = 2
  case verticalStack = 3
  case horizontalStack = 4
  case scrollView = 5
  case list = 6
  case navigationStack = 7
  case tabView = 8
  case image = 9
  case listRow = 10
  case customView = 11
}

private struct BonsaiNativeRowAction: Identifiable {
  let id = UUID()
  let title: String
  let systemImage: String?
  let style: Int32
  let eventId: Int32?
}

private struct BonsaiNativeTab: Identifiable {
  let id: String
  let title: String
  let systemImage: String?
  let role: Int32
}

private final class BonsaiNativeNode: ObservableObject, Identifiable {
  let id = UUID()
  let kind: NodeKind

  @Published var text = ""
  @Published var textStyle: Int32 = 5
  @Published var textWeight: Int32 = 0
  @Published var textColor: Int32 = 0
  @Published var placeholder: String?
  @Published var spacing: CGFloat?
  @Published var children: [BonsaiNativeNode] = []
  @Published var clickEventId: Int32?
  @Published var changeEventId: Int32?
  @Published var isSearchable = false
  @Published var searchText = ""
  @Published var searchEventId: Int32?
  @Published var sheetContent: BonsaiNativeNode?
  @Published var isSheetPresented = false
  @Published var dismissEventId: Int32?
  @Published var padding: EdgeInsets?
  @Published var frameWidth: CGFloat?
  @Published var frameHeight: CGFloat?
  @Published var tabs: [BonsaiNativeTab] = []
  @Published var selectedTabId = ""
  @Published var tabSelectEventId: Int32?
  @Published var rowSubtitle = ""
  @Published var rowTrailingText = ""
  @Published var rowTitleStrikethrough = false
  @Published var rowLeadingSystemImage: String?
  @Published var rowLeadingSelectedSystemImage: String?
  @Published var rowLeadingSelected = false
  @Published var rowLeadingAccessibilityLabel = ""
  @Published var rowLeadingEventId: Int32?
  @Published var rowActions: [BonsaiNativeRowAction] = []

  init(kind: NodeKind) {
    self.kind = kind
  }
}

private final class BonsaiNativeHostModel: ObservableObject {
  @Published var root: BonsaiNativeNode
  let callback: BonsaiNativeEventCallback?

  init(root: BonsaiNativeNode, callback: BonsaiNativeEventCallback?) {
    self.root = root
    self.callback = callback
  }

  func sendClick(_ eventId: Int32?) {
    guard let eventId else { return }
    DispatchQueue.main.async { [callback] in
      callback?(eventId, nil)
    }
  }

  func sendChange(_ eventId: Int32?, text: String) {
    guard let eventId else { return }
    DispatchQueue.main.async { [callback, text] in
      text.withCString { pointer in
        callback?(eventId, pointer)
      }
    }
  }
}

private struct BonsaiNativeRootView: View {
  @ObservedObject var model: BonsaiNativeHostModel

  var body: some View {
    BonsaiNativeNodeView(node: model.root, model: model)
  }
}

private final class BonsaiNativeHostingController: UIHostingController<BonsaiNativeRootView> {
  override var preferredStatusBarStyle: UIStatusBarStyle {
    .darkContent
  }
}

private func makeHostingController(
  root: BonsaiNativeNode,
  callback: BonsaiNativeEventCallback?
) -> UIHostingController<BonsaiNativeRootView> {
  let model = BonsaiNativeHostModel(root: root, callback: callback)
  let controller = BonsaiNativeHostingController(rootView: BonsaiNativeRootView(model: model))
  objc_setAssociatedObject(controller, "BonsaiNativeSwiftUIModel", model, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  return controller
}

private struct BonsaiNativeSearchModifier: ViewModifier {
  @ObservedObject var node: BonsaiNativeNode
  @ObservedObject var model: BonsaiNativeHostModel

  @ViewBuilder
  func body(content: Content) -> some View {
    if node.isSearchable {
      content.searchable(
        text: Binding(
          get: { node.searchText },
          set: { value in
            node.searchText = value
            model.sendChange(node.searchEventId, text: value)
          }
        )
      )
    } else {
      content
    }
  }
}

private struct BonsaiNativeNodeModifiers: ViewModifier {
  @ObservedObject var node: BonsaiNativeNode
  @ObservedObject var model: BonsaiNativeHostModel

  func body(content: Content) -> some View {
    content
      .padding(node.padding ?? EdgeInsets())
      .frame(width: node.frameWidth, height: node.frameHeight)
      .modifier(BonsaiNativeSearchModifier(node: node, model: model))
      .sheet(
        isPresented: Binding(
          get: { node.isSheetPresented },
          set: { presented in
            node.isSheetPresented = presented
            if !presented {
              model.sendClick(node.dismissEventId)
            }
          }
        )
      ) {
        if let sheetContent = node.sheetContent {
          BonsaiNativeNodeView(node: sheetContent, model: model)
        }
      }
  }
}

private struct BonsaiNativeNodeView: View {
  @ObservedObject var node: BonsaiNativeNode
  @ObservedObject var model: BonsaiNativeHostModel

  var body: some View {
    applyModifiers(to: base)
  }

  @ViewBuilder
  private var base: some View {
    switch node.kind {
    case .label:
      Text(node.text)
        .font(textFont(node.textStyle))
        .fontWeight(textWeight(node.textWeight))
        .foregroundStyle(textColor(node.textColor))

    case .button:
      Button(node.text) {
        model.sendClick(node.clickEventId)
      }

    case .textField:
      TextField(
        node.placeholder ?? "",
        text: Binding(
          get: { node.text },
          set: { value in
            node.text = value
            model.sendChange(node.changeEventId, text: value)
          }
        )
      )
      .textFieldStyle(.roundedBorder)

    case .verticalStack:
      VStack(alignment: .leading, spacing: node.spacing) {
        childViews
      }

    case .horizontalStack:
      HStack(spacing: node.spacing) {
        childViews
      }

    case .scrollView:
      ScrollView {
        childViews
      }
      .background(Color(uiColor: .systemGroupedBackground))

    case .list:
      List {
        ForEach(node.children) { child in
          BonsaiNativeNodeView(node: child, model: model)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
      }
      .listStyle(.plain)
      .scrollDisabled(true)
      .scrollContentBackground(.hidden)
      .contentMargins(.horizontal, 0, for: .scrollContent)
      .environment(\.defaultMinListRowHeight, 1)
      .frame(height: max(CGFloat(node.children.count) * 72, 1))
      .background(Color(uiColor: .secondarySystemGroupedBackground))
      .clipShape(.rect(cornerRadius: 24, style: .continuous))

    case .navigationStack:
      NavigationStack {
        childViews
      }

    case .tabView:
      tabView

    case .image:
      Image(systemName: node.text)

    case .listRow:
      listRow

    case .customView:
      Text(node.text)
        .foregroundStyle(.secondary)
    }
  }

  private var childViews: some View {
    ForEach(node.children) { child in
      BonsaiNativeNodeView(node: child, model: model)
    }
  }

  private func textFont(_ style: Int32) -> Font {
    switch style {
    case 0: return .largeTitle
    case 1: return .title
    case 2: return .title2
    case 3: return .title3
    case 4: return .headline
    case 6: return .callout
    case 7: return .subheadline
    case 8: return .footnote
    case 9: return .caption
    case 10: return .caption2
    default: return .body
    }
  }

  private func textWeight(_ weight: Int32) -> Font.Weight {
    switch weight {
    case 1: return .semibold
    case 2: return .bold
    default: return .regular
    }
  }

  private func textColor(_ color: Int32) -> Color {
    switch color {
    case 1: return .secondary
    case 2: return Color.secondary.opacity(0.65)
    default: return .primary
    }
  }

  private var listRow: some View {
    VStack(spacing: 0) {
      HStack(spacing: 14) {
        if let leadingImage = node.rowLeadingSystemImage {
          Button {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
              model.sendClick(node.rowLeadingEventId)
            }
          } label: {
            Image(
              systemName: node.rowLeadingSelected
                ? (node.rowLeadingSelectedSystemImage ?? leadingImage)
                : leadingImage
            )
              .font(.system(size: 25, weight: .regular))
              .symbolRenderingMode(.hierarchical)
              .foregroundStyle(
                node.rowLeadingSelected
                  ? Color.green
                  : Color.secondary.opacity(0.35)
              )
              .frame(width: 32, height: 32)
              .contentShape(.circle)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(node.rowLeadingAccessibilityLabel)
        }

        VStack(alignment: .leading, spacing: 3) {
          Text(node.text)
            .font(.subheadline)
            .foregroundStyle(node.rowTitleStrikethrough ? .secondary : .primary)
            .strikethrough(node.rowTitleStrikethrough, color: .secondary)
            .lineLimit(1)
          if !node.rowSubtitle.isEmpty {
            Text(node.rowSubtitle)
              .font(.subheadline)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        .layoutPriority(1)

        Spacer(minLength: 12)

        if !node.rowTrailingText.isEmpty {
          Text(node.rowTrailingText)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(2)
        }
      }
      .frame(minHeight: 71)

      Divider()
        .padding(.leading, node.rowLeadingSystemImage == nil ? 0 : 46)
    }
    .padding(.horizontal, 16)
    .contentShape(.rect)
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      ForEach(node.rowActions) { action in
        Button(role: action.style == 1 ? .destructive : nil) {
          model.sendClick(action.eventId)
        } label: {
          if let systemImage = action.systemImage {
            Label(action.title, systemImage: systemImage)
          } else {
            Text(action.title)
          }
        }
        .tint(action.style == 1 ? .red : .blue)
      }
    }
  }

  private var tabSelection: Binding<String> {
    Binding(
      get: { node.selectedTabId },
      set: { value in
        node.selectedTabId = value
        model.sendChange(node.tabSelectEventId, text: value)
      }
    )
  }

  @ViewBuilder
  private var tabView: some View {
    if #available(iOS 18.0, *) {
      modernTabView
    } else {
      legacyTabView
    }
  }

  @ViewBuilder
  @available(iOS 18.0, *)
  private var modernTabView: some View {
    let content = TabView(selection: tabSelection) {
      ForEach(Array(node.tabs.enumerated()), id: \.element.id) { index, tab in
        if index < node.children.count {
          let systemImage = tab.systemImage ?? "circle"
          if tab.role == 1 {
            Tab(value: tab.id, role: .search) {
              NavigationStack {
                BonsaiNativeNodeView(node: node.children[index], model: model)
              }
            } label: {
              Label(tab.title, systemImage: systemImage)
            }
          } else {
            Tab(
              tab.title,
              systemImage: systemImage,
              value: tab.id,
              role: nil
            ) {
              NavigationStack {
                BonsaiNativeNodeView(node: node.children[index], model: model)
              }
            }
          }
        }
      }
    }

    if #available(iOS 26.0, *), node.tabs.contains(where: { $0.role == 1 }) {
      content.tabViewSearchActivation(.searchTabSelection)
    } else {
      content
    }
  }

  private var legacyTabView: some View {
    TabView(selection: tabSelection) {
      ForEach(Array(node.tabs.enumerated()), id: \.element.id) { index, tab in
        if index < node.children.count {
          BonsaiNativeNodeView(node: node.children[index], model: model)
            .tabItem {
              if let systemImage = tab.systemImage {
                Image(systemName: systemImage)
              }
              Text(tab.title)
            }
            .tag(tab.id)
        }
      }
    }
  }

  private func applyModifiers<Content: View>(to content: Content) -> some View {
    content.modifier(BonsaiNativeNodeModifiers(node: node, model: model))
  }
}

private func nativeNode(from pointer: UnsafeMutableRawPointer?) -> BonsaiNativeNode? {
  guard let pointer else { return nil }
  return Unmanaged<BonsaiNativeNode>.fromOpaque(pointer).takeUnretainedValue()
}

@_cdecl("bonsai_native_swiftui_run_application")
public func bonsai_native_swiftui_run_application(_ callback: BonsaiNativeLaunchCallback?) {
  BonsaiNativeAppDelegate.launchCallback = callback
  UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(BonsaiNativeAppDelegate.self)
  )
}

@_cdecl("bonsai_native_swiftui_set_padding")
public func bonsai_native_swiftui_set_padding(
  _ pointer: UnsafeMutableRawPointer?,
  _ top: Double,
  _ leading: Double,
  _ bottom: Double,
  _ trailing: Double
) {
  guard let node = nativeNode(from: pointer) else { return }
  if top < 0 || leading < 0 || bottom < 0 || trailing < 0 {
    node.padding = nil
  } else {
    node.padding = EdgeInsets(
      top: CGFloat(top),
      leading: CGFloat(leading),
      bottom: CGFloat(bottom),
      trailing: CGFloat(trailing)
    )
  }
}

@_cdecl("bonsai_native_swiftui_set_frame")
public func bonsai_native_swiftui_set_frame(
  _ pointer: UnsafeMutableRawPointer?,
  _ width: Double,
  _ height: Double
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.frameWidth = width < 0 ? nil : CGFloat(width)
  node.frameHeight = height < 0 ? nil : CGFloat(height)
}

@_cdecl("bonsai_native_swiftui_create_node")
public func bonsai_native_swiftui_create_node(_ rawKind: Int32) -> UnsafeMutableRawPointer? {
  guard let kind = NodeKind(rawValue: rawKind) else { return nil }
  return Unmanaged.passRetained(BonsaiNativeNode(kind: kind)).toOpaque()
}

@_cdecl("bonsai_native_swiftui_release_node")
public func bonsai_native_swiftui_release_node(_ pointer: UnsafeMutableRawPointer?) {
  guard let pointer else { return }
  Unmanaged<BonsaiNativeNode>.fromOpaque(pointer).release()
}

@_cdecl("bonsai_native_swiftui_set_text")
public func bonsai_native_swiftui_set_text(
  _ pointer: UnsafeMutableRawPointer?,
  _ textPointer: UnsafePointer<CChar>?
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.text = textPointer.map(String.init(cString:)) ?? ""
}

@_cdecl("bonsai_native_swiftui_set_text_attributes")
public func bonsai_native_swiftui_set_text_attributes(
  _ pointer: UnsafeMutableRawPointer?,
  _ style: Int32,
  _ weight: Int32,
  _ color: Int32
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.textStyle = style
  node.textWeight = weight
  node.textColor = color
}

@_cdecl("bonsai_native_swiftui_set_placeholder")
public func bonsai_native_swiftui_set_placeholder(
  _ pointer: UnsafeMutableRawPointer?,
  _ textPointer: UnsafePointer<CChar>?
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.placeholder = textPointer.map(String.init(cString:))
}

@_cdecl("bonsai_native_swiftui_set_spacing")
public func bonsai_native_swiftui_set_spacing(
  _ pointer: UnsafeMutableRawPointer?,
  _ spacing: Double
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.spacing = spacing < 0 ? nil : CGFloat(spacing)
}

@_cdecl("bonsai_native_swiftui_set_children")
public func bonsai_native_swiftui_set_children(
  _ pointer: UnsafeMutableRawPointer?,
  _ childPointers: UnsafePointer<UnsafeMutableRawPointer?>?,
  _ count: Int32
) {
  guard let node = nativeNode(from: pointer), let childPointers else { return }
  node.children = (0..<Int(count)).compactMap { index in
    nativeNode(from: childPointers[index])
  }
}

@_cdecl("bonsai_native_swiftui_set_on_click")
public func bonsai_native_swiftui_set_on_click(
  _ pointer: UnsafeMutableRawPointer?,
  _ eventId: Int32
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.clickEventId = eventId < 0 ? nil : eventId
}

@_cdecl("bonsai_native_swiftui_set_on_change")
public func bonsai_native_swiftui_set_on_change(
  _ pointer: UnsafeMutableRawPointer?,
  _ eventId: Int32
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.changeEventId = eventId < 0 ? nil : eventId
}

@_cdecl("bonsai_native_swiftui_set_list_row_subtitle")
public func bonsai_native_swiftui_set_list_row_subtitle(
  _ pointer: UnsafeMutableRawPointer?,
  _ subtitlePointer: UnsafePointer<CChar>?
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.rowSubtitle = subtitlePointer.map(String.init(cString:)) ?? ""
}

@_cdecl("bonsai_native_swiftui_set_list_row_trailing_text")
public func bonsai_native_swiftui_set_list_row_trailing_text(
  _ pointer: UnsafeMutableRawPointer?,
  _ trailingTextPointer: UnsafePointer<CChar>?
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.rowTrailingText = trailingTextPointer.map(String.init(cString:)) ?? ""
}

@_cdecl("bonsai_native_swiftui_set_list_row_title_strikethrough")
public func bonsai_native_swiftui_set_list_row_title_strikethrough(
  _ pointer: UnsafeMutableRawPointer?,
  _ titleStrikethrough: Bool
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.rowTitleStrikethrough = titleStrikethrough
}

@_cdecl("bonsai_native_swiftui_set_list_row_leading")
public func bonsai_native_swiftui_set_list_row_leading(
  _ pointer: UnsafeMutableRawPointer?,
  _ systemImagePointer: UnsafePointer<CChar>?,
  _ selectedSystemImagePointer: UnsafePointer<CChar>?,
  _ selected: Bool
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.rowLeadingSystemImage = systemImagePointer.map(String.init(cString:))
  node.rowLeadingSelectedSystemImage = selectedSystemImagePointer.map(String.init(cString:))
  node.rowLeadingSelected = selected
}

@_cdecl("bonsai_native_swiftui_set_list_row_leading_accessibility")
public func bonsai_native_swiftui_set_list_row_leading_accessibility(
  _ pointer: UnsafeMutableRawPointer?,
  _ labelPointer: UnsafePointer<CChar>?
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.rowLeadingAccessibilityLabel = labelPointer.map(String.init(cString:)) ?? ""
}

@_cdecl("bonsai_native_swiftui_set_list_row_leading_event")
public func bonsai_native_swiftui_set_list_row_leading_event(
  _ pointer: UnsafeMutableRawPointer?,
  _ eventId: Int32
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.rowLeadingEventId = eventId < 0 ? nil : eventId
}

@_cdecl("bonsai_native_swiftui_clear_list_row_actions")
public func bonsai_native_swiftui_clear_list_row_actions(_ pointer: UnsafeMutableRawPointer?) {
  guard let node = nativeNode(from: pointer) else { return }
  node.rowActions = []
}

@_cdecl("bonsai_native_swiftui_append_list_row_action")
public func bonsai_native_swiftui_append_list_row_action(
  _ pointer: UnsafeMutableRawPointer?,
  _ titlePointer: UnsafePointer<CChar>?,
  _ systemImagePointer: UnsafePointer<CChar>?,
  _ style: Int32,
  _ eventId: Int32
) {
  guard let node = nativeNode(from: pointer), let titlePointer else { return }
  node.rowActions.append(
    BonsaiNativeRowAction(
      title: String(cString: titlePointer),
      systemImage: systemImagePointer.map(String.init(cString:)),
      style: style,
      eventId: eventId < 0 ? nil : eventId
    )
  )
}

@_cdecl("bonsai_native_swiftui_set_searchable")
public func bonsai_native_swiftui_set_searchable(
  _ pointer: UnsafeMutableRawPointer?,
  _ eventId: Int32,
  _ textPointer: UnsafePointer<CChar>?
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.isSearchable = eventId >= 0
  node.searchEventId = eventId < 0 ? nil : eventId
  node.searchText = textPointer.map(String.init(cString:)) ?? ""
}

@_cdecl("bonsai_native_swiftui_set_sheet")
public func bonsai_native_swiftui_set_sheet(
  _ pointer: UnsafeMutableRawPointer?,
  _ contentPointer: UnsafeMutableRawPointer?,
  _ isPresented: Bool,
  _ dismissEventId: Int32
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.sheetContent = nativeNode(from: contentPointer)
  node.isSheetPresented = isPresented
  node.dismissEventId = dismissEventId < 0 ? nil : dismissEventId
}

@_cdecl("bonsai_native_swiftui_clear_tabs")
public func bonsai_native_swiftui_clear_tabs(
  _ pointer: UnsafeMutableRawPointer?,
  _ selectedPointer: UnsafePointer<CChar>?,
  _ eventId: Int32
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.tabs = []
  node.selectedTabId = selectedPointer.map(String.init(cString:)) ?? ""
  node.tabSelectEventId = eventId < 0 ? nil : eventId
}

@_cdecl("bonsai_native_swiftui_append_tab")
public func bonsai_native_swiftui_append_tab(
  _ pointer: UnsafeMutableRawPointer?,
  _ idPointer: UnsafePointer<CChar>?,
  _ titlePointer: UnsafePointer<CChar>?,
  _ systemImagePointer: UnsafePointer<CChar>?,
  _ role: Int32
) {
  guard let node = nativeNode(from: pointer), let idPointer, let titlePointer else { return }
  node.tabs.append(
    BonsaiNativeTab(
      id: String(cString: idPointer),
      title: String(cString: titlePointer),
      systemImage: systemImagePointer.map(String.init(cString:)),
      role: role
    )
  )
}

@_cdecl("bonsai_native_swiftui_make_controller")
public func bonsai_native_swiftui_make_controller(
  _ rootPointer: UnsafeMutableRawPointer?,
  _ callback: BonsaiNativeEventCallback?
) -> UnsafeMutableRawPointer? {
  guard let root = nativeNode(from: rootPointer) else { return nil }
  let controller = makeHostingController(root: root, callback: callback)
  return Unmanaged.passRetained(controller).toOpaque()
}

@_cdecl("bonsai_native_swiftui_update_controller")
public func bonsai_native_swiftui_update_controller(
  _ controllerPointer: UnsafeMutableRawPointer?,
  _ rootPointer: UnsafeMutableRawPointer?
) {
  guard let controllerPointer, let root = nativeNode(from: rootPointer) else { return }
  let controller = Unmanaged<UIViewController>.fromOpaque(controllerPointer).takeUnretainedValue()
  if let model = objc_getAssociatedObject(controller, "BonsaiNativeSwiftUIModel") as? BonsaiNativeHostModel {
    model.root = root
  }
}

@_cdecl("bonsai_native_swiftui_release_controller")
public func bonsai_native_swiftui_release_controller(_ controllerPointer: UnsafeMutableRawPointer?) {
  guard let controllerPointer else { return }
  Unmanaged<UIViewController>.fromOpaque(controllerPointer).release()
}

@_cdecl("bonsai_native_swiftui_make_window")
public func bonsai_native_swiftui_make_window(
  _ rootPointer: UnsafeMutableRawPointer?,
  _ callback: BonsaiNativeEventCallback?
) -> UnsafeMutableRawPointer? {
  guard let root = nativeNode(from: rootPointer) else { return nil }
  let window = UIWindow(frame: UIScreen.main.bounds)
  window.rootViewController = makeHostingController(root: root, callback: callback)
  window.makeKeyAndVisible()
  return Unmanaged.passRetained(window).toOpaque()
}

@_cdecl("bonsai_native_swiftui_release_window")
public func bonsai_native_swiftui_release_window(_ windowPointer: UnsafeMutableRawPointer?) {
  guard let windowPointer else { return }
  Unmanaged<UIWindow>.fromOpaque(windowPointer).release()
}
