# Architecture

`bonsai-native` keeps the Bonsai programming model and swaps only the rendering
backend.

```text
Bonsai
  -> bonsai_native node tree
  -> renderer + event table
  -> platform bridge
  -> UIKit / Jetpack Compose
  -> native Apple / Android UI
```

## Shared Core

`native/` is the platform-neutral layer:

- SwiftUI-like node constructors.
- Modifiers for padding, frame, searchable, toolbar, and sheet.
- A render bridge that produces platform payloads and a per-render event table.
- `Bonsai_driver` integration for state, effects, and incremental recomputing.

Platform packages should depend on this layer instead of duplicating Bonsai
state handling.

## Backend Packages

`bonsai_android` is the Android facade. Kotlin Compose is the renderer, not the
authoring API. The UI tree comes from OCaml.

`bonsai_apple` is the Apple facade. The renderer is backend-agnostic; UIKit and
AppKit backends implement the backend operations with Camlkit objects.

## Event And State Flow

1. Platform code asks OCaml to render.
2. OCaml flushes the Bonsai driver and builds the current node tree.
3. Rendering assigns stable-per-render integer event ids.
4. The native renderer attaches those ids to widget callbacks.
5. Platform code dispatches `click` or `change` events back to OCaml.
6. OCaml looks up the event id, schedules the stored `Bonsai.Effect.t`, and the
   next render observes the updated Bonsai state.

Android calls:

- `renderNative(demoId: String) : String`
- `dispatchClickNative(demoId: String, eventId: Int)`
- `dispatchChangeNative(demoId: String, eventId: Int, text: String)`

The Android demo keeps one Bonsai driver per demo id (`counter`, `todo`,
`search`) so tab-local state and event tables remain isolated while the Kotlin
renderer stays generic.

iOS/AppKit backends should expose the same shape through a retained app driver:
render, dispatch, flush, update native views.

## Native Mapping

Android:

| bonsai_native | Android |
| --- | --- |
| `Text` | Compose `Text` |
| `Button` | Compose `Button` |
| `Text_field` | Material `OutlinedTextField` |
| `VStack` / `HStack` | `Column` / `Row` |
| `Scroll_view` | vertical scroll container |
| `List` | `LazyColumn` |
| `Searchable` | Material text field wrapper |
| `Sheet` | Material modal bottom sheet |

Apple:

| bonsai_apple | UIKit |
| --- | --- |
| `Text` | `UILabel` |
| `Button` | `UIButton` |
| `Text_field` | `UITextField` |
| `VStack` / `HStack` | `UIStackView` |
| `Scroll_view` | `UIScrollView` |
| `List` | `UITableView` |
| `Navigation_stack` | `UINavigationController` |
| `Searchable` | `UISearchController` |

Future core logic such as SQLite-backed Datascript state, sync, and domain
effects should live in shared OCaml packages above `bonsai_native`, then be used
by both platform backends.
