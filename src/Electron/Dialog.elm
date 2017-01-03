effect module Electron.Dialog
    where { command = MyCmd }
    exposing
        ( showItemInFolder
        )


showOpenDialog : Cmd msg
showOpenDialog =
    command <| ShowOpenDialog


nativeShowOpenDialog : String -> Task Never ()
nativeShowOpenDialog fullPath =
    Native.Dialog.showOpenDialog



-- EFFECT MANAGER


type MyCmd msg
    = ShowOpenDialog


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap mapper cmd =
    case cmd of
        ShowOpenDialog ->
            ShowOpenDialog


cmdToTask : MyCmd msg -> Task Never ()
cmdToTask cmd =
    case cmd of
        ShowOpenDialog ->
            nativeShowOpenDialog


init : Task Never ()
init =
    Task.succeed ()


onEffects : Router msg Never -> List (MyCmd msg) -> () -> Task Never ()
onEffects router cmds seed =
    case cmds of
        [] ->
            Task.succeed ()

        _ ->
            cmds
                |> List.map cmdToTask
                |> Task.sequence
                |> Task.map (\_ -> ())


onSelfMsg : Platform.Router msg Never -> Never -> () -> Task Never ()
onSelfMsg _ _ _ =
    Task.succeed ()
