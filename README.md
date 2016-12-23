# elm-electron

Elm-electron is a (work in progress) integration of electron for Elm.

At the moment, it exposes a limited subset of the electron api. But it should be enough to get you started!

## How to

**Nota** You can find an example of a project integrating `elm-electron` [there](https://github.com/oleiade/patron)

elm-electron is mostly written using the Native elm api. Therefore it is not compatible with the `elm-package` command. As a result you will have to integrate the code by hand into your projects.

To do so, you will need to integrate the `elm-electron` sources into your project, in this example we will assume you maintain your elm sources files in an `src/` folder.

The folder hierarchy would probably look like:

```bash
├── Electron
│   └── IpcRenderer.elm
│   └── Screen.elm
│   └── Shell.elm
├── Native
│   └── IpcRenderer.js
│   └── Screen.js
│   └── Shell.js
├── MyFile.elm
├── MyOtherFile.elm
└── MyOtherOtherFile.elm
```

And you should make sure your `elm-package.json` file:
*   adds the `elm-electron` sources to *source-directories
*   exposes the `Electron` modules you intend to use
*   activates the usage of `native-modules`

```json
"source-directories": [
    ".",
    "./src"
],
"exposed-modules": [
    "Electron.IpcRenderer"
],
"native-modules": true,
"elm-version": "0.18.0 <= v < 0.19.0"
```

You should be done and ready to rock. For more informations on how to actually use the library, please refer to the `examples/`
