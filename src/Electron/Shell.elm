effect module Shell where { command = MyCmd } exposing (..)

import Task exposing (Task)
import Platform exposing (Router)
import Native.Shell


-- NATIVE WRAPPERS


nativeShowItemInFolder : String -> Task Never ()
nativeShowItemInFolder fullPath =
    Native.Shell.showItemInFolder fullPath


nativeOpenItem : String -> Task Never ()
nativeOpenItem fullPath =
    Native.Shell.openItem fullPath


nativeOpenExternal : String -> Task Never ()
nativeOpenExternal url =
    Native.Shell.openExternal url


nativeMoveItemToTrash : String -> Task Never ()
nativeMoveItemToTrash fullPath =
    Native.Shell.moveItemToTrash fullPath


nativeBeep : Task Never ()
nativeBeep =
    Native.Shell.beep



-- EFFECT MANAGER


type MyCmd msg
    = ShowItemInFolder String
    | OpenItem String
    | OpenExternal String
    | MoveItemToTrash String
    | Beep


cmdMap : (a -> b) -> MyCmd a -> MyCmd b
cmdMap mapper cmd =
    case cmd of
        ShowItemInFolder fullPath ->
            ShowItemInFolder fullPath

        OpenItem fullPath ->
            OpenItem fullPath

        OpenExternal url ->
            OpenExternal url

        MoveItemToTrash fullPath ->
            MoveItemToTrash fullPath

        Beep ->
            Beep


cmdToTask : MyCmd msg -> Task Never ()
cmdToTask cmd =
    case cmd of
        ShowItemInFolder fullPath ->
            nativeShowItemInFolder fullPath

        OpenItem fullPath ->
            nativeOpenItem fullPath

        OpenExternal url ->
            nativeOpenExternal url

        MoveItemToTrash fullPath ->
            nativeMoveItemToTrash fullPath

        Beep ->
            nativeBeep


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
