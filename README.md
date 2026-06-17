# bonsai-native

`bonsai-native` is an OCaml native UI experiment for building iOS and Android
apps with the Bonsai programming model.

The app UI is authored in OCaml. Platform code is only the renderer bridge:

```text
Bonsai component
  -> bonsai_native node tree
  -> platform renderer + event table
  -> Android JNI / iOS Camlkit
  -> Jetpack Compose / UIKit
  -> native app UI
```

This is not a WebView and not a SwiftUI wrapper.

## Packages

- `bonsai_native`: shared OCaml node DSL, JSON/event bridge, and Bonsai driver
  integration.
- `bonsai_android`: Android facade over `bonsai_native`; rendered by Kotlin
  Compose through JNI.
- `bonsai_apple`: iOS/macOS-facing API and renderer abstractions; UIKit backend
  lives under `apple/uikit`.

Backend package names intentionally remain explicit. Existing Android code can
continue to open `Bonsai_android`, and iOS code can continue to open
`Bonsai_apple`.

## OCaml UI Example

```ocaml
let component graph =
  let open Bonsai.Let_syntax in
  let count, set_count = Bonsai.state 0 graph in
  let%arr count and set_count in
  Bonsai_android.vstack
    [ Bonsai_android.text (Int.to_string count)
    ; Bonsai_android.button "Increment" ~on_click:(set_count (count + 1))
    ]
```

On Android, Compose receives a native node tree JSON payload and sends event ids
back to OCaml through JNI. OCaml owns the Bonsai driver and event table, so
state updates are still Bonsai effects.

## Repository Layout

- `native/`: shared `bonsai_native` implementation.
- `src/`: Android OCaml facade.
- `android/`: Gradle/Compose demo app.
- `jni/`: Android JNI bridge into OCaml.
- `apple/`: Apple OCaml package, UIKit backend, and iOS examples.
- `examples/`: Android demo entrypoints and smoke examples.
- `scripts/`: Android and iOS bootstrap/build helpers.
- `docs/`: architecture and platform build notes.

## Android Quick Check

Use a switch with the Android cross compiler and Jane preview packages. The
current working path is documented in
[docs/android-native-build.md](docs/android-native-build.md).

```sh
export BONSAI_NATIVE_OPAM_SWITCH=/path/to/your/ocaml-android-switch

scripts/build-android-native.sh
cd android
rtk proxy ./gradlew :app:assembleDebug
```

The debug APK should contain:

```text
lib/arm64-v8a/libbonsai_android_counter.so
```

Run the emulator smoke test:

```sh
scripts/test-android-emulator.sh
```

It installs the APK, launches the counter, taps `Increment`, and verifies the UI
changes from `0` to `1`. It also switches through the Android `Todo` and
`Search` tabs, which mirror the current iOS demo tabs.

## iOS Quick Check

The iOS package is under `apple/` and builds through Camlkit/opam-cross-ios
contexts. See [docs/apple-native-build.md](docs/apple-native-build.md).

The simulator app target is:

```sh
opam exec -- dune build apple/examples/BonsaiNativeDemos.app \
  --workspace dune-workspace.simulator
```

## Status

Working now:

- Shared OCaml DSL for text, button, text fields, stacks, scroll views, keyed
  lists, navigation stacks, images, custom views, and common modifiers.
- Android JNI native library built with OCaml 5.2.1, Core, Bonsai, and
  `bonsai.ppx_bonsai`.
- Android Compose renderer loads real native OCaml state and dispatches clicks
  back into Bonsai.
- Android and iOS demo apps expose the same `Counter`, `Todo`, and `Search`
  OCaml views.
- Apple source/backend scaffolding is included in the same repo.

Still early:

- Android release-size optimization.
- More complete iOS packaging automation.
- AppKit backend.
- Shared persistence/sync packages above the UI layer.
