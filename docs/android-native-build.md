# Android Native Build

The Android app loads `libbonsai_android_counter.so` when it exists. That
library must contain:

- the OCaml runtime
- the OCaml Bonsai app entrypoint
- the JNI functions in `jni/bonsai_android_jni.c`

The Dune target for that library is:

```sh
dune build -x android_arm64v8a examples/android_counter_entry.so
```

`scripts/build-android-native.sh` copies the resulting file to Gradle's native
library input:

```text
android/_build/android/jniLibs/arm64-v8a/libbonsai_android_counter.so
```

## Current Toolchain Constraint

The maintained Android OCaml cross-compiler route is DkML. Its published quick
start uses Android NDK 27, an `android_arm64v8a` Dune target, and
`ocamlfind -toolchain android_arm64v8a`.

That route is not yet enough to finish this project by itself because this repo
uses Jane Street Bonsai v0.18 preview packages, which require the OCaml 5-era
Jane Street stack. The DkML Android route is compiler-distribution-specific, and
its Android documentation warns that Android cross compilation is not standard
OCaml compiler behavior.

So the native build has two stages:

1. Build the binary shape on the host. This is already wired:

   ```sh
   opam exec --switch=/Users/tiensonqin/Codes/projects/bonsai-apple -- \
     dune build examples/android_counter_entry.so
   ```

   The resulting host shared object exports:

   - `Java_com_logseq_bonsaiandroid_BonsaiAndroidNative_renderNative`
   - `Java_com_logseq_bonsaiandroid_BonsaiAndroidNative_dispatchClickNative`
   - `Java_com_logseq_bonsaiandroid_BonsaiAndroidNative_dispatchChangeNative`

2. Make an Android cross switch that can build the same Dune target with the
   Bonsai v0.18 dependency set.

## DkML Reference Commands

These are the upstream-style commands for the Android arm64-v8a shape. They are
kept here so the project has a concrete target instead of a vague TODO:

```sh
export ANDROID_HOME=${ANDROID_HOME:-$HOME/Library/Android/sdk}
export BONSAI_ANDROID_NDK_VERSION=27.1.12297006

yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
  --install "ndk;$BONSAI_ANDROID_NDK_VERSION"

opam var --global ANDROID_NDK="$ANDROID_HOME/ndk/$BONSAI_ANDROID_NDK_VERSION"
opam var --global ANDROID_PLATFORM=android-34

opam switch create android34-ndk27-arm64-v8a --cli=2.1 \
  --packages dkml-base-compiler,dkml-host-abi-linux_x86_64,dkml-target-abi-android_arm64v8a,ocamlfind,conf-dkml-cross-toolchain \
  --repos default,diskuv-4d79e732=git+https://github.com/diskuv/diskuv-opam-repository.git#4d79e732
```

The published DkML instructions use a Linux Android container for macOS users.
On Apple Silicon, expect to run this in a Linux container unless the DkML host
ABI packages for macOS are confirmed to satisfy this project.
