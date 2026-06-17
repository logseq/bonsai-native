# bonsai-native Apple examples

These files are component examples.  They intentionally define Bonsai components
that return `Bonsai_apple.node`; the Camlkit app delegate is responsible for
instantiating a UIKit or AppKit backend and mounting the component with
`Bonsai_apple.App.Make`.

Examples:

- `counter.ml`
- `todo.ml`
- `searchable_list.ml`
- `navigation.ml`
- `ios_app.ml`
