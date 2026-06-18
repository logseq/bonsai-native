# Bonsai Native SwiftUI backend

This backend is a SwiftUI implementation target for the OCaml
`Bonsai_apple.Renderer.Backend` shape.

The boundary is intentionally generic:

- OCaml/Bonsai owns the node tree, state, reconciliation, and effects.
- The Apple renderer creates and patches backend view nodes from OCaml.
- SwiftUI observes those backend nodes and maps generic node kinds to native controls.
- SwiftUI sends event ids and optional text values back through a C callback.

UIKit support stays separate in `bonsai_apple.uikit`. This backend is additive and should not replace the UIKit renderer.

The Swift side does not contain app-specific UI. App UX should come from the OCaml node tree and backend styling conventions.

App authors should not edit this backend to build one screen. They should use
`Bonsai_apple` primitives. If a native concept such as bottom tabs, sidebars, or
split navigation is missing, add it once to the shared OCaml API and implement
it in each Apple backend (`bonsai_apple.uikit`, `bonsai_apple.swiftui`) as
needed.

The current Swift runtime exposes C symbols for:

- Creating/releasing generic backend nodes.
- Updating text, placeholder, spacing, children, event ids, searchable state, and sheets.
- Hosting a root node in a `UIHostingController`.

The remaining integration step is an OCaml `bonsai_apple.swiftui` module that
implements `Bonsai_apple.Renderer.Backend` by calling these symbols. The module
is checked in as `bonsai_apple.swiftui`; app targets that instantiate it must
also link the compiled Swift runtime object or archive.
