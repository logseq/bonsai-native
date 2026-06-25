import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

public typealias BonsaiNativeEventCallback = @convention(c) (Int32, UnsafePointer<CChar>?) -> Void
public typealias BonsaiNativeHTTPCallback =
  @convention(c) (UnsafeMutableRawPointer?, Bool, UnsafePointer<CChar>?) -> Void
public typealias BonsaiNativeLaunchCallback =
  @convention(c) (UnsafeMutableRawPointer?, UnsafeMutableRawPointer?, UnsafeMutableRawPointer?) -> Bool

private enum NodeKind: Int32 {
  case label = 0
  case button = 1
  case textField = 2
  case textEditor = 3
  case verticalStack = 4
  case horizontalStack = 5
  case scrollView = 6
  case list = 7
  case navigationStack = 8
  case tabView = 9
  case image = 10
  case listRow = 11
  case section = 12
  case picker = 13
  case customView = 14
  case photoPicker = 15
  case sidebarSplit = 16
  case fileExporter = 17
  case fileImporter = 18
  case cameraCapture = 19
  case navigationSplit = 20
  case adaptiveLayout = 21
  case toggle = 22
}

private struct BonsaiNativeRowAction: Identifiable {
  let id = UUID()
  let title: String
  let systemImage: String?
  let style: Int32
  let eventId: Int32?
  let exportFilename: String?
  let exportContentType: String?
  let exportContent: String?
}

private struct BonsaiNativeTab: Identifiable {
  let id: String
  let title: String
  let systemImage: String?
  let role: Int32
}

private struct BonsaiNativeSidebarAction: Identifiable {
  let id: String
  let title: String
  let systemImage: String?
  let eventId: Int32?
}

private struct BonsaiNativePickerOption: Identifiable {
  let id: String
  let title: String
}

private final class BonsaiNativeNode: ObservableObject, Identifiable {
  let id = UUID()
  let kind: NodeKind

  @Published var text = ""
  @Published var textStyle: Int32 = 5
  @Published var textWeight: Int32 = 0
  @Published var textColor: Int32 = 0
  @Published var textFieldStyle: Int32 = 0
  @Published var isTextFieldSecure = false
  @Published var isToggleOn = false
  @Published var isEnabled = true
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
  @Published var navigationTitle: String?
  @Published var padding: EdgeInsets?
  @Published var frameWidth: CGFloat?
  @Published var frameHeight: CGFloat?
  @Published var tabs: [BonsaiNativeTab] = []
  @Published var selectedTabId = ""
  @Published var tabSelectEventId: Int32?
  @Published var sidebarHeaderAction: BonsaiNativeSidebarAction?
  @Published var sidebarActions: [BonsaiNativeSidebarAction] = []
  @Published var sidebarBottomSearchPlaceholder: String?
  @Published var sidebarBottomSearchText = ""
  @Published var sidebarBottomSearchEventId: Int32?
  @Published var sidebarBottomAction: BonsaiNativeSidebarAction?
  @Published var rowSubtitle = ""
  @Published var rowTrailingText = ""
  @Published var rowContentStyle: Int32 = 0
  @Published var rowAccessory: Int32 = 0
  @Published var rowTitleStrikethrough = false
  @Published var rowStaticLeadingSystemImage: String?
  @Published var rowPreviewImagePath: String?
  @Published var rowLeadingSystemImage: String?
  @Published var rowLeadingSelectedSystemImage: String?
  @Published var rowLeadingSelected = false
  @Published var rowLeadingAccessibilityLabel = ""
  @Published var rowLeadingEventId: Int32?
  @Published var rowActions: [BonsaiNativeRowAction] = []
  @Published var rowMenuActions: [BonsaiNativeRowAction] = []
  @Published var sectionTitle = ""
  @Published var pickerSelected = ""
  @Published var pickerEventId: Int32?
  @Published var pickerOptions: [BonsaiNativePickerOption] = []
  @Published var exportFilename = ""
  @Published var exportContentType = ""
  @Published var exportContent = ""
  @Published var allowedContentTypes: [String] = []
  @Published var wantsImagePayload = false

  init(kind: NodeKind) {
    self.kind = kind
  }
}

private func sameNodeSequence(_ lhs: [BonsaiNativeNode], _ rhs: [BonsaiNativeNode]) -> Bool {
  lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { $0 === $1 }
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
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

private final class BonsaiNativeHostingController: NSHostingController<BonsaiNativeRootView> {}

private func makeHostingController(
  root: BonsaiNativeNode,
  callback: BonsaiNativeEventCallback?
) -> BonsaiNativeHostingController {
  let model = BonsaiNativeHostModel(root: root, callback: callback)
  let controller = BonsaiNativeHostingController(rootView: BonsaiNativeRootView(model: model))
  objc_setAssociatedObject(controller, "BonsaiNativeSwiftUIModel", model, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  return controller
}

private func nativeNode(from pointer: UnsafeMutableRawPointer?) -> BonsaiNativeNode? {
  guard let pointer else { return nil }
  return Unmanaged<BonsaiNativeNode>.fromOpaque(pointer).takeUnretainedValue()
}

private struct BonsaiNativeNavigationTitleModifier: ViewModifier {
  @ObservedObject var node: BonsaiNativeNode

  @ViewBuilder
  func body(content: Content) -> some View {
    if let title = node.navigationTitle {
      content.navigationTitle(title)
    } else {
      content
    }
  }
}

private struct BonsaiNativeNodeView: View {
  @ObservedObject var node: BonsaiNativeNode
  @ObservedObject var model: BonsaiNativeHostModel

  var body: some View {
    applyModifiers(to: content)
  }

  @ViewBuilder
  private var content: some View {
    switch node.kind {
    case .label:
      Text(node.text)
        .font(font)
        .fontWeight(weight)
        .foregroundStyle(color)
    case .button:
      Button(node.text) { model.sendClick(node.clickEventId) }
        .disabled(!node.isEnabled)
        .buttonStyle(.bordered)
    case .textField:
      Group {
        if node.isTextFieldSecure {
          SecureField(
            node.placeholder ?? "",
            text: Binding(
              get: { node.text },
              set: { value in
                node.text = value
                model.sendChange(node.changeEventId, text: value)
              }
            )
          )
        } else {
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
        }
      }
      .textFieldStyle(.roundedBorder)
      .onSubmit { model.sendClick(node.clickEventId) }
    case .toggle:
      Toggle(
        node.text,
        isOn: Binding(
          get: { node.isToggleOn },
          set: { value in
            node.isToggleOn = value
            model.sendChange(node.changeEventId, text: value ? "true" : "false")
          }
        )
      )
      .disabled(!node.isEnabled)
    case .textEditor:
      TextEditor(
        text: Binding(
          get: { node.text },
          set: { value in
            node.text = value
            model.sendChange(node.changeEventId, text: value)
          }
        )
      )
    case .verticalStack:
      VStack(alignment: .leading, spacing: node.spacing) { childViews }
    case .horizontalStack:
      HStack(alignment: .center, spacing: node.spacing) { childViews }
    case .scrollView:
      ScrollView { childViews }
    case .list:
      List { childViews }
    case .navigationStack:
      NavigationStack { childViews }
    case .navigationSplit:
      NavigationSplitView {
        child(at: 0)
          .navigationTitle("Todos")
      } content: {
        child(at: 1)
          .navigationTitle("Tasks")
      } detail: {
        child(at: 2)
      }
    case .adaptiveLayout:
      child(at: 1)
    case .tabView:
      TabView(selection: tabSelection) {
        ForEach(Array(node.children.enumerated()), id: \.element.id) { index, child in
          BonsaiNativeNodeView(node: child, model: model)
            .tabItem {
              if index < node.tabs.count, let image = node.tabs[index].systemImage {
                Image(systemName: image)
              }
              Text(index < node.tabs.count ? node.tabs[index].title : "")
            }
            .tag(index < node.tabs.count ? node.tabs[index].id : "")
        }
      }
    case .sidebarSplit:
      NavigationSplitView {
        List(node.tabs) { tab in
          Button {
            node.selectedTabId = tab.id
            model.sendChange(node.tabSelectEventId, text: tab.id)
          } label: {
            Label(tab.title, systemImage: tab.systemImage ?? "circle")
          }
          .buttonStyle(.plain)
        }
        .navigationTitle("Todos")
      } detail: {
        selectedTabDetail
      }
    case .image:
      Image(systemName: node.text)
    case .listRow:
      listRow
    case .section:
      Section(node.sectionTitle) { childViews }
    case .picker:
      Picker(node.text, selection: pickerSelection) {
        ForEach(node.pickerOptions) { option in
          Text(option.title).tag(option.id)
        }
      }
    case .photoPicker:
      Label(node.text, systemImage: "photo")
        .foregroundStyle(.secondary)
    case .fileExporter:
      Label(node.text, systemImage: "square.and.arrow.up")
        .foregroundStyle(.secondary)
    case .fileImporter:
      Label(node.text, systemImage: "square.and.arrow.down")
        .foregroundStyle(.secondary)
    case .cameraCapture:
      Label(node.text, systemImage: "camera")
        .foregroundStyle(.secondary)
    case .customView:
      Text(node.text)
    }
  }

  private var childViews: some View {
    ForEach(node.children) { child in
      BonsaiNativeNodeView(node: child, model: model)
    }
  }

  @ViewBuilder
  private func child(at index: Int) -> some View {
    if node.children.indices.contains(index) {
      BonsaiNativeNodeView(node: node.children[index], model: model)
    } else {
      EmptyView()
    }
  }

  @ViewBuilder
  private var selectedTabDetail: some View {
    if let index = node.tabs.firstIndex(where: { $0.id == node.selectedTabId }),
       node.children.indices.contains(index) {
      BonsaiNativeNodeView(node: node.children[index], model: model)
    } else if let first = node.children.first {
      BonsaiNativeNodeView(node: first, model: model)
    } else {
      EmptyView()
    }
  }

  private var listRow: some View {
    HStack(spacing: 10) {
      if let leading = node.rowLeadingSystemImage {
        Button {
          model.sendClick(node.rowLeadingEventId)
        } label: {
          Image(systemName: node.rowLeadingSelected ? (node.rowLeadingSelectedSystemImage ?? leading) : leading)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(node.rowLeadingAccessibilityLabel)
      } else if let leading = node.rowStaticLeadingSystemImage {
        Image(systemName: leading)
          .frame(width: 24, height: 24)
      }
      listRowMainContent
    }
    .contextMenu {
      ForEach(node.rowActions) { action in
        Button(role: action.style == 1 ? .destructive : nil) {
          model.sendClick(action.eventId)
        } label: {
          if let image = action.systemImage {
            Label(action.title, systemImage: image)
          } else {
            Text(action.title)
          }
        }
      }
      ForEach(node.rowMenuActions) { action in
        Button(role: action.style == 1 ? .destructive : nil) {
          model.sendClick(action.eventId)
        } label: {
          if let image = action.systemImage {
            Label(action.title, systemImage: image)
          } else {
            Text(action.title)
          }
        }
      }
    }
  }

  @ViewBuilder
  private var listRowMainContent: some View {
    let content = Group {
      if node.rowContentStyle == 1 {
        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 4) {
            Text(node.text)
              .font(.headline)
              .strikethrough(node.rowTitleStrikethrough)
            if !node.rowSubtitle.isEmpty {
              Text(node.rowSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          Spacer()
          if node.rowAccessory == 1 {
            Image(systemName: "chevron.right")
              .foregroundStyle(.tertiary)
          }
        }
      } else if node.rowContentStyle == 2 {
        VStack(alignment: .leading, spacing: 6) {
          Text(node.text)
            .font(.headline)
            .strikethrough(node.rowTitleStrikethrough)
          if !node.rowSubtitle.isEmpty {
            Text(node.rowSubtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        HStack(spacing: 10) {
          VStack(alignment: .leading, spacing: 2) {
            Text(node.text)
              .strikethrough(node.rowTitleStrikethrough)
            if !node.rowSubtitle.isEmpty {
              Text(node.rowSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          Spacer()
          if !node.rowTrailingText.isEmpty {
            Text(node.rowTrailingText)
              .foregroundStyle(.secondary)
          }
          if node.rowAccessory == 1 {
            Image(systemName: "chevron.right")
              .foregroundStyle(.tertiary)
          }
        }
      }
    }

    content
      .contentShape(Rectangle())
      .onTapGesture {
        model.sendClick(node.clickEventId)
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

  private var pickerSelection: Binding<String> {
    Binding(
      get: { node.pickerSelected },
      set: { value in
        node.pickerSelected = value
        model.sendChange(node.pickerEventId, text: value)
      }
    )
  }

  private var font: Font {
    switch node.textStyle {
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

  private var weight: Font.Weight {
    switch node.textWeight {
    case 1: return .semibold
    case 2: return .bold
    default: return .regular
    }
  }

  private var color: Color {
    switch node.textColor {
    case 1: return .secondary
    case 2: return .secondary
    default: return .primary
    }
  }

  @ViewBuilder
  private func applyModifiers<Content: View>(to content: Content) -> some View {
    let base = content
      .padding(node.padding ?? EdgeInsets())
      .frame(
        width: node.frameWidth,
        height: node.frameHeight,
        alignment: .topLeading
      )
      .modifier(BonsaiNativeNavigationTitleModifier(node: node))

    if node.isSearchable {
      base
        .searchable(
          text: Binding(
            get: { node.searchText },
            set: { value in
              node.searchText = value
              model.sendChange(node.searchEventId, text: value)
            }
          ),
          placement: .toolbar,
          prompt: "Search tasks"
        )
        .sheet(isPresented: sheetBinding) {
          if let sheetContent = node.sheetContent {
            BonsaiNativeNodeView(node: sheetContent, model: model)
          }
        }
    } else {
      base
        .sheet(isPresented: sheetBinding) {
          if let sheetContent = node.sheetContent {
            BonsaiNativeNodeView(node: sheetContent, model: model)
          }
        }
    }
  }

  private var sheetBinding: Binding<Bool> {
    Binding(
      get: { node.isSheetPresented },
      set: { value in
        node.isSheetPresented = value
        if !value {
          model.sendClick(node.dismissEventId)
        }
      }
    )
  }
}

@_cdecl("bonsai_native_swiftui_run_application")
public func bonsai_native_swiftui_run_application(_ callback: BonsaiNativeLaunchCallback?) {
  let app = NSApplication.shared
  app.setActivationPolicy(.regular)
  _ = callback?(nil, Unmanaged.passUnretained(app).toOpaque(), nil)
  app.activate(ignoringOtherApps: true)
  app.run()
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
public func bonsai_native_swiftui_set_text(_ pointer: UnsafeMutableRawPointer?, _ textPointer: UnsafePointer<CChar>?) {
  nativeNode(from: pointer)?.text = textPointer.map(String.init(cString:)) ?? ""
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

@_cdecl("bonsai_native_swiftui_set_enabled")
public func bonsai_native_swiftui_set_enabled(_ pointer: UnsafeMutableRawPointer?, _ isEnabled: Bool) {
  nativeNode(from: pointer)?.isEnabled = isEnabled
}

@_cdecl("bonsai_native_swiftui_set_placeholder")
public func bonsai_native_swiftui_set_placeholder(_ pointer: UnsafeMutableRawPointer?, _ textPointer: UnsafePointer<CChar>?) {
  nativeNode(from: pointer)?.placeholder = textPointer.map(String.init(cString:))
}

@_cdecl("bonsai_native_swiftui_set_text_field_style")
public func bonsai_native_swiftui_set_text_field_style(_ pointer: UnsafeMutableRawPointer?, _ style: Int32) {
  nativeNode(from: pointer)?.textFieldStyle = style
}

@_cdecl("bonsai_native_swiftui_set_text_field_secure")
public func bonsai_native_swiftui_set_text_field_secure(_ pointer: UnsafeMutableRawPointer?, _ isSecure: Bool) {
  nativeNode(from: pointer)?.isTextFieldSecure = isSecure
}

@_cdecl("bonsai_native_swiftui_set_toggle")
public func bonsai_native_swiftui_set_toggle(_ pointer: UnsafeMutableRawPointer?, _ isOn: Bool, _ eventId: Int32) {
  guard let node = nativeNode(from: pointer) else { return }
  node.isToggleOn = isOn
  node.changeEventId = eventId < 0 ? nil : eventId
}

@_cdecl("bonsai_native_swiftui_set_spacing")
public func bonsai_native_swiftui_set_spacing(_ pointer: UnsafeMutableRawPointer?, _ spacing: Double) {
  nativeNode(from: pointer)?.spacing = spacing < 0 ? nil : CGFloat(spacing)
}

@_cdecl("bonsai_native_swiftui_set_children")
public func bonsai_native_swiftui_set_children(
  _ pointer: UnsafeMutableRawPointer?,
  _ childPointers: UnsafePointer<UnsafeMutableRawPointer?>?,
  _ count: Int32
) {
  guard let node = nativeNode(from: pointer), let childPointers else { return }
  let children = (0..<Int(count)).compactMap { nativeNode(from: childPointers[$0]) }
  if !sameNodeSequence(node.children, children) {
    node.children = children
  }
}

@_cdecl("bonsai_native_swiftui_set_on_click")
public func bonsai_native_swiftui_set_on_click(_ pointer: UnsafeMutableRawPointer?, _ eventId: Int32) {
  nativeNode(from: pointer)?.clickEventId = eventId < 0 ? nil : eventId
}

@_cdecl("bonsai_native_swiftui_set_on_change")
public func bonsai_native_swiftui_set_on_change(_ pointer: UnsafeMutableRawPointer?, _ eventId: Int32) {
  nativeNode(from: pointer)?.changeEventId = eventId < 0 ? nil : eventId
}

@_cdecl("bonsai_native_swiftui_set_list_row_subtitle")
public func bonsai_native_swiftui_set_list_row_subtitle(_ pointer: UnsafeMutableRawPointer?, _ subtitlePointer: UnsafePointer<CChar>?) {
  nativeNode(from: pointer)?.rowSubtitle = subtitlePointer.map(String.init(cString:)) ?? ""
}

@_cdecl("bonsai_native_swiftui_set_list_row_trailing_text")
public func bonsai_native_swiftui_set_list_row_trailing_text(_ pointer: UnsafeMutableRawPointer?, _ trailingTextPointer: UnsafePointer<CChar>?) {
  nativeNode(from: pointer)?.rowTrailingText = trailingTextPointer.map(String.init(cString:)) ?? ""
}

@_cdecl("bonsai_native_swiftui_set_list_row_content_style")
public func bonsai_native_swiftui_set_list_row_content_style(_ pointer: UnsafeMutableRawPointer?, _ contentStyle: Int32) {
  nativeNode(from: pointer)?.rowContentStyle = contentStyle
}

@_cdecl("bonsai_native_swiftui_set_list_row_accessory")
public func bonsai_native_swiftui_set_list_row_accessory(_ pointer: UnsafeMutableRawPointer?, _ accessory: Int32) {
  nativeNode(from: pointer)?.rowAccessory = accessory
}

@_cdecl("bonsai_native_swiftui_set_list_row_title_strikethrough")
public func bonsai_native_swiftui_set_list_row_title_strikethrough(_ pointer: UnsafeMutableRawPointer?, _ value: Bool) {
  nativeNode(from: pointer)?.rowTitleStrikethrough = value
}

@_cdecl("bonsai_native_swiftui_set_list_row_leading_system_image")
public func bonsai_native_swiftui_set_list_row_leading_system_image(_ pointer: UnsafeMutableRawPointer?, _ systemImagePointer: UnsafePointer<CChar>?) {
  nativeNode(from: pointer)?.rowStaticLeadingSystemImage = systemImagePointer.map(String.init(cString:))
}

@_cdecl("bonsai_native_swiftui_set_list_row_preview_image_path")
public func bonsai_native_swiftui_set_list_row_preview_image_path(_ pointer: UnsafeMutableRawPointer?, _ imagePathPointer: UnsafePointer<CChar>?) {
  nativeNode(from: pointer)?.rowPreviewImagePath = imagePathPointer.map(String.init(cString:))
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
public func bonsai_native_swiftui_set_list_row_leading_accessibility(_ pointer: UnsafeMutableRawPointer?, _ labelPointer: UnsafePointer<CChar>?) {
  nativeNode(from: pointer)?.rowLeadingAccessibilityLabel = labelPointer.map(String.init(cString:)) ?? ""
}

@_cdecl("bonsai_native_swiftui_set_list_row_leading_event")
public func bonsai_native_swiftui_set_list_row_leading_event(_ pointer: UnsafeMutableRawPointer?, _ eventId: Int32) {
  nativeNode(from: pointer)?.rowLeadingEventId = eventId < 0 ? nil : eventId
}

@_cdecl("bonsai_native_swiftui_clear_list_row_actions")
public func bonsai_native_swiftui_clear_list_row_actions(_ pointer: UnsafeMutableRawPointer?) {
  nativeNode(from: pointer)?.rowActions = []
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
      eventId: eventId < 0 ? nil : eventId,
      exportFilename: nil,
      exportContentType: nil,
      exportContent: nil
    )
  )
}

@_cdecl("bonsai_native_swiftui_clear_list_row_menu_actions")
public func bonsai_native_swiftui_clear_list_row_menu_actions(_ pointer: UnsafeMutableRawPointer?) {
  nativeNode(from: pointer)?.rowMenuActions = []
}

@_cdecl("bonsai_native_swiftui_append_list_row_menu_action")
public func bonsai_native_swiftui_append_list_row_menu_action(
  _ pointer: UnsafeMutableRawPointer?,
  _ titlePointer: UnsafePointer<CChar>?,
  _ systemImagePointer: UnsafePointer<CChar>?,
  _ style: Int32,
  _ eventId: Int32
) {
  guard let node = nativeNode(from: pointer), let titlePointer else { return }
  node.rowMenuActions.append(
    BonsaiNativeRowAction(
      title: String(cString: titlePointer),
      systemImage: systemImagePointer.map(String.init(cString:)),
      style: style,
      eventId: eventId < 0 ? nil : eventId,
      exportFilename: nil,
      exportContentType: nil,
      exportContent: nil
    )
  )
}

@_cdecl("bonsai_native_swiftui_set_searchable")
public func bonsai_native_swiftui_set_searchable(_ pointer: UnsafeMutableRawPointer?, _ eventId: Int32, _ textPointer: UnsafePointer<CChar>?) {
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

@_cdecl("bonsai_native_swiftui_set_navigation_title")
public func bonsai_native_swiftui_set_navigation_title(
  _ pointer: UnsafeMutableRawPointer?,
  _ titlePointer: UnsafePointer<CChar>?
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.navigationTitle = titlePointer.map(String.init(cString:))
}

@_cdecl("bonsai_native_swiftui_set_padding")
public func bonsai_native_swiftui_set_padding(_ pointer: UnsafeMutableRawPointer?, _ top: Double, _ leading: Double, _ bottom: Double, _ trailing: Double) {
  nativeNode(from: pointer)?.padding =
    top < 0 || leading < 0 || bottom < 0 || trailing < 0
    ? nil
    : EdgeInsets(top: CGFloat(top), leading: CGFloat(leading), bottom: CGFloat(bottom), trailing: CGFloat(trailing))
}

@_cdecl("bonsai_native_swiftui_set_frame")
public func bonsai_native_swiftui_set_frame(_ pointer: UnsafeMutableRawPointer?, _ width: Double, _ height: Double) {
  guard let node = nativeNode(from: pointer) else { return }
  node.frameWidth = width < 0 ? nil : CGFloat(width)
  node.frameHeight = height < 0 ? nil : CGFloat(height)
}

@_cdecl("bonsai_native_swiftui_clear_tabs")
public func bonsai_native_swiftui_clear_tabs(_ pointer: UnsafeMutableRawPointer?, _ selectedPointer: UnsafePointer<CChar>?, _ eventId: Int32) {
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

@_cdecl("bonsai_native_swiftui_clear_sidebar_shell")
public func bonsai_native_swiftui_clear_sidebar_shell(
  _ pointer: UnsafeMutableRawPointer?,
  _ bottomSearchPlaceholderPointer: UnsafePointer<CChar>?,
  _ bottomSearchTextPointer: UnsafePointer<CChar>?,
  _ bottomSearchEventId: Int32
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.sidebarHeaderAction = nil
  node.sidebarActions = []
  node.sidebarBottomSearchPlaceholder = bottomSearchPlaceholderPointer.map(String.init(cString:))
  node.sidebarBottomSearchText = bottomSearchTextPointer.map(String.init(cString:)) ?? ""
  node.sidebarBottomSearchEventId = bottomSearchEventId >= 0 ? bottomSearchEventId : nil
  node.sidebarBottomAction = nil
}

@_cdecl("bonsai_native_swiftui_set_sidebar_header_action")
public func bonsai_native_swiftui_set_sidebar_header_action(
  _ pointer: UnsafeMutableRawPointer?,
  _ headerActionIdPointer: UnsafePointer<CChar>?,
  _ headerActionTitlePointer: UnsafePointer<CChar>?,
  _ headerActionSystemImagePointer: UnsafePointer<CChar>?,
  _ headerActionEventId: Int32
) {
  guard let node = nativeNode(from: pointer) else { return }
  if let headerActionIdPointer, let headerActionTitlePointer {
    node.sidebarHeaderAction = BonsaiNativeSidebarAction(
      id: String(cString: headerActionIdPointer),
      title: String(cString: headerActionTitlePointer),
      systemImage: headerActionSystemImagePointer.map(String.init(cString:)),
      eventId: headerActionEventId < 0 ? nil : headerActionEventId
    )
  } else {
    node.sidebarHeaderAction = nil
  }
}

@_cdecl("bonsai_native_swiftui_append_sidebar_action")
public func bonsai_native_swiftui_append_sidebar_action(
  _ pointer: UnsafeMutableRawPointer?,
  _ idPointer: UnsafePointer<CChar>?,
  _ titlePointer: UnsafePointer<CChar>?,
  _ systemImagePointer: UnsafePointer<CChar>?,
  _ eventId: Int32
) {
  guard let node = nativeNode(from: pointer), let idPointer, let titlePointer else { return }
  node.sidebarActions.append(
    BonsaiNativeSidebarAction(
      id: String(cString: idPointer),
      title: String(cString: titlePointer),
      systemImage: systemImagePointer.map(String.init(cString:)),
      eventId: eventId < 0 ? nil : eventId
    )
  )
}

@_cdecl("bonsai_native_swiftui_set_sidebar_bottom_action")
public func bonsai_native_swiftui_set_sidebar_bottom_action(
  _ pointer: UnsafeMutableRawPointer?,
  _ idPointer: UnsafePointer<CChar>?,
  _ titlePointer: UnsafePointer<CChar>?,
  _ systemImagePointer: UnsafePointer<CChar>?,
  _ eventId: Int32
) {
  guard let node = nativeNode(from: pointer) else { return }
  guard let idPointer, let titlePointer else {
    node.sidebarBottomAction = nil
    return
  }
  node.sidebarBottomAction = BonsaiNativeSidebarAction(
    id: String(cString: idPointer),
    title: String(cString: titlePointer),
    systemImage: systemImagePointer.map(String.init(cString:)),
    eventId: eventId < 0 ? nil : eventId
  )
}

@_cdecl("bonsai_native_swiftui_set_section")
public func bonsai_native_swiftui_set_section(_ pointer: UnsafeMutableRawPointer?, _ titlePointer: UnsafePointer<CChar>?) {
  nativeNode(from: pointer)?.sectionTitle = titlePointer.map(String.init(cString:)) ?? ""
}

@_cdecl("bonsai_native_swiftui_clear_picker")
public func bonsai_native_swiftui_clear_picker(
  _ pointer: UnsafeMutableRawPointer?,
  _ titlePointer: UnsafePointer<CChar>?,
  _ selectedPointer: UnsafePointer<CChar>?,
  _ eventId: Int32
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.text = titlePointer.map(String.init(cString:)) ?? ""
  node.pickerSelected = selectedPointer.map(String.init(cString:)) ?? ""
  node.pickerEventId = eventId < 0 ? nil : eventId
  node.pickerOptions = []
}

@_cdecl("bonsai_native_swiftui_append_picker_option")
public func bonsai_native_swiftui_append_picker_option(_ pointer: UnsafeMutableRawPointer?, _ idPointer: UnsafePointer<CChar>?, _ titlePointer: UnsafePointer<CChar>?) {
  guard let node = nativeNode(from: pointer), let idPointer, let titlePointer else { return }
  node.pickerOptions.append(BonsaiNativePickerOption(id: String(cString: idPointer), title: String(cString: titlePointer)))
}

@_cdecl("bonsai_native_swiftui_set_file_exporter")
public func bonsai_native_swiftui_set_file_exporter(_ pointer: UnsafeMutableRawPointer?, _ filenamePointer: UnsafePointer<CChar>?, _ contentTypePointer: UnsafePointer<CChar>?, _ contentPointer: UnsafePointer<CChar>?) {
  guard let node = nativeNode(from: pointer) else { return }
  node.exportFilename = filenamePointer.map(String.init(cString:)) ?? ""
  node.exportContentType = contentTypePointer.map(String.init(cString:)) ?? ""
  node.exportContent = contentPointer.map(String.init(cString:)) ?? ""
}

@_cdecl("bonsai_native_swiftui_set_file_importer")
public func bonsai_native_swiftui_set_file_importer(_ pointer: UnsafeMutableRawPointer?, _ allowedTypesPointer: UnsafeMutablePointer<UnsafePointer<CChar>?>?, _ count: Int32, _ eventId: Int32) {
  guard let node = nativeNode(from: pointer) else { return }
  node.allowedContentTypes = (0..<Int(count)).compactMap { index in
    guard let typePointer = allowedTypesPointer?[index] else { return nil }
    return String(cString: typePointer)
  }
  node.changeEventId = eventId < 0 ? nil : eventId
}

@_cdecl("bonsai_native_swiftui_set_image_payload_mode")
public func bonsai_native_swiftui_set_image_payload_mode(_ pointer: UnsafeMutableRawPointer?, _ wantsPayload: Bool) {
  nativeNode(from: pointer)?.wantsImagePayload = wantsPayload
}

@_cdecl("bonsai_native_swiftui_make_controller")
public func bonsai_native_swiftui_make_controller(_ rootPointer: UnsafeMutableRawPointer?, _ callback: BonsaiNativeEventCallback?) -> UnsafeMutableRawPointer? {
  guard let root = nativeNode(from: rootPointer) else { return nil }
  return Unmanaged.passRetained(makeHostingController(root: root, callback: callback)).toOpaque()
}

@_cdecl("bonsai_native_swiftui_update_controller")
public func bonsai_native_swiftui_update_controller(_ controllerPointer: UnsafeMutableRawPointer?, _ rootPointer: UnsafeMutableRawPointer?) {
  guard let controllerPointer, let root = nativeNode(from: rootPointer) else { return }
  let controller = Unmanaged<NSViewController>.fromOpaque(controllerPointer).takeUnretainedValue()
  if let model = objc_getAssociatedObject(controller, "BonsaiNativeSwiftUIModel") as? BonsaiNativeHostModel {
    model.root = root
  }
}

@_cdecl("bonsai_native_swiftui_release_controller")
public func bonsai_native_swiftui_release_controller(_ controllerPointer: UnsafeMutableRawPointer?) {
  guard let controllerPointer else { return }
  Unmanaged<NSViewController>.fromOpaque(controllerPointer).release()
}

@_cdecl("bonsai_native_swiftui_make_window")
public func bonsai_native_swiftui_make_window(_ rootPointer: UnsafeMutableRawPointer?, _ callback: BonsaiNativeEventCallback?) -> UnsafeMutableRawPointer? {
  guard let root = nativeNode(from: rootPointer) else { return nil }
  let defaultSize = NSSize(width: 1280, height: 820)
  let window = NSWindow(
    contentRect: NSRect(origin: .zero, size: defaultSize),
    styleMask: [.titled, .closable, .miniaturizable, .resizable],
    backing: .buffered,
    defer: false
  )
  window.title = "Bonsai Native Todos"
  window.minSize = NSSize(width: 960, height: 640)
  window.setContentSize(defaultSize)
  window.contentViewController = makeHostingController(root: root, callback: callback)
  window.center()
  window.makeKeyAndOrderFront(nil)
  return Unmanaged.passRetained(window).toOpaque()
}

@_cdecl("bonsai_native_swiftui_release_window")
public func bonsai_native_swiftui_release_window(_ windowPointer: UnsafeMutableRawPointer?) {
  guard let windowPointer else { return }
  Unmanaged<NSWindow>.fromOpaque(windowPointer).release()
}

@_cdecl("bonsai_native_swiftui_http_send_json")
public func bonsai_native_swiftui_http_send_json(
  _ methodPointer: UnsafePointer<CChar>?,
  _ urlPointer: UnsafePointer<CChar>?,
  _ authorizationPointer: UnsafePointer<CChar>?,
  _ bodyPointer: UnsafePointer<CChar>?,
  _ timeoutSeconds: Double,
  _ context: UnsafeMutableRawPointer?,
  _ callback: BonsaiNativeHTTPCallback?
) {
  let message = "HTTP is not implemented in the macOS SwiftUI host"
  message.withCString { pointer in
    callback?(context, false, pointer)
  }
}
