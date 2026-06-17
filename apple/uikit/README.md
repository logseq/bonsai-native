# UIKit Backend

`bonsai_apple_uikit.ml` is the Camlkit/UIKit backend module.  Keep it outside
the default Bonsai build unless the active switch has Camlkit and an iOS SDK
context.

In a Camlkit iOS app, add a Dune stanza like:

```lisp
(library
 (name bonsai_apple_uikit)
 (enabled_if
  (or
   (= %{context_name} device.ios)
   (= %{context_name} simulator.ios)
   (= %{context_name} simulator-arm.ios)
   (= %{context_name} catalyst.ios)))
 (flags :standard -ccopt "-framework UIKit")
 (libraries
  bonsai_apple
  camlkit-base.Foundation
  camlkit-base.CoreGraphics
  camlkit-gui.UIKit)
 (preprocess
  (pps ppx_jane)))
```

Then instantiate:

```ocaml
module App = Bonsai_apple_uikit.App
```

`Bonsai_apple_uikit.native` exposes the underlying `UIView` for app delegate
installation.

The checked-in `dune-workspace.simulator` expects an opam switch named
`simulator`.  Build the bundled demos app with:

```sh
opam exec -- dune build apple/examples/BonsaiNativeDemos.app \
  --workspace dune-workspace.simulator
```

At the moment, the host switch can parser-check this file, but full typechecking
requires an iOS switch with `camlkit-ios`/`camlkit-gui-ios` installed.
