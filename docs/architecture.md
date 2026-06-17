# Architecture

`bonsai-android` follows the same split as `bonsai-apple`, with a shared
OCaml-native layer factored as `bonsai_native`:

```text
Bonsai
  -> bonsai_native node tree
  -> renderer + event table
  -> platform bridge
  -> Android JNI / iOS Camlkit
  -> Kotlin Compose backend / UIKit backend
  -> Android native UI
```

Compose is not the authoring API. It is the Android renderer for OCaml-authored
nodes.

## Shared code

The reusable code is:

- `native/`: platform-neutral node DSL, JSON renderer, event table, and
  `Bonsai_driver` integration.
- `src/`: Android package facade that currently re-exports `bonsai_native`.
- `examples/`: OCaml-authored Bonsai components that can be rendered by Android
  now and iOS later.

Future Datascript/SQLite/sync code should live beside `bonsai_native` or in a
separate OCaml package that both `bonsai_android` and `bonsai_apple` depend on.

## OCaml surface

The public OCaml API starts with:

- `text`
- `button`
- `text_field`
- `vstack`
- `hstack`
- `scroll_view`
- `list`
- `navigation_stack`
- `image`
- `custom_view`
- `padding`
- `frame`
- `searchable`
- `toolbar`
- `sheet`

The API uses `Bonsai.Effect.t` for events, so state, effects, composition, and
incremental recomputation still belong to Bonsai.

Android consumes this shared surface through JSON. The Compose backend maps:

- `searchable` to a native `OutlinedTextField` search control.
- `toolbar` to native Material3 text buttons.
- `sheet` to a native Material3 modal bottom sheet.
- `list` to `LazyColumn` so large keyed lists are not eagerly materialized by
  Compose.

## Event and state flow

`Bonsai_native.App` owns a `Bonsai_driver.t`.

1. Android asks OCaml to render.
2. OCaml flushes the Bonsai driver and returns JSON for the current node tree.
3. During rendering, OCaml assigns stable-per-render integer event ids.
4. Compose renders native widgets and keeps those ids on event callbacks.
5. Android sends `click` or `change` events back to OCaml through JNI.
6. OCaml looks up the id, schedules the stored `Bonsai.Effect.t`, and the next
   render observes the updated Bonsai state.

`Bonsai_native.Bridge.render` produces:

- a JSON node tree for Compose
- a per-render event table mapping integer ids to Bonsai effects

Kotlin calls:

- `renderNative() : String`
- `dispatchClickNative(eventId: Int)`
- `dispatchChangeNative(eventId: Int, text: String)`

The JNI C shim maps those calls to OCaml callbacks registered by the Android
entrypoint.

## Current Android demo

The debug app can run before the Android OCaml `.so` exists. In that mode Gradle
packages `android/app/src/main/assets/bonsai_counter.json`, which is generated
from the OCaml counter component by `scripts/generate-android-assets.sh`.

This proves the OCaml-authored node tree and Compose renderer contract in the
Android emulator. Interactive Bonsai state updates require the native `.so`
path below.

## Native Android `.so` step

Create an Android OCaml cross switch and build a shared library that links:

- OCaml runtime
- `bonsai_android`
- app component
- `jni/bonsai_android_jni.c`

Then copy the resulting `.so` into Gradle's `jniLibs` directory.
