# Apple Native Build

The Apple package lives under `apple/` and exposes `bonsai_apple`.

It targets the Jane Street preview package set
`v0.18~preview.130.100+614`, matching Bonsai and `ppxlib_jane` from the same
preview train. Use OCaml 5.2.x for now.

## Host Dependencies

```sh
cd ~/Codes/projects/bonsai-native
opam switch create . 5.2.1
eval "$(opam env)"
opam repo add janestreet-bleeding https://github.com/janestreet/opam-repository.git --this-switch
opam repo add janestreet-bleeding-external \
  https://github.com/janestreet/opam-repository.git#external-packages \
  --this-switch
DUNE_WORKSPACE=$PWD/dune-workspace.basement-flags \
  opam install . --deps-only --with-test
```

## iOS Cross Switch

Use the iOS fork with OCaml 5.2.1 support:

```sh
git clone https://github.com/tiensonqin/opam-cross-ios.git \
  ~/Codes/projects/opam-cross-ios
cd ~/Codes/projects/opam-cross-ios
git checkout logseq/ocaml-ios-5.2.1
```

Create a simulator switch:

```sh
opam switch create simulator 5.2.1
opam repo add ios-local file://$HOME/Codes/projects/opam-cross-ios --this-switch
opam repo add janestreet-bleeding https://github.com/janestreet/opam-repository.git --this-switch
opam repo add janestreet-bleeding-external \
  https://github.com/janestreet/opam-repository.git#external-packages \
  --this-switch
opam install conf-simulator-ios
ARCH=arm64 SUBARCH=arm64 PLATFORM=iPhoneSimulator \
  SDK=$(xcrun --sdk iphonesimulator --show-sdk-version) VER=17.0 \
  opam install conf-ios
opam install ocaml-ios camlkit-ios camlkit-gui-ios
```

Then build Jane runtime packages into the iOS target sysroot:

```sh
cd ~/Codes/projects/bonsai-native
scripts/bootstrap-ios-jane.sh --switch simulator --clean
```

## Build The Demo App

```sh
IOS_TARGET=arm64-apple-ios17.0-simulator \
IOS_ARCH=arm64 \
IOS_SDKROOT=$(xcrun --sdk iphonesimulator --show-sdk-path) \
opam exec -- dune build apple/examples/BonsaiNativeDemos.app \
  --workspace dune-workspace.simulator
```

For a physical device, create a `device` switch with `PLATFORM=iPhoneOS`, run
`scripts/bootstrap-ios-jane.sh --switch device --clean`, and build with
`--workspace dune-workspace.device`.

The UIKit backend is in `apple/uikit`. It should stay gated behind iOS Dune
contexts because it depends on Camlkit UIKit packages and Apple frameworks.
