# Architecture

`bonsai-native` keeps shared OCaml graph state/actions above native platform
renderers.

```text
OCaml graph component
  -> bonsai_native node tree
  -> renderer + event table
  -> platform bridge
  -> SwiftUI / Jetpack Compose
  -> native Apple / Android UI
```

## Shared Runtime

`native/` is the platform-neutral layer:

- SwiftUI-like node constructors.
- Modifiers for padding, frame, searchable, toolbar, and sheet.
- A render bridge that produces platform payloads and a per-render event table.
- A lightweight graph driver for state, effects, and rerender scheduling.

Platform packages should depend on this layer instead of duplicating graph state
handling.

## Backend Packages

`bonsai_android` is the Android facade. Kotlin Compose is the renderer, not the
authoring API. The UI tree comes from OCaml.

`bonsai_apple` is the Apple facade. The renderer is backend-agnostic; SwiftUI is
the maintained Apple backend.

## Event And State Flow

1. Platform code asks OCaml to render.
2. OCaml flushes the graph driver and builds the current node tree.
3. Rendering assigns stable-per-render integer event ids.
4. The native renderer attaches those ids to widget callbacks.
5. Platform code dispatches `click` or `change` events back to OCaml.
6. OCaml looks up the event id, schedules the stored effect, and the next render
   observes the updated graph state.

Android calls:

- `renderNative(demoId: String) : String`
- `dispatchClickNative(demoId: String, eventId: Int)`
- `dispatchChangeNative(demoId: String, eventId: Int, text: String)`

The Android demo keeps one graph driver per demo id (`counter`, `todo`,
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

| bonsai_apple | SwiftUI |
| --- | --- |
| `Text` | `Text` |
| `Button` | `Button` |
| `Text_field` | `TextField` |
| `VStack` / `HStack` | `VStack` / `HStack` |
| `Scroll_view` | `ScrollView` |
| `List` | `List` |
| `Navigation_stack` | `NavigationStack` |
| `Searchable` | `searchable` |

Future shared logic such as SQLite-backed Datascript state, sync, and domain
effects should live in shared OCaml packages above `bonsai_native`, then be used
by both platform backends.
