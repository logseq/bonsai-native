(lang dune 3.17)

(name bonsai_native)

(package
 (name bonsai_native)
 (synopsis "Shared native UI core for Bonsai")
 (description
  "Platform-independent OCaml node tree, event bridge, and Bonsai app driver for native backends.")
 (depends
  (ocaml (>= 5.1.0))
  dune
  (bonsai (= v0.18~preview.130.100+614))
  (core (= v0.18~preview.130.100+614))
  (ppx_jane (= v0.18~preview.130.100+614))))

(package
 (name bonsai_android)
 (synopsis "Native Android UI backend for Bonsai")
 (description
  "A Jetpack Compose backed native Android UI framework for OCaml built on Bonsai.")
 (depends
  (ocaml (>= 5.1.0))
  dune
  (bonsai (= v0.18~preview.130.100+614))
  bonsai_native
  (core (= v0.18~preview.130.100+614))
  (ppx_jane (= v0.18~preview.130.100+614))))

(package
 (name bonsai_apple)
 (synopsis "Native Apple UI backend for Bonsai")
 (description
  "A SwiftUI-like declarative native Apple UI framework for OCaml built on Bonsai and Camlkit.")
 (depends
  (ocaml (and (>= 5.1.0) (< 5.3.0)))
  dune
  (bonsai (= v0.18~preview.130.100+614))
  (core (= v0.18~preview.130.100+614))
  (ppx_jane (= v0.18~preview.130.100+614))))
