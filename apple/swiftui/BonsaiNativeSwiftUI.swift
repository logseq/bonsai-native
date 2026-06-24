import CryptoKit
import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import Vision

public typealias BonsaiNativeEventCallback = @convention(c) (Int32, UnsafePointer<CChar>?) -> Void
public typealias BonsaiNativeHTTPCallback =
  @convention(c) (UnsafeMutableRawPointer?, Bool, UnsafePointer<CChar>?) -> Void
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
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

private struct BonsaiNativeImagePayload {
  let id: String
  let localPath: String
  let mimeType: String
  let byteSize: Int
  let sha256: String
  let width: Int
  let height: Int
  let recognizedText: String?

  var eventText: String {
    var lines = [
      "bonsai-image-payload",
      "id=\(id)",
      "local_path=\(localPath)",
      "mime_type=\(mimeType)",
      "byte_size=\(byteSize)",
      "sha256=\(sha256)",
      "width=\(width)",
      "height=\(height)"
    ]
    if let recognizedText, !recognizedText.isEmpty {
      lines.append("recognized_text=\(percentEncodePayloadField(recognizedText))")
    }
    return lines.joined(separator: "\n")
  }
}

private func percentEncodePayloadField(_ string: String) -> String {
  string.utf8.map { byte in
    let isDigit = byte >= 48 && byte <= 57
    let isUppercase = byte >= 65 && byte <= 90
    let isLowercase = byte >= 97 && byte <= 122
    if isDigit || isUppercase || isLowercase || byte == 45 || byte == 46 || byte == 95 || byte == 126 {
      return String(UnicodeScalar(byte))
    }
    return String(format: "%%%02X", byte)
  }.joined()
}

private func mimeType(for contentType: UTType?) -> String {
  if contentType?.conforms(to: .png) == true {
    return "image/png"
  }
  if contentType?.conforms(to: .heic) == true {
    return "image/heic"
  }
  return "image/jpeg"
}

private func fileExtension(for mimeType: String) -> String {
  switch mimeType {
  case "image/png":
    return "png"
  case "image/heic":
    return "heic"
  default:
    return "jpg"
  }
}

private func saveImagePayload(
  data: Data,
  mimeType: String,
  idPrefix: String,
  recognizedText: String? = nil
) throws -> BonsaiNativeImagePayload {
  let id = "\(idPrefix)-\(UUID().uuidString)"
  let directory = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask)
    .first?
    .appendingPathComponent("BonsaiNativeImages", isDirectory: true)
    ?? FileManager.default.temporaryDirectory.appendingPathComponent("BonsaiNativeImages", isDirectory: true)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  let url = directory.appendingPathComponent("\(id).\(fileExtension(for: mimeType))")
  try data.write(to: url, options: [.atomic])
  let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  let image = UIImage(data: data)
  let scale = image?.scale ?? 1
  let width = Int(((image?.size.width ?? 0) * scale).rounded())
  let height = Int(((image?.size.height ?? 0) * scale).rounded())
  return BonsaiNativeImagePayload(
    id: id,
    localPath: url.path,
    mimeType: mimeType,
    byteSize: data.count,
    sha256: digest,
    width: width,
    height: height,
    recognizedText: recognizedText
  )
}

private func recognizeText(in data: Data) async -> String? {
  guard let image = UIImage(data: data), let cgImage = image.cgImage else { return nil }
  return await withCheckedContinuation { continuation in
    let request = VNRecognizeTextRequest { request, _ in
      let lines = (request.results as? [VNRecognizedTextObservation] ?? [])
        .compactMap { observation in observation.topCandidates(1).first?.string }
      continuation.resume(returning: lines.isEmpty ? nil : lines.joined(separator: "\n"))
    }
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([request])
    } catch {
      continuation.resume(returning: nil)
    }
  }
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
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
      .disabled(!node.isEnabled)

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

    case .textEditor:
      ZStack(alignment: .topLeading) {
        if node.text.isEmpty, let placeholder = node.placeholder {
          Text(placeholder)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 8)
        }
        TextEditor(
          text: Binding(
            get: { node.text },
            set: { value in
              node.text = value
              model.sendChange(node.changeEventId, text: value)
            }
          )
        )
        .frame(minHeight: 96)
        .scrollContentBackground(.hidden)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 8))

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
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          childViews
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
      }
      .background(Color(uiColor: .systemGroupedBackground))

    case .navigationStack:
      NavigationStack {
        VStack(spacing: 0) {
          childViews
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

    case .navigationSplit:
      navigationSplitView

    case .adaptiveLayout:
      adaptiveLayoutView

    case .tabView:
      tabView

    case .sidebarSplit:
      sidebarSplitView

    case .image:
      Image(systemName: node.text)

    case .listRow:
      listRow

    case .section:
      section

    case .picker:
      picker

    case .photoPicker:
      BonsaiNativePhotoPickerView(node: node, model: model)
        .disabled(!node.isEnabled)

    case .fileExporter:
      BonsaiNativeFileExporterView(node: node)
        .disabled(!node.isEnabled)

    case .fileImporter:
      BonsaiNativeFileImporterView(node: node, model: model)

    case .cameraCapture:
      BonsaiNativeCameraCaptureView(node: node, model: model)

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

  private var section: some View {
    VStack(alignment: .leading, spacing: 0) {
      if !node.sectionTitle.isEmpty {
        Text(node.sectionTitle)
          .font(.headline)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 16)
          .padding(.top, 18)
          .padding(.bottom, 6)
      }
      childViews
    }
    .frame(maxWidth: .infinity, alignment: .leading)
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

  private var picker: some View {
    HStack {
      Text(node.text)
        .foregroundStyle(.primary)
      Spacer(minLength: 12)
      Picker(node.text, selection: pickerSelection) {
        ForEach(node.pickerOptions) { option in
          Text(option.title).tag(option.id)
        }
      }
      .labelsHidden()
      .pickerStyle(.menu)
    }
    .frame(minHeight: 52)
    .padding(.horizontal, 16)
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
              .contentShape(.rect)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(node.rowLeadingAccessibilityLabel)
        }

        listRowMainContent
      }
      .frame(minHeight: 71)

      Divider()
        .padding(.leading, node.rowLeadingSystemImage == nil ? 0 : 46)
    }
    .padding(.horizontal, 16)
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

  @ViewBuilder
  private var listRowMainContent: some View {
    let content = HStack(spacing: 14) {
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

    content
      .contentShape(.rect)
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

  private var selectedRouteIndex: Int? {
    node.tabs.firstIndex { tab in
      tab.id == node.selectedTabId
    }
  }

  @ViewBuilder
  private var selectedRouteDetail: some View {
    if let selectedRouteIndex, selectedRouteIndex < node.children.count {
      BonsaiNativeNodeView(node: node.children[selectedRouteIndex], model: model)
    } else if let firstChild = node.children.first {
      BonsaiNativeNodeView(node: firstChild, model: model)
    } else {
      EmptyView()
    }
  }

  private var sidebarSplitView: some View {
    NavigationSplitView {
      List {
        ForEach(node.tabs) { tab in
          Button {
            node.selectedTabId = tab.id
            model.sendChange(node.tabSelectEventId, text: tab.id)
          } label: {
            Label(tab.title, systemImage: tab.systemImage ?? "circle")
              .fontWeight(tab.id == node.selectedTabId ? .semibold : .regular)
          }
          .buttonStyle(.plain)
        }
      }
      .navigationTitle("Todos")
    } detail: {
      selectedRouteDetail
    }
  }

  @ViewBuilder
  private var navigationSplitView: some View {
    NavigationSplitView {
      if node.children.indices.contains(0) {
        BonsaiNativeNodeView(node: node.children[0], model: model)
      } else {
        EmptyView()
      }
    } content: {
      if node.children.indices.contains(1) {
        BonsaiNativeNodeView(node: node.children[1], model: model)
      } else {
        EmptyView()
      }
    } detail: {
      if node.children.indices.contains(2) {
        BonsaiNativeNodeView(node: node.children[2], model: model)
      } else {
        EmptyView()
      }
    }
  }

  @ViewBuilder
  private var adaptiveLayoutView: some View {
    let index = horizontalSizeClass == .compact ? 0 : 1
    if node.children.indices.contains(index) {
      BonsaiNativeNodeView(node: node.children[index], model: model)
    } else {
      EmptyView()
    }
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
              BonsaiNativeNodeView(node: node.children[index], model: model)
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
              BonsaiNativeNodeView(node: node.children[index], model: model)
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

private struct BonsaiNativePhotoPickerView: View {
  @ObservedObject var node: BonsaiNativeNode
  @ObservedObject var model: BonsaiNativeHostModel
  @State private var selectedItem: PhotosPickerItem?

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      PhotosPicker(selection: $selectedItem, matching: .images) {
        Label(node.text, systemImage: "photo")
      }
      if let selected = node.placeholder, !selected.isEmpty {
        Label("Image attached", systemImage: "checkmark.circle.fill")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .onChange(of: selectedItem) { _, item in
      guard let item else { return }
      if node.wantsImagePayload {
        Task {
          guard let data = try? await item.loadTransferable(type: Data.self) else { return }
          let preferredType = item.supportedContentTypes.first
          let recognizedText = await recognizeText(in: data)
          guard
            let payload = try? saveImagePayload(
              data: data,
              mimeType: mimeType(for: preferredType),
              idPrefix: "image",
              recognizedText: recognizedText
            )
          else { return }
          await MainActor.run {
            node.placeholder = payload.id
            model.sendChange(node.changeEventId, text: payload.eventText)
          }
        }
      } else {
        let imageId = item.itemIdentifier ?? UUID().uuidString
        node.placeholder = imageId
        model.sendChange(node.changeEventId, text: imageId)
      }
    }
  }
}

private struct BonsaiNativeFileExporterView: View {
  @ObservedObject var node: BonsaiNativeNode

  var body: some View {
    if let url = exportURL {
      ShareLink(item: url) {
        Label(node.text, systemImage: "square.and.arrow.up")
      }
    } else {
      Label(node.text, systemImage: "square.and.arrow.up")
        .foregroundStyle(.secondary)
    }
  }

  private var exportURL: URL? {
    guard !node.exportFilename.isEmpty else { return nil }
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("BonsaiNativeExports", isDirectory: true)
    do {
      try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
      )
      let url = directory.appendingPathComponent(node.exportFilename)
      try Data(node.exportContent.utf8).write(to: url, options: [.atomic])
      return url
    } catch {
      return nil
    }
  }
}

private struct BonsaiNativeFileImporterView: View {
  @ObservedObject var node: BonsaiNativeNode
  @ObservedObject var model: BonsaiNativeHostModel
  @State private var isPresented = false

  var body: some View {
    Button {
      isPresented = true
    } label: {
      Label(node.text, systemImage: "square.and.arrow.down")
    }
    .fileImporter(
      isPresented: $isPresented,
      allowedContentTypes: contentTypes,
      allowsMultipleSelection: false
    ) { result in
      guard
        let url = try? result.get().first,
        let content = readText(from: url)
      else { return }
      model.sendChange(node.changeEventId, text: content)
    }
  }

  private var contentTypes: [UTType] {
    let types = node.allowedContentTypes.compactMap { identifier in
      UTType(identifier) ?? UTType(filenameExtension: identifier)
    }
    return types.isEmpty ? [.data] : types
  }

  private func readText(from url: URL) -> String? {
    let shouldStopAccessing = url.startAccessingSecurityScopedResource()
    defer {
      if shouldStopAccessing {
        url.stopAccessingSecurityScopedResource()
      }
    }
    guard let data = try? Data(contentsOf: url) else { return nil }
    return String(data: data, encoding: .utf8) ?? ""
  }
}

private struct BonsaiNativeCameraCaptureView: View {
  @ObservedObject var node: BonsaiNativeNode
  @ObservedObject var model: BonsaiNativeHostModel
  @State private var isPresented = false

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Button {
        isPresented = true
      } label: {
        Label(node.text, systemImage: "camera")
      }
      .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

      if let captured = node.placeholder, !captured.isEmpty {
        Label("Image attached", systemImage: "checkmark.circle.fill")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .sheet(isPresented: $isPresented) {
      BonsaiNativeCameraPicker { image in
        if node.wantsImagePayload, let data = image.jpegData(compressionQuality: 0.92) {
          Task {
            let recognizedText = await recognizeText(in: data)
            if let payload = try? saveImagePayload(
              data: data,
              mimeType: "image/jpeg",
              idPrefix: "image",
              recognizedText: recognizedText
            ) {
              await MainActor.run {
                node.placeholder = payload.id
                model.sendChange(node.changeEventId, text: payload.eventText)
              }
            }
          }
        } else {
          let imageId = "camera://" + UUID().uuidString
          node.placeholder = imageId
          model.sendChange(node.changeEventId, text: imageId)
        }
        isPresented = false
      } onCancel: {
        isPresented = false
      }
    }
  }
}

private struct BonsaiNativeCameraPicker: UIViewControllerRepresentable {
  let onCapture: (UIImage) -> Void
  let onCancel: () -> Void

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let controller = UIImagePickerController()
    controller.sourceType = .camera
    controller.delegate = context.coordinator
    return controller
  }

  func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(onCapture: onCapture, onCancel: onCancel)
  }

  final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    init(onCapture: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
      self.onCapture = onCapture
      self.onCancel = onCancel
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      guard let image = info[.originalImage] as? UIImage else {
        onCancel()
        return
      }
      onCapture(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      onCancel()
    }
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
  let method = methodPointer.map { String(cString: $0) } ?? "GET"
  let urlString = urlPointer.map { String(cString: $0) } ?? ""
  let authorization = authorizationPointer.map { String(cString: $0) }
  let body = bodyPointer.map { String(cString: $0) } ?? ""

  guard let url = URL(string: urlString) else {
    "Invalid URL: \(urlString)".withCString { pointer in
      callback?(context, false, pointer)
    }
    return
  }

  var request = URLRequest(url: url)
  request.httpMethod = method
  request.timeoutInterval = timeoutSeconds > 0 ? timeoutSeconds : 30
  request.setValue("application/json", forHTTPHeaderField: "Accept")
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  if let authorization, !authorization.isEmpty {
    request.setValue(authorization, forHTTPHeaderField: "Authorization")
  }
  if !body.isEmpty {
    request.httpBody = Data(body.utf8)
  }

  URLSession.shared.dataTask(with: request) { data, response, error in
    let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    let result: (Bool, String)
    if let error {
      result = (false, error.localizedDescription)
    } else if let httpResponse = response as? HTTPURLResponse,
              !(200..<300).contains(httpResponse.statusCode) {
      let message = responseBody.isEmpty
        ? "HTTP \(httpResponse.statusCode)"
        : "HTTP \(httpResponse.statusCode): \(responseBody)"
      result = (false, message)
    } else {
      result = (true, responseBody)
    }

    DispatchQueue.main.async {
      result.1.withCString { pointer in
        callback?(context, result.0, pointer)
      }
    }
  }.resume()
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

@_cdecl("bonsai_native_swiftui_set_enabled")
public func bonsai_native_swiftui_set_enabled(
  _ pointer: UnsafeMutableRawPointer?,
  _ isEnabled: Bool
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.isEnabled = isEnabled
}

@_cdecl("bonsai_native_swiftui_set_image_payload_mode")
public func bonsai_native_swiftui_set_image_payload_mode(
  _ pointer: UnsafeMutableRawPointer?,
  _ wantsPayload: Bool
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.wantsImagePayload = wantsPayload
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
  let children = (0..<Int(count)).compactMap { index in
    nativeNode(from: childPointers[index])
  }
  if !sameNodeSequence(node.children, children) {
    node.children = children
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

@_cdecl("bonsai_native_swiftui_set_section")
public func bonsai_native_swiftui_set_section(
  _ pointer: UnsafeMutableRawPointer?,
  _ titlePointer: UnsafePointer<CChar>?
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.sectionTitle = titlePointer.map(String.init(cString:)) ?? ""
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
public func bonsai_native_swiftui_append_picker_option(
  _ pointer: UnsafeMutableRawPointer?,
  _ idPointer: UnsafePointer<CChar>?,
  _ titlePointer: UnsafePointer<CChar>?
) {
  guard let node = nativeNode(from: pointer), let idPointer, let titlePointer else { return }
  node.pickerOptions.append(
    BonsaiNativePickerOption(id: String(cString: idPointer), title: String(cString: titlePointer))
  )
}

@_cdecl("bonsai_native_swiftui_set_file_exporter")
public func bonsai_native_swiftui_set_file_exporter(
  _ pointer: UnsafeMutableRawPointer?,
  _ filenamePointer: UnsafePointer<CChar>?,
  _ contentTypePointer: UnsafePointer<CChar>?,
  _ contentPointer: UnsafePointer<CChar>?
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.exportFilename = filenamePointer.map(String.init(cString:)) ?? ""
  node.exportContentType = contentTypePointer.map(String.init(cString:)) ?? ""
  node.exportContent = contentPointer.map(String.init(cString:)) ?? ""
}

@_cdecl("bonsai_native_swiftui_set_file_importer")
public func bonsai_native_swiftui_set_file_importer(
  _ pointer: UnsafeMutableRawPointer?,
  _ allowedTypesPointer: UnsafeMutablePointer<UnsafePointer<CChar>?>?,
  _ count: Int32,
  _ eventId: Int32
) {
  guard let node = nativeNode(from: pointer) else { return }
  node.allowedContentTypes = (0..<Int(count)).compactMap { index in
    guard let typePointer = allowedTypesPointer?[index] else { return nil }
    return String(cString: typePointer)
  }
  node.changeEventId = eventId < 0 ? nil : eventId
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
